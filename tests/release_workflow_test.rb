# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"
require "yaml"

# 在隔离目录执行真实发布步骤；假的 gh 只操作夹具，不访问 GitHub。
class ReleaseWorkflowTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  STEP_NAME = "Distribute and verify immutable rule artifacts"
  ARTIFACTS = { "CLAUDE.md" => "claude rules\n", "AGENTS.md" => "agent rules\n" }.freeze
  FAKE_GH = <<~'RUBY'
    require "fileutils"
    require "json"
    state_path = ENV.fetch("FAKE_GH_STATE")
    state = JSON.parse(File.read(state_path))
    command = ARGV.fetch(1)
    state.fetch("calls") << ARGV
    option = ->(name) { index = ARGV.index(name); index && ARGV[index + 1] }
    persist = -> { File.write(state_path, JSON.generate(state)) }
    case command
    when "view"
      persist.call
      exit 1 unless state.fetch("exists")
      case option.call("--json")
      when "isDraft"
        puts state.fetch("draft")
      when "assets"
        artifact = option.call("--jq")[/name == "([^"]+)"/, 1]
        puts state.fetch("assets").key?(artifact)
      end
    when "create"
      abort "release already exists" if state.fetch("exists")
      abort "must create a draft without Latest promotion" unless ARGV.include?("--draft") && ARGV.include?("--latest=false") && ARGV.include?("--verify-tag")
      state["exists"] = true
      state["draft"] = true
      persist.call
      exit 1 if state["create_timeout"]
    when "upload"
      artifact = ARGV.fetch(3)
      abort "cannot replace an artifact" if state.fetch("assets").key?(artifact) || ARGV.include?("--clobber")
      state.fetch("assets")[artifact] = File.read(artifact)
      persist.call
    when "download"
      persist.call
      abort "download unavailable" if state["download_failure"]
      artifact = option.call("--pattern")
      directory = option.call("--dir")
      File.write(File.join(directory, artifact), state.fetch("assets").fetch(artifact))
    when "edit"
      abort "must not promote Latest" unless ARGV.include?("--latest=false")
      state["draft"] = false
      persist.call
    else
      abort "unsupported fake gh command: #{command}"
    end
  RUBY

  def setup
    @directory = Dir.mktmpdir("rule-release-test")
    @state_path = File.join(@directory, "state.json")
    @state = { "exists" => false, "draft" => true, "assets" => {}, "calls" => [] }
    ARTIFACTS.each { |name, content| File.write(File.join(@directory, name), content) }
    fake = File.join(@directory, "gh")
    File.write(fake, "#!#{RbConfig.ruby}\n#{FAKE_GH}")
    File.chmod(0o700, fake)
    workflow = YAML.load_file(File.join(ROOT, ".github", "workflows", "release-claude.yml"))
    @script = workflow.fetch("jobs").fetch("release").fetch("steps").find { |step| step["name"] == STEP_NAME }.fetch("run")
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def execute
    File.write(@state_path, JSON.generate(@state))
    environment = { "PATH" => "#{@directory}:#{ENV.fetch('PATH')}", "FAKE_GH_STATE" => @state_path, "TAG_NAME" => "v1.2.3", "TMPDIR" => @directory }
    stdout, stderr, status = Open3.capture3(environment, "bash", "-euo", "pipefail", "-c", @script, chdir: @directory)
    @state = JSON.parse(File.read(@state_path))
    [status.success?, "#{stdout}\n#{stderr}"]
  end

  def calls(command)
    @state.fetch("calls").select { |arguments| arguments[1] == command }
  end

  def test_new_release_is_published_only_after_both_artifacts_are_verified
    passed, output = execute
    assert passed, output
    assert_equal ARTIFACTS, @state.fetch("assets")
    refute @state.fetch("draft")
    assert_equal 2, calls("download").size
    assert_equal 1, calls("edit").size
  end

  def test_identical_published_release_can_be_retried_without_mutation
    @state.merge!("exists" => true, "draft" => false, "assets" => ARTIFACTS.dup)
    passed, output = execute
    assert passed, output
    assert_empty calls("create")
    assert_empty calls("upload")
    assert_empty calls("edit")
  end

  def test_partial_draft_upload_resumes_without_replacing_existing_asset
    @state.merge!("exists" => true, "assets" => { "CLAUDE.md" => ARTIFACTS.fetch("CLAUDE.md") })
    passed, output = execute
    assert passed, output
    assert_equal ["AGENTS.md"], calls("upload").map { |arguments| arguments[3] }
    assert_equal ARTIFACTS, @state.fetch("assets")
  end

  def test_mismatched_asset_blocks_publication_and_is_not_overwritten
    @state.merge!("exists" => true, "assets" => ARTIFACTS.merge("CLAUDE.md" => "different content"))
    passed, = execute
    refute passed
    assert @state.fetch("draft")
    assert_equal "different content", @state.fetch("assets").fetch("CLAUDE.md")
    assert_empty calls("upload")
    assert_empty calls("edit")
  end

  def test_missing_asset_in_published_release_fails_without_changing_release
    @state.merge!("exists" => true, "draft" => false, "assets" => { "CLAUDE.md" => ARTIFACTS.fetch("CLAUDE.md") })
    passed, output = execute
    refute passed
    assert_includes output, "missing required artifact"
    assert_empty calls("upload")
    assert_empty calls("edit")
  end

  def test_download_failure_cannot_be_reported_as_published
    @state["download_failure"] = true
    passed, = execute
    refute passed
    assert @state.fetch("draft")
    assert_empty calls("edit")
  end

  def test_timeout_after_draft_creation_can_be_recovered_on_retry
    @state["create_timeout"] = true
    passed, = execute
    refute passed
    assert @state.fetch("exists")
    assert @state.fetch("draft")
    @state["create_timeout"] = false
    passed, output = execute
    assert passed, output
    assert_equal 1, calls("create").size
    assert_equal ARTIFACTS, @state.fetch("assets")
    refute @state.fetch("draft")
  end
end
