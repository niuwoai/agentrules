#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "optparse"

# 默认编码随 locale 变化会让子进程输出和文件写入报 US-ASCII 编码错，这里显式固定 UTF-8
Encoding.default_external = Encoding::UTF_8

RuleDoc = Struct.new(:key, :file, :title, :summary, :tags, keyword_init: true)

ROOT = File.expand_path("..", __dir__)
DEFAULT_OUTPUT = "CLAUDE.md"
RULES_REPOSITORY_URL = "https://github.com/niuwoai/agentrules/blob/main"
RULES_CANONICAL_URL = "#{RULES_REPOSITORY_URL}/CLAUDE.md"

def output_document_name(path)
  File.basename(path.to_s.empty? ? DEFAULT_OUTPUT : path)
end

DOCS = [
  RuleDoc.new(
    key: "ai-guardrails",
    file: "ai-guardrails.md",
    title: "AI 协作红线",
    summary: "文件编辑方式、破坏性操作确认、需求文本与产品文案边界、界面要求与实现行为分离、共享分支保护和如实汇报",
    tags: %w[common ai required]
  ),
  RuleDoc.new(
    key: "programming",
    file: "programming.md",
    title: "编程通用规范",
    summary: "代码风格、错误处理、测试、版本控制、安全和日志",
    tags: %w[common backend frontend app required]
  ),
  RuleDoc.new(
    key: "design",
    file: "design.md",
    title: "多端产品设计规范",
    summary: "新项目启动门禁、界面呈现与实现行为分离、UI 规范方向和多端规范",
    tags: %w[design h5 desktop-web mac-app android-app frontend app]
  ),
  RuleDoc.new(
    key: "frontend",
    file: "frontend.md",
    title: "前端规范",
    summary: "TypeScript、React、状态管理、CSS、性能、安全和测试",
    tags: %w[frontend h5 desktop-web react web]
  ),
  RuleDoc.new(
    key: "go",
    file: "go.md",
    title: "Go 规范",
    summary: "Go 项目结构、错误处理、并发、DI、测试、性能和 Go + React embed",
    tags: %w[go backend api service]
  ),
  RuleDoc.new(
    key: "python",
    file: "python.md",
    title: "Python 规范",
    summary: "Python 环境、类型、异步、数据库、测试和常用库",
    tags: %w[python backend api service]
  ),
  RuleDoc.new(
    key: "database-migrations",
    file: "database-migrations.md",
    title: "数据库迁移规范",
    summary: "迁移版本、建表、索引、启动迁移、回滚和 CI/CD",
    tags: %w[database migration backend api service]
  ),
  RuleDoc.new(
    key: "database-queries",
    file: "database-queries.md",
    title: "数据库查询规范",
    summary: "SQL 编写、索引、查询优化、EXPLAIN 和 ORM",
    tags: %w[database sql backend api service]
  ),
  RuleDoc.new(
    key: "database-sync",
    file: "database-sync.md",
    title: "数据库同步规范",
    summary: "全量、增量、实时同步、一致性、冲突解决和监控",
    tags: %w[database sync backend service]
  ),
  RuleDoc.new(
    key: "deployment",
    file: "deployment.md",
    title: "服务部署规范",
    summary: "发布检查、迁移、产物备份、健康检查、回滚和 CI/CD",
    tags: %w[deployment backend api service ops]
  ),
  RuleDoc.new(
    key: "linux-server",
    file: "linux-server.md",
    title: "Linux 服务器规范",
    summary: "安全基线、监控、备份、日志、性能调优、Docker 和应急响应",
    tags: %w[linux ops deployment service]
  ),
  RuleDoc.new(
    key: "version-control",
    file: "version-control.md",
    title: "版本管理规范",
    summary: "分支策略、语义化版本、Build 号、CHANGELOG、.gitignore 和 Git 工作流",
    tags: %w[version git common required]
  )
].freeze

PROFILES = {
  "generic" => {
    name: "通用项目",
    docs: %w[programming design version-control]
  },
  "h5" => {
    name: "H5 移动网页",
    docs: %w[programming design frontend version-control]
  },
  "desktop-web" => {
    name: "电脑版网页 / 后台 / SaaS",
    docs: %w[programming design frontend database-queries version-control]
  },
  "mac-app" => {
    name: "macOS App",
    docs: %w[programming design version-control]
  },
  "android-app" => {
    name: "Android App",
    docs: %w[programming design version-control]
  },
  "go-api" => {
    name: "Go 后端服务",
    docs: %w[programming go database-migrations database-queries deployment linux-server version-control]
  },
  "go-react-embed" => {
    name: "Go + React embed 全栈",
    docs: %w[programming design frontend go database-migrations database-queries deployment linux-server version-control]
  },
  "python-api" => {
    name: "Python 后端服务",
    docs: %w[programming python database-migrations database-queries deployment linux-server version-control]
  },
  "data-sync" => {
    name: "数据库同步 / ETL",
    docs: %w[programming database-sync database-queries database-migrations deployment version-control]
  },
  "full" => {
    name: "完整规则集",
    docs: DOCS.map(&:key)
  }
}.freeze

class RuleSelector
  def initialize(options)
    @options = options
  end

  def selected_docs
    if @options[:all]
      return DOCS
    end

    profile_keys = Array(@options[:profiles])
    explicit_keys = Array(@options[:docs])
    selected_keys = profile_keys.flat_map { |profile| profile_docs(profile) } + explicit_keys

    return docs_by_keys(selected_keys) unless selected_keys.empty?
    return interactive_selection if $stdin.tty? && $stdout.tty?

    docs_by_keys(PROFILES.fetch("go-react-embed")[:docs])
  end

  private

  def profile_docs(profile)
    unless PROFILES.key?(profile)
      abort("未知画像：#{profile}。可选：#{PROFILES.keys.join(", ")}")
    end

    PROFILES.fetch(profile)[:docs]
  end

  def docs_by_keys(keys)
    normalized = keys.map(&:to_s).flat_map { |item| item.split(",") }.map(&:strip).reject(&:empty?)
    docs = normalized.uniq.map do |key|
      DOCS.find { |doc| doc.key == key || doc.file == key } ||
        abort("未知文档：#{key}。可选：#{DOCS.map(&:key).join(", ")}")
    end
    ensure_required_docs(docs)
  end

  def ensure_required_docs(docs)
    required = DOCS.select { |doc| doc.tags.include?("required") }
    missing_required = required.reject { |required_doc| docs.any? { |doc| doc.key == required_doc.key } }
    docs + missing_required
  end

  def interactive_selection
    prompt = try_tty_prompt
    if prompt
      selected_keys = prompt.multi_select(
        "选择要整合进 #{document_name} 的规则文档：",
        DOCS.map { |doc| { name: "#{doc.title} - #{doc.summary}", value: doc.key } },
        default: %w[programming design frontend version-control],
        per_page: 12
      )
      return docs_by_keys(selected_keys)
    end

    fallback_selection
  end

  def try_tty_prompt
    require "tty-prompt"
    TTY::Prompt.new(symbols: { marker: ">", radio_on: "x", radio_off: " " })
  rescue LoadError
    nil
  end

  def fallback_selection
    puts "未检测到 tty-prompt，将使用基础终端选择。安装提示：gem install tty-prompt"
    puts "目标输出：#{document_name}"
    puts
    DOCS.each_with_index do |doc, index|
      puts "#{index + 1}. #{doc.title}（#{doc.file}）- #{doc.summary}"
    end
    puts
    print "请输入编号，多个用逗号分隔；直接回车使用 Go + React embed 推荐组合："
    answer = $stdin.gets&.strip

    if answer.nil? || answer.empty?
      return docs_by_keys(PROFILES.fetch("go-react-embed")[:docs])
    end

    indexes = answer.split(",").map(&:strip).reject(&:empty?).map do |part|
      Integer(part, exception: false) || abort("编号不是数字：#{part}")
    end
    keys = indexes.map do |index|
      DOCS.fetch(index - 1) { abort("编号超出范围：#{index}") }.key
    end
    docs_by_keys(keys)
  end

  def document_name
    output_document_name(@options[:output])
  end
end

class RulesBundleBuilder
  def initialize(docs, options)
    @docs = docs
    @options = options
  end

    def build
      parts = [instructions]
      parts << claude_essentials if claude_index_output?
      parts << source_index
      parts << body unless @options[:index]
    parts.unshift(front_matter) unless @options[:fragment]
    parts.join("\n\n")
  end

  private

  def document_name
    output_document_name(@options[:output])
  end

    def front_matter
      profile_names = Array(@options[:profiles]).map { |key| PROFILES.fetch(key, { name: key })[:name] }
      profile_line = profile_names.empty? ? "自定义选择" : profile_names.join("、")
      mode_line = if @options[:index]
                    if claude_index_output?
                      "\n> 模式：对外发布概要索引（--index），规则正文在 GitHub 按需读取，不内嵌于本文件。"
                    else
                      "\n> 模式：按需读取索引版（--index），不内嵌主题规则正文。"
                    end
                  elsif @options[:compact]
                    "\n> 模式：硬约束精简版（--compact），完整背景与细节见规则库原文。"
                  else
                    ""
                  end
      canonical_line = claude_index_output? ? "\n> 规范地址：`#{RULES_CANONICAL_URL}`" : ""

      <<~MARKDOWN.strip
        <!-- GENERATED FILE — DO NOT EDIT.
             Source: Willdeep rule documents and scripts/generate_claude_md.rb -->

        # #{document_name}

        > 由 `scripts/generate_claude_md.rb` 生成；请修改规则源文件后重新生成。
        > 规则画像：#{profile_line}
        > 生成来源：Willdeep 规则库。#{canonical_line}#{mode_line}
      MARKDOWN
    end

  def instructions
    return index_instructions if @options[:index]

    <<~MARKDOWN.strip
      ## 使用说明

      - 本文件是面向 Claude / Codex / 其他 AI 编程助手的整合规则入口。
      - 若本文件与项目内更具体、更晚出现的 `AGENTS.md`、`CLAUDE.md` 或用户指令冲突，以更具体、更晚出现的指令为准。
      - AI 开工前先判断当前仓库是新项目、半成品还是既有项目迭代；判断不清时按新项目处理。
      - 新项目或规则缺失时，先生成/更新 `AGENTS.md`、`CLAUDE.md`、`PRODUCT_OVERVIEW.md`、`ARCHITECTURE.md` 或等价文档，写清产品定义、技术栈、模块边界、数据流、设计规范、UI token、多语言计划、版本和验收标准。
      - 新项目必须创建根目录 `ARCHITECTURE.md`；技术栈、模块边界、服务通信、数据存储、接口协议、认证授权、部署拓扑或关键集成发生变化时，必须同步更新。
      - 新项目关键决策应沉淀到 `docs/product-brief.md`、`ARCHITECTURE.md`、`docs/design-system.md`、`docs/ui-tokens.md`、`docs/i18n.md` 和 `docs/decisions/`，不要只依赖 memory 或聊天记录。
      - 新项目第一轮沟通只问 6-8 个高价值主题：定位、用户场景、首版范围、平台设备、设计方向、多语言、数据库/数据权限、交付验收；能从仓库判断的内容写成默认假设。
      - 架构、数据库、部署、测试、权限等工程决策先给最佳实践建议，再让用户确认；不要把选型责任全丢给用户。
      - UI 规范按平台和应用类型先给 2-4 套推荐方向，再让用户选择；选定后沉淀到 `docs/design-system.md`、`docs/ui-tokens.md` 等仓库文档。
      - 架构、设计规范、数据库、多语言、部署和验收等关键决策必须落入仓库文档；memory 和聊天记录不能作为唯一事实来源。
      - 涉及界面项目时，先按设计规范与用户确认平台、用户、核心场景、视觉气质、信息密度、UI 体系和计划支持语言，再进入实现。
      - 修改代码后必须同步版本号、CHANGELOG 和必要的产品概览文档。
      - 不得输出或提交密钥、Token、凭据、个人隐私数据。
    MARKDOWN
  end

    def index_instructions
      if claude_index_output?
        base = @options[:index_base].to_s.sub(%r{/\z}, "")
        return <<~MARKDOWN.strip
          ## 使用说明

          - **本文件是概要索引**，不把各主题「硬约束」正文塞进系统提示；保持短，避免上下文膨胀。
          - **规范全集地址**：#{RULES_CANONICAL_URL}（与本文件同源，随仓库发布更新）。
          - **按需加载主题规则**：仅当任务命中时，再读取下方链接对应文件；不要因看到文件名列表就一次性拉取全部规则。
          - **URL 推导**：主题规则默认位于同一仓库 `main` 分支根目录，模式为 `#{base}/<文件名>`。例如 `ai-guardrails.md` → `#{base}/ai-guardrails.md`；索引未列出的其它 `.md` 规则（若存在）按同模式推导，仅在与任务相关时读取。
          - **本地优先**：若工作区已克隆 [niuwoai/agentrules](https://github.com/niuwoai/agentrules) 或已 vendor 同名文件，优先读本地文件，与远程内容冲突时以**目标业务仓库**内更具体的 `AGENTS.md` / `CLAUDE.md` 为准。
          - **优先级**：系统 / 开发者 / 用户指令 > 目标仓库内更具体的 `AGENTS.md` / `CLAUDE.md` > 本索引。
          - **最低必读（涉及改代码时）**：先读 `ai-guardrails.md`、`programming.md`；提交、发版、打 tag 再读 `version-control.md`；UI 相关再读 `design.md` / `frontend.md`。
          - 不得输出或提交密钥、Token、凭据、个人隐私数据。
        MARKDOWN
      end

      <<~MARKDOWN.strip
        ## 使用说明

        - 本文件是规则索引，不内嵌主题规则正文；不要因为看到索引就一次性读取全部规则。
        - 指令优先级：系统 / 开发者 / 用户指令 > 目标仓库内更具体的 `AGENTS.md` / `CLAUDE.md` > 本索引。
        - 开工前根据任务类型，只读取下方索引中直接相关的规则文件；任务范围扩大时再补读。
        - 修改任何文件前先检查目标仓库的本地规则、工作区状态和既有实现，保留用户已有改动。
        - 涉及代码时至少读取 `ai-guardrails.md`、`programming.md`；涉及提交、版本或发布时再读取 `version-control.md`。
        - 不得输出或提交密钥、Token、凭据、个人隐私数据；疑似敏感信息先停止扩散并脱敏处理。
        - 规则源文件以 GitHub 默认分支为准；本地存在 agentrules 仓库时优先读取同名本地文件。
      MARKDOWN
    end

      def claude_index_output?
        return false unless @options[:index]

        base = File.basename(@options[:output].to_s)
        base.casecmp?(DEFAULT_OUTPUT) || base.casecmp?("GENERATED_CLAUDE.md")
      end

      def claude_essentials
        <<~MARKDOWN.strip
          ## 始终遵守（精简）

          下文是跨任务底线；细则与例外见按需规则索引。

          **协作与安全**
          - 改文件优先 patch/编辑工具，禁止用 shell 覆写；破坏性操作先确认；禁止 force-push 共享分支；测试失败如实报，不宣称已完成。
          - 不输出/提交密钥与凭据；不探测读取私钥、`.env`、token 文件。
          - 不改 `GENERATED FILE — DO NOT EDIT` 产物，改源文件后重新生成；改动范围与任务一致。

          **需求与界面**
          - 不要把需求、验收、Prompt、实现参数当用户界面文案；实现行为由代码完成，界面少字、可点即懂。
          - 用户可见文案走 i18n；新项目先落启动文档再大规模编码；关键决策写仓库文档，不单靠聊天记录。

            **工程**
            - SQL 参数化；核心逻辑有测；错误带上下文；单文件超过 3000 行必须拆分。
            - 发版：`MAJOR.MINOR.BUILD`，每次发版 BUILD +1；改代码同步 CHANGELOG；用户要求提交时打 tag 并推送。
            - 入口文档控体量：概览类 ≤300 行且 ≤20k 字符，产品/架构主文 ≤1k 字符，超限索引化到 `docs/`。
            - 有 Schema 变更须走迁移：`up`/`down` 成对，提供 `migrate up|down|status`；`down` 须验证，prod 回滚谨慎（见 `database-migrations.md`）。
            - 业务仓库维护 `README.md`、`CHANGELOG.md`、`PRODUCT_OVERVIEW.md`、`ARCHITECTURE.md`（或等价文档）；缺则新建，有架构/产品变化时同步更新。
          MARKDOWN
      end

    def source_index
    return embedded_source_index unless @options[:index]

    index_base = @options[:index_base].to_s.sub(%r{/\z}, "")
    lines = @docs.map do |doc|
      "- [#{doc.title}](#{index_base}/#{doc.file})（`#{doc.file}`）：#{doc.summary}"
    end
    (["## 按需规则索引"] + lines).join("\n")
  end

  def embedded_source_index
    lines = @docs.map { |doc| "- `#{doc.file}`：#{doc.summary}" }
    (["## 本次整合文档"] + lines).join("\n")
  end

  def body
    @docs.map do |doc|
      content = doc_content(doc)
      <<~MARKDOWN.strip
        ---

        # #{doc.title}

        > 来源：`#{doc.file}`

        #{content}
      MARKDOWN
    end.join("\n\n")
  end

  def doc_content(doc)
    content = File.read(File.join(ROOT, doc.file), encoding: "UTF-8").strip
    return content unless @options[:compact]

    section = hard_constraints_section(content)
    if section.nil?
      warn "警告：#{doc.file} 缺少「## 硬约束」小节，--compact 模式回退为完整内容。"
      return content
    end

    <<~MARKDOWN.strip
      ## 硬约束

      #{section}
    MARKDOWN
  end

  def hard_constraints_section(content)
    lines = content.lines
    start_index = lines.index { |line| line.strip.match?(/\A##\s*硬约束\z/) }
    return nil unless start_index

    rest = lines[(start_index + 1)..]
    end_offset = rest.index { |line| line.start_with?("## ") }
    section = end_offset ? rest[0...end_offset] : rest
    section.reject { |line| line.lstrip.start_with?(">") }.join.strip
  end
end

def parse_options(argv)
  options = {
    profiles: [],
    docs: [],
    output: DEFAULT_OUTPUT,
    all: false,
    compact: false,
    index: false,
    index_base: RULES_REPOSITORY_URL,
    dry_run: false,
    force: false,
    list: false,
    catalog_json: false,
    fragment: false
  }

  parser = OptionParser.new do |opts|
    opts.banner = "用法：ruby scripts/generate_claude_md.rb [options]"

    opts.on("-p", "--profile NAME", "按项目画像选择文档，可重复。可选：#{PROFILES.keys.join(", ")}") do |value|
      options[:profiles] << value
    end

    opts.on("-d", "--docs LIST", "指定文档 key，逗号分隔。可选：#{DOCS.map(&:key).join(", ")}") do |value|
      options[:docs].concat(value.split(",").map(&:strip))
    end

    opts.on("-o", "--output PATH", "输出文件，默认 #{DEFAULT_OUTPUT}") do |value|
      options[:output] = value
    end

    opts.on("--all", "整合全部文档") do
      options[:all] = true
    end

    opts.on("--compact", "只整合各文档的「硬约束」小节，输出精简版（离线/内嵌场景）；对外发布的 CLAUDE.md 请用 --index") do
      options[:compact] = true
    end

    opts.on("--index", "只生成按需读取的规则索引，不内嵌主题正文（推荐用作全局 AGENTS.md）") do
      options[:index] = true
    end

    opts.on("--index-base BASE", "设置 --index 的规则链接根路径，默认指向 GitHub 主分支") do |value|
      options[:index_base] = value
    end

    opts.on("--dry-run", "只输出到终端，不写文件") do
      options[:dry_run] = true
    end

    opts.on("-f", "--force", "允许覆盖已有输出文件") do
      options[:force] = true
    end

    opts.on("--list", "列出可用项目画像和文档") do
      options[:list] = true
    end

    opts.on("--catalog-json", "以 JSON 输出规则文档与项目画像目录，供校验工具使用") do
      options[:catalog_json] = true
    end

    opts.on("--fragment", "仅输出规则正文片段，供 AGENTS.md 等模板嵌入") do
      options[:fragment] = true
    end

    opts.on("-h", "--help", "显示帮助") do
      puts opts
      exit 0
    end
  end

  parser.parse!(argv)
  abort("--compact 与 --index 不能同时使用。") if options[:compact] && options[:index]
  options
rescue OptionParser::ParseError => e
  warn e.message
  warn parser
  exit 1
end

def print_catalog
  puts "项目画像："
  PROFILES.each do |key, profile|
    puts "- #{key}: #{profile[:name]}（#{profile[:docs].join(", ")}）"
  end
  puts
  puts "规则文档："
  DOCS.each do |doc|
    puts "- #{doc.key}: #{doc.file} - #{doc.summary}"
  end
end

def print_catalog_json
  puts JSON.generate(
    docs: DOCS.map { |doc| { key: doc.key, file: doc.file, tags: doc.tags } },
    profiles: PROFILES.transform_values { |profile| { docs: profile.fetch(:docs) } }
  )
end

def output_path(path)
  File.expand_path(path, ROOT)
end

def write_output(path, content, force)
  if File.exist?(path) && !force
    abort("输出文件已存在：#{path}。如需覆盖，请加 --force。")
  end

  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, "#{content}\n", encoding: "UTF-8")
end

options = parse_options(ARGV)

if options[:list]
  print_catalog
  exit 0
end

if options[:catalog_json]
  print_catalog_json
  exit 0
end

docs = RuleSelector.new(options).selected_docs
content = RulesBundleBuilder.new(docs, options).build

if options[:dry_run]
  puts content
else
  target = output_path(options[:output])
  write_output(target, content, options[:force])
  puts "已生成：#{target}"
  puts "整合文档：#{docs.map(&:file).join(", ")}"
end
