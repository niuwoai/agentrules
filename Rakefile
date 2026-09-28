# frozen_string_literal: true

# Alma 规则库的本地验证入口。
#
# 用法：
#   rake test   # 运行规则校验，报告只打印到 stdout
#   rake        # 默认任务，等同 rake test
#
# test 通过 --no-report 调用校验脚本：报告写到 stdout，不生成 tmp/rule-verification.*，
# 运行前后工作区保持不变。校验失败时任务以非零退出码结束，便于本地和 CI 直接判定。

require "rbconfig"

VERIFY_SCRIPT = File.expand_path("scripts/verify_rules.rb", __dir__)

desc "运行规则校验（ruby scripts/verify_rules.rb --no-report）"
task :test do
  sh RbConfig.ruby, VERIFY_SCRIPT, "--no-report", verbose: false
end

task default: :test
