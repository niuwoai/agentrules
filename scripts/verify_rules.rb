#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "optparse"
require "rbconfig"
require "tmpdir"

# 默认编码随 locale 变化会读不到含中文的规则文本和子进程输出，这里显式固定 UTF-8
Encoding.default_external = Encoding::UTF_8

ROOT = File.expand_path("..", __dir__)
GENERATOR = File.join(ROOT, "scripts", "generate_claude_md.rb")
PROJECT_AGENT_GENERATOR = File.join(ROOT, "scripts", "generate_project_agents.rb")
GENERATED_ARTIFACT = File.join(ROOT, "GENERATED_CLAUDE.md")
GENERATED_INDEX_ARTIFACT = File.join(ROOT, "GENERATED_AGENTS.md")
AUTO_LOAD_DOCS = %w[README.md PRODUCT_OVERVIEW.md ARCHITECTURE.md CHANGELOG.md CLAUDE.md GENERATED_CLAUDE.md GENERATED_AGENTS.md].freeze
AUTO_LOAD_BUDGET_LINES = 300
AUTO_LOAD_BUDGET_CHARS = 20_000
OVERVIEW_ARCHITECTURE_DOCS = %w[PRODUCT_OVERVIEW.md ARCHITECTURE.md].freeze
OVERVIEW_ARCHITECTURE_BUDGET_CHARS = 1_000
VERSION_FILES = {
  "PRODUCT_OVERVIEW.md" => File.join(ROOT, "PRODUCT_OVERVIEW.md"),
  "ARCHITECTURE.md" => File.join(ROOT, "ARCHITECTURE.md")
}.freeze
CHANGELOG = File.join(ROOT, "CHANGELOG.md")

class RuleVerifier
  def initialize(expected_version: nil)
    @expected_version = normalize_version(expected_version)
    @checks = []
  end

  def run
    catalog = generator_catalog
    verify_hard_constraints(catalog.fetch("docs"))
    verify_required_docs(catalog)
    verify_generator_contracts(catalog)
    verify_generated_artifact
    verify_generated_index_artifact
    verify_doc_budget
    verify_project_agent_generator
    verify_project_agent_templates
    verify_invalid_arguments
    verify_release_workflow
    verify_versions
    verify_nested_agents

    {
      passed: @checks.all? { |check| check.fetch(:passed) },
      expected_version: @expected_version,
      checks: @checks
    }
  end

  private

  def verify_hard_constraints(docs)
    missing = docs.each_with_object([]) do |doc, result|
      path = File.join(ROOT, doc.fetch("file"))
      result << doc.fetch("file") unless File.read(path, encoding: "UTF-8").match?(/^## 硬约束$/)
    end
    record("主题文档硬约束", missing.empty?, missing.empty? ? "全部主题文档均包含“硬约束”章节。" : "缺少章节：#{missing.join(', ')}")
  end

  def verify_required_docs(catalog)
    required_files = catalog.fetch("docs").select { |doc| doc.fetch("tags").include?("required") }.map { |doc| doc.fetch("file") }
    missing = catalog.fetch("profiles").flat_map do |name, profile|
      output = generator_output("--profile", name, "--compact", "--dry-run")
      required_files.reject { |file| output.include?("`#{file}`") }.map { |file| "#{name}: #{file}" }
    end
    record("必选规则覆盖", missing.empty?, missing.empty? ? "所有项目画像都会整合必选规则。" : "缺少必选规则：#{missing.join(', ')}")
  end

  def verify_generator_contracts(catalog)
    delivery = catalog.fetch("docs").find { |doc| doc.fetch("key") == "delivery" }
    requirements = catalog.fetch("docs").find { |doc| doc.fetch("key") == "requirements" }
    required = catalog.fetch("docs").select { |doc| doc.fetch("tags").include?("required") }.map { |doc| doc.fetch("key") }
    profile = catalog.fetch("profiles").fetch("delivery", {}).fetch("docs", [])
    passed = delivery && delivery.fetch("file") == "delivery.md" &&
      requirements && requirements.fetch("file") == "requirements.md" &&
      required.sort == %w[ai-guardrails programming version-control] && profile == %w[requirements delivery deployment version-control]
    record("delivery 与需求可选目录", passed, "交付画像叠加 requirements / delivery / deployment / version-control；required 保持原有三项底线。")

    selections = [
      [%w[--profile generic --docs programming.md], %w[programming.md design.md version-control.md ai-guardrails.md]],
      [%w[--profile generic --docs requirements,requirements.md],
       %w[programming.md design.md version-control.md requirements.md ai-guardrails.md]],
      [%w[--profile generic --profile delivery --profile delivery --docs programming.md,requirements.md,delivery,delivery.md],
       %w[programming.md design.md version-control.md requirements.md delivery.md deployment.md ai-guardrails.md]]
    ]
    errors = selections.map do |arguments, expected|
      files = indexed_files(generator_output(*arguments, "--index", "--fragment", "--dry-run"))
      "#{arguments.join(' ')} => #{files.join(', ')}" unless files == expected
    end.compact
    %w[--all full].each do |selection|
      arguments = selection == "--all" ? ["--all"] : ["--profile", selection]
      files = indexed_files(generator_output(*arguments, "--index", "--fragment", "--dry-run"))
      errors << "#{selection} 未覆盖全部主题" unless files == catalog.fetch("docs").map { |doc| doc.fetch("file") }
    end
    record("画像叠加与别名去重", errors.empty?, errors.empty? ? "技术画像可叠加 delivery；key / 文件别名与重复画像按主题去重；--all / full 覆盖全部主题。" : errors.join("；"))
    verify_output_modes(catalog)
    verify_requirement_loading
    verify_compact_constraints(catalog)
  end

  def verify_requirement_loading
    errors = []
    %w[CLAUDE.md AGENTS.md].each do |name|
      [[], ["--compact"], ["--index"]].each do |mode|
        output = generator_output("--profile", "generic", "--output", name, *mode, "--dry-run")
        instructions = output.split(/^## (?:本次整合文档|按需规则索引)$/, 2).first
        next if instructions.include?("`requirements.md`") && instructions.include?("需求") && instructions.include?("验收")

        errors << "#{name} #{mode.empty? ? 'full' : mode.first} 缺少需求读取指令"
      end
    end
    record("需求主题按需读取", errors.empty?, errors.empty? ? "CLAUDE / AGENTS 的 full、compact、index 入口均说明需求与验收读取 requirements.md，不要求加入所有技术画像。" : errors.join("；"))
  end

  def verify_compact_constraints(catalog)
    errors = catalog.fetch("docs").map do |doc|
      file = doc.fetch("file")
      source = File.read(File.join(ROOT, file), encoding: "UTF-8")
      expected = source[/^## 硬约束\n(.*?)(?=^## |\z)/m, 1].to_s.lines.reject { |line| line.lstrip.start_with?(">") }.join.strip
      actual = all_compact_output[/^> 来源：`#{Regexp.escape(file)}`\n## 硬约束\n(.*?)(?=^# |\z)/m, 1].to_s.strip
      file unless actual == expected && !expected.empty?
    end.compact
    record("全量 compact 硬约束保留", errors.empty?, errors.empty? ? "逐主题比较实际全量 compact 输出：全部硬约束与源章节一致，仅去除说明引用，不删条目或添加背景。" : "硬约束正文不一致：#{errors.join(', ')}")
  end

  def all_compact_output
    @all_compact_output ||= generator_output("--all", "--compact", "--dry-run")
  end

  def verify_output_modes(catalog)
    arguments = %w[--profile delivery --dry-run]
    full = generator_output(*arguments, "--fragment")
    compact = generator_output(*arguments, "--compact", "--fragment")
    index = generator_output(*arguments, "--index", "--fragment")
    selected = %w[requirements delivery deployment version-control ai-guardrails programming]
    missing_constraints = selected.flat_map do |key|
      doc = catalog.fetch("docs").find { |entry| entry.fetch("key") == key }
      source = File.read(File.join(ROOT, doc.fetch("file")), encoding: "UTF-8")
      section = source[/^## 硬约束\n(.*?)(?=^## |\z)/m, 1]
      section.to_s.lines.map(&:strip).select { |line| line.start_with?("- ") }.reject { |line| compact.include?(line) }
    end
    details = ["## 目标与适用边界", "## 写文件方式的优先级"]
    mode_ok = full.include?("## 硬约束") && details.all? { |heading| full.include?(heading) } &&
      missing_constraints.empty? && details.none? { |heading| compact.include?(heading) } &&
      !index.include?("## 硬约束") && !index.include?("- **MUST") && indexed_files(index).size == selected.size
    record("index / compact 正文边界", mode_ok, mode_ok ? "index 仅含主题索引；compact 保留所选主题全部硬约束且不嵌背景；完整模式仍包含细则。" : "正文模式边界异常或 compact 丢失硬约束：#{missing_constraints.join('；')}")

    wrappers = /^<!-- GENERATED FILE|^## 使用说明$|^## 始终遵守|^# (?:CLAUDE|AGENTS)\.md$/
    fragment_ok = [full, compact, index].none? { |content| content.match?(wrappers) } &&
      full.start_with?("## 本次整合文档\n") && compact.start_with?("## 本次整合文档\n") &&
      index.start_with?("## 按需规则索引\n") && index.lines.all? { |line| line.start_with?("## 按需规则索引", "- [") }
    # 索引路径和 CLAUDE essentials 分别检查，避免 --fragment 被默认输出文件名污染。
    %w[CLAUDE.md AGENTS.md].each do |name|
      wrapped = generator_output(*arguments, "--index", "--output", name)
      fragment = generator_output(*arguments, "--index", "--output", name, "--fragment")
      fragment_ok &&= fragment == index && wrapped.start_with?("<!-- GENERATED FILE") &&
        wrapped.include?("## 使用说明") && wrapped.include?("系统 / 开发者 / 用户指令") &&
        !wrapped.include?("## 硬约束") && !wrapped.include?("- **MUST") &&
        (wrapped.include?("## 始终遵守") == (name == "CLAUDE.md"))
    end
    [[], ["--compact"]].each do |mode|
      wrapped = generator_output(*arguments, *mode)
      fragment_ok &&= wrapped.start_with?("<!-- GENERATED FILE") && wrapped.include?("## 使用说明") &&
        wrapped.include?("系统 / 开发者 / 用户指令") && wrapped.include?("## 硬约束")
    end
    record("fragment 纯片段与入口包装", fragment_ok, fragment_ok ? "fragment 只有索引及对应正文；index fragment 仅索引；完整入口保留来源标记、优先级和按输出区分的 essentials。" : "fragment 混入常驻包装，或非 fragment 入口包装缺失。")
  end

  def indexed_files(content)
    content.scan(/^- \[[^\n]+\]\([^\n]+\)（`([^`]+)`）/).flatten
  end

  def verify_generated_artifact
    Dir.mktmpdir("agentrules-verify") do |dir|
      expected = File.join(dir, "GENERATED_CLAUDE.md")
        generator_output("--all", "--index", "--output", expected, "--force")
        generated = File.exist?(GENERATED_ARTIFACT) && File.binread(GENERATED_ARTIFACT) == File.binread(expected)
        content = generated ? File.read(GENERATED_ARTIFACT, encoding: "UTF-8") : ""
        header = content.start_with?("<!-- GENERATED FILE — DO NOT EDIT.")
        canonical = content.include?("https://github.com/niuwoai/agentrules/blob/main/CLAUDE.md")
        no_embedded_body = !content.include?("## 硬约束")
        record("生成产物同步", generated && header && canonical && no_embedded_body, generated && header && canonical && no_embedded_body ? "GENERATED_CLAUDE.md 与生成器一致：概要索引、niuwoai 规范地址、无内嵌硬约束正文。" : "请重新生成 GENERATED_CLAUDE.md（--all --index），并检查规范地址与未内嵌正文。")
    end
  end

  def verify_generated_index_artifact
    Dir.mktmpdir("agentrules-index-verify") do |dir|
      expected = File.join(dir, "GENERATED_AGENTS.md")
      generator_output("--all", "--index", "--output", expected, "--force")
      generated = File.exist?(GENERATED_INDEX_ARTIFACT) && File.binread(GENERATED_INDEX_ARTIFACT) == File.binread(expected)
      content = generated ? File.read(GENERATED_INDEX_ARTIFACT, encoding: "UTF-8") : ""
      header = content.start_with?("<!-- GENERATED FILE — DO NOT EDIT.")
      source_files = generator_catalog.fetch("docs").map { |doc| doc.fetch("file") }
      links_all_sources = source_files.all? { |file| content.include?("/#{file}") }
      no_embedded_body = !content.include?("## 硬约束")
      passed = generated && header && links_all_sources && no_embedded_body
      detail = passed ? "GENERATED_AGENTS.md 与索引生成器一致，只包含按需链接，不内嵌主题正文。" : "请重新生成 GENERATED_AGENTS.md，并检查来源链接和正文未内嵌约束。"
      record("索引产物同步", passed, detail)
    end
  end

  def verify_doc_budget
    sizes = AUTO_LOAD_DOCS.to_h do |file|
      [file, document_size(File.read(File.join(ROOT, file), encoding: "UTF-8"))]
    end
    errors = sizes.map { |file, size| "#{file} #{size_label(size)}" unless within_entry_budget?(size) }.compact
    OVERVIEW_ARCHITECTURE_DOCS.each do |file|
      chars = sizes.fetch(file).fetch(:chars)
      errors << "#{file} #{chars} 字符（产品/架构上限 #{OVERVIEW_ARCHITECTURE_BUDGET_CHARS} 字符）" if chars > OVERVIEW_ARCHITECTURE_BUDGET_CHARS
    end
    threshold = "≤ #{AUTO_LOAD_BUDGET_LINES} 行 且 ≤ 20,000 字符"
    compact_threshold = "≤ 1,000 字符（约 1k tokens）"
    guardrails = File.read(File.join(ROOT, "ai-guardrails.md"), encoding: "UTF-8")
    errors << "ai-guardrails.md 缺少预算阈值文本" unless guardrails.include?(threshold) && guardrails.include?(compact_threshold)
    detail = if errors.empty?
      "入口文档均在预算内：#{sizes.map { |file, size| "#{file} #{size_label(size)}" }.join('、')}。"
    else
      "入口超出预算或阈值不一致：#{errors.join('；')}；通用上限 #{threshold}，请索引化或归档。"
    end
    record("入口文档体量预算", errors.empty?, detail)

    compact = document_size(generator_output("--all", "--compact", "--dry-run"))
    passed = within_entry_budget?(compact)
    record("全量 compact 体量实测", passed, "全量 compact 实际 #{size_label(compact)}；上限 #{threshold}。#{passed ? '' : '不得删除有效硬约束或提高阈值；自动加载入口应改用 index。'}")
  end

  def document_size(content)
    { lines: content.lines.size, chars: content.length }
  end

  def within_entry_budget?(size)
    size.fetch(:lines) <= AUTO_LOAD_BUDGET_LINES && size.fetch(:chars) <= AUTO_LOAD_BUDGET_CHARS
  end

  def size_label(size)
    "#{size.fetch(:lines)} 行 / #{size.fetch(:chars)} 字符"
  end

  def verify_project_agent_generator
    Dir.mktmpdir("agentrules-project") do |dir|
      create_project_fixture(dir)
      FileUtils.mkdir_p(File.join(dir, "docs", "requirements"))
      File.binwrite(File.join(dir, "LESSONS.md"), "# 项目已有经验\r\n\r\n保留现有记录与行尾。\r\n")
      File.write(File.join(dir, "docs", "requirements", "existing.md"), "# 已有需求\n\n保留目标、范围与验收记录。\n", encoding: "UTF-8")
      before = fixture_snapshot(dir)
      dry = project_generator_output(dir, "--profile", "delivery", "--dry-run",
        "--json-output", File.join(dir, "reports", "dry.json"), "--markdown-output", File.join(dir, "reports", "dry.md"))
      dry_ok = before == fixture_snapshot(dir) && dry.fetch("actions").all? { |action| action.fetch("status") == "planned" }
      generator_output("--profile", "delivery", "--index", "--output", File.join(dir, "preview.md"), "--dry-run")
      dry_ok &&= before == fixture_snapshot(dir)
      record("生成器 dry-run 无写入", dry_ok, dry_ok ? "规则与项目生成器 dry-run 均不改变夹具；显式报告路径也不创建文件。" : "dry-run 写入文件或计划状态异常。")

      first = project_generator_output(dir, "--profile", "delivery", "--profile", "python-api")
      generated_paths = %w[AGENTS.md apps/web/AGENTS.md services/api/AGENTS.md .github/AGENTS.md]
      generated = generated_paths.all? { |path| File.exist?(File.join(dir, path)) }
      parent_chain = nested_fixture_agents(dir).all? { |path| File.read(path, encoding: "UTF-8").include?("> **Parent:**") }
      web_agent = File.read(File.join(dir, "apps", "web", "AGENTS.md"), encoding: "UTF-8")
      package_manager_ok = web_agent.include?("`npm ci`") && web_agent.include?("`npm run test`")
      root_agent = File.read(File.join(dir, "AGENTS.md"), encoding: "UTF-8")
      profiles_ok = first.fetch("profiles") == %w[go-react-embed delivery python-api] && indexed_files(root_agent).include?("python.md")
      index_ok = first.fetch("rules_mode") == "index" && root_agent.include?("/requirements.md") && root_agent.include?("/delivery.md") &&
        !root_agent.include?("## 硬约束") && !root_agent.include?("## 使用说明") && !root_agent.include?("## 始终遵守")
      after = fixture_snapshot(dir)
      existing_preserved = before.all? { |path, bytes| after[path] == bytes }
      only_agents = (after.keys - before.keys).sort == generated_paths.sort
      second = project_generator_output(dir, "--rules-mode", "compact", "--profile", "delivery")
      preserved = after == fixture_snapshot(dir) && second.fetch("actions").all? { |action| action.fetch("status") == "skipped" }
      passed = generated && parent_chain && package_manager_ok && profiles_ok && index_ok && existing_preserved && only_agents && preserved && first.fetch("template") == "go-react-embed"
      record("项目 AGENTS 脚手架", passed, passed ? "默认 index、自动技术模板、画像叠加、锁文件命令与 Parent 链通过；仅新增缺失 AGENTS，首次生成与重复执行均逐字节保留已有需求、经验与规则记录。" : "项目脚手架默认模式、画像、目录、命令、Parent 链、首次生成保留或重复执行保护异常。")
    end
    verify_existing_nested_agent
  end

  def verify_existing_nested_agent
    Dir.mktmpdir("agentrules-preserve") do |dir|
      create_project_fixture(dir)
      path = File.join(dir, "apps", "web", "AGENTS.md")
      original = "# 本地规则\r\n\r\n> **Scope:** apps/web\r\n> **Parent:** [根规则](../../AGENTS.md)\r\n\r\n保留手写字节与行尾。\r\n"
      File.binwrite(path, original)
      result = project_generator_output(dir, "--profile", "delivery", "--rules-mode", "compact")
      action = result.fetch("actions").find { |entry| entry.fetch("path") == "apps/web/AGENTS.md" }
      passed = File.binread(path) == original.b && action.fetch("status") == "skipped"
      record("既有嵌套规则字节保留", passed, passed ? "已有嵌套 AGENTS 的手写内容与 CRLF 字节保留，其他规则正常生成。" : "已有嵌套 AGENTS 被覆盖或未标记跳过。")
    end
  end

  def verify_project_agent_templates
    profiles = { "generic" => "generic", "react-web" => "desktop-web", "go-api" => "go-api", "go-react-embed" => "go-react-embed" }
    errors = []
    sizes = []
    profiles.each do |template, profile|
      Dir.mktmpdir("agentrules-template") do |dir|
        create_project_fixture(dir)
        project_generator_output(dir, "--template", template, "--profile", "delivery")
        root = File.read(File.join(dir, "AGENTS.md"), encoding: "UTF-8")
        fragment = generator_output("--profile", profile, "--profile", "delivery", "--index", "--fragment", "--output", "AGENTS.md", "--dry-run").strip
        size = document_size(root)
        sizes << "#{template}+delivery #{size_label(size)}"
        instructions = root.split("## 按需规则索引", 2).first
        required_loading = %w[ai-guardrails.md programming.md version-control.md requirements.md].all? { |file| instructions.include?("`#{file}`") } &&
          instructions.include?("修改代码前") && instructions.include?("读取") && instructions.include?("验收")
        valid = root.include?("> **Template:** `#{template}`") && root.end_with?("#{fragment}\n") &&
          indexed_files(root).include?("delivery.md") && !root.include?("## 硬约束") &&
          !root.include?("## 始终遵守") && root.include?("不要求每轮全部读取") && required_loading
        errors << "#{template} index 模板输出异常或缺少必选规则读取指令" unless valid
        errors << "#{template} 超出入口预算" unless within_entry_budget?(size)
      end
      Dir.mktmpdir("agentrules-compact-template") do |dir|
        create_project_fixture(dir)
        project_generator_output(dir, "--template", template, "--profile", "delivery", "--rules-mode", "compact")
        root = File.read(File.join(dir, "AGENTS.md"), encoding: "UTF-8")
        fragment = generator_output("--profile", profile, "--profile", "delivery", "--compact", "--fragment", "--output", "AGENTS.md", "--dry-run").strip
        valid = root.end_with?("#{fragment}\n") && root.include?("## 硬约束") &&
          !root.include?("## 目标与适用边界") && !root.include?("## 使用说明") && !root.include?("## 始终遵守")
        errors << "#{template} compact 模板输出异常" unless valid
      end
    end
    record("四种项目模板与 index 根预算", errors.empty?, "#{sizes.join('；')}。#{errors.empty? ? '默认 index 与显式 compact 输出均符合所选片段，index 实际根文件均在预算内。' : errors.join('；')}")
  end

  def verify_invalid_arguments
    Dir.mktmpdir("agentrules-invalid") do |dir|
      create_project_fixture(dir)
      File.write(File.join(dir, "AGENTS.md"), "# 已有根规则\n", encoding: "UTF-8")
      before = fixture_snapshot(dir)
      failures = []
      [
        [PROJECT_AGENT_GENERATOR, %w[--rules-mode full], "未知规则模式"],
        [PROJECT_AGENT_GENERATOR, %w[--profile missing], "未知画像"],
        [PROJECT_AGENT_GENERATOR, %w[--profile delivery --profile missing], "未知画像"],
        [PROJECT_AGENT_GENERATOR, %w[--template missing], "未知模板"],
        [GENERATOR, %w[--index --compact], "不能同时使用"],
        [GENERATOR, %w[--profile missing], "未知画像"],
        [GENERATOR, %w[--all --profile missing], "未知画像"],
        [GENERATOR, %w[--docs missing], "未知文档"]
      ].each do |script, arguments, message|
        target = script == PROJECT_AGENT_GENERATOR ? ["--target", dir] : ["--output", File.join(dir, "AGENTS.md"), "--force"]
        output, status = Open3.capture2e(RbConfig.ruby, script, *target, *arguments)
        valid = !status.success? && output.include?(message) && !output.include?("from #{script}:") && before == fixture_snapshot(dir)
        failures << "#{File.basename(script)} #{arguments.join(' ')}" unless valid
      end
      record("非法模式与画像安全失败", failures.empty?, failures.empty? ? "非法模式、模板、叠加画像与主题均明确报错；已有根规则不掩盖非法画像，失败不写入或覆盖文件。" : "参数检查失败：#{failures.join('；')}")
    end
  end

  def fixture_snapshot(dir)
    Dir.glob(File.join(dir, "**", "*"), File::FNM_DOTMATCH).select { |path| File.file?(path) }.to_h do |path|
      [path.delete_prefix("#{dir}/"), File.binread(path)]
    end
  end

  def verify_release_workflow
    test = File.join(ROOT, "tests", "release_workflow_test.rb")
    output, status = Open3.capture2e(RbConfig.ruby, test)
    summary = output.lines.find { |line| line.match?(/\d+ runs, \d+ assertions, \d+ failures, \d+ errors/) }
    record("发布工作流隔离回归", status.success? && !summary.nil?, status.success? && summary ? summary.strip : output.strip)
  end

  def create_project_fixture(dir)
    FileUtils.mkdir_p(File.join(dir, "apps", "web"))
    FileUtils.mkdir_p(File.join(dir, "services", "api"))
    FileUtils.mkdir_p(File.join(dir, ".github", "workflows"))
    package = { name: "fixture", private: true, scripts: { lint: "eslint .", test: "vitest run", build: "vite build" } }
    File.write(File.join(dir, "package-lock.json"), "{}\n", encoding: "UTF-8")
    File.write(File.join(dir, "apps", "web", "package.json"), "#{JSON.pretty_generate(package)}\n", encoding: "UTF-8")
    File.write(File.join(dir, "services", "api", "go.mod"), "module example.test/api\n\ngo 1.24\n", encoding: "UTF-8")
  end

  def project_generator_output(dir, *args)
    output, status = Open3.capture2e(
      RbConfig.ruby,
      PROJECT_AGENT_GENERATOR,
      "--target",
      dir,
      *args
    )
    raise "项目 AGENTS 生成器执行失败：#{output}" unless status.success?

    JSON.parse(output)
  end

  def nested_fixture_agents(dir)
    Dir.glob(File.join(dir, "**", "AGENTS.md")).reject { |path| path == File.join(dir, "AGENTS.md") }
  end

  def verify_versions
    versions = VERSION_FILES.transform_values { |path| extract_version(path) }
    versions["CHANGELOG.md"] = extract_changelog_version
    expected_matches = @expected_version.nil? || versions.values.all? { |version| version == @expected_version }
    consistent = versions.values.uniq.size == 1
    passed = consistent && expected_matches
    detail = if passed
      "版本一致：#{versions.values.first}。"
    elsif !consistent
      "版本不一致：#{versions.map { |file, version| "#{file}=#{version || '缺失'}" }.join(', ')}"
    else
      "版本应为 #{@expected_version}，实际为 #{versions.values.first || '缺失'}。"
    end
    record("版本与变更记录", passed, detail)
  end

  def verify_nested_agents
    nested = Dir.glob(File.join(ROOT, "**", "AGENTS.md")).reject { |path| path == File.join(ROOT, "AGENTS.md") }
    missing = nested.reject do |path|
      File.read(path, encoding: "UTF-8").match?(/^> \*\*Parent:\*\*/)
    end.map { |path| path.delete_prefix("#{ROOT}/") }
    record("嵌套 AGENTS 上溯链", missing.empty?, missing.empty? ? "没有缺失父级链接的嵌套 AGENTS.md。" : "缺少 Parent 链接：#{missing.join(', ')}")
  end

  def generator_catalog
    @catalog ||= JSON.parse(generator_output("--catalog-json"))
  end

  def generator_output(*args)
    output, status = Open3.capture2e(RbConfig.ruby, GENERATOR, *args)
    return output if status.success?

    raise "生成器执行失败：#{output}"
  end

  def extract_version(path)
    File.read(path, encoding: "UTF-8")[/当前版本：v([0-9]+\.[0-9]+\.[0-9]+)/, 1]
  end

  def extract_changelog_version
    File.read(CHANGELOG, encoding: "UTF-8")[/^## \[([0-9]+\.[0-9]+\.[0-9]+)\]/, 1]
  end

  def normalize_version(value)
    value&.sub(/\Av/, "")
  end

  def record(name, passed, detail)
    @checks << { name: name, passed: passed, detail: detail }
  end
end

def parse_options(argv)
  options = {
    expected_version: nil,
    json_output: "tmp/rule-verification.json",
    markdown_output: "tmp/rule-verification.md",
    write_report: true
  }

  OptionParser.new do |opts|
    opts.banner = "用法：ruby scripts/verify_rules.rb [options]"
    opts.on("--expected-version VERSION", "要求 Product Overview、Architecture 和 Changelog 使用该版本") { |value| options[:expected_version] = value }
    opts.on("--json-output PATH", "JSON 报告路径") { |value| options[:json_output] = value }
    opts.on("--markdown-output PATH", "Markdown 报告路径") { |value| options[:markdown_output] = value }
    opts.on("--no-report", "报告改写到 stdout，不落盘，工作区保持无副作用") { options[:write_report] = false }
  end.parse!(argv)
  options
end

def report_path(path)
  File.expand_path(path, ROOT)
end

def write_report(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content, encoding: "UTF-8")
end

def markdown_report(result)
  status = result.fetch(:passed) ? "PASS" : "FAIL"
  lines = ["# Rule Verification Report", "", "> Result: #{status}"]
  lines << "> Expected version: v#{result.fetch(:expected_version)}" if result.fetch(:expected_version)
  lines << "" << "| 检查项 | 结果 | 说明 |" << "|--------|------|------|"
  result.fetch(:checks).each do |check|
    lines << "| #{check.fetch(:name)} | #{check.fetch(:passed) ? 'PASS' : 'FAIL'} | #{check.fetch(:detail)} |"
  end
  "#{lines.join("\n")}\n"
end

options = parse_options(ARGV)
result = RuleVerifier.new(expected_version: options.fetch(:expected_version)).run
if options.fetch(:write_report)
  write_report(report_path(options.fetch(:json_output)), "#{JSON.pretty_generate(result)}\n")
  write_report(report_path(options.fetch(:markdown_output)), markdown_report(result))
else
  puts JSON.pretty_generate(result)
  puts markdown_report(result)
end
puts "规则校验：#{result.fetch(:passed) ? '通过' : '失败'}"
exit(result.fetch(:passed) ? 0 : 1)
