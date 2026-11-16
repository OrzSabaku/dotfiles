# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |task|
  task.libs << "tests"
  task.pattern = "tests/test_*.rb"
end

task default: :test

SCRIPTS = %w[setup-zsh update-zsh-plugins nvim-experiment].freeze
REPOSITORY = File.expand_path(__dir__)
BUILD_DIRECTORY = File.join(REPOSITORY, "build")

desc "Compile the command scripts with Spinel (optional, no installation)"
task :aot do
  mkdir_p BUILD_DIRECTORY
  SCRIPTS.each do |name|
    # __dir__で参照するリポジトリの位置を確定させるため、絶対パスでコンパイルする。
    sh "spinel", File.join(REPOSITORY, "scripts", "#{name}.rb"), "--strict-require",
      "-o", File.join(BUILD_DIRECTORY, name)
  end
end

desc "Run the same fixtures against the compiled commands"
task "test:aot" => :aot do
  sh({ "SCRIPT_BIN_DIR" => BUILD_DIRECTORY }, RbConfig.ruby, "-Itests", "-e",
    'Dir["tests/test_*.rb"].sort.each { |file| require_relative file }')
end
