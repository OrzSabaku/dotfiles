# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |task|
  task.libs << "tests"
  task.pattern = "tests/test_*.rb"
end

task default: :test
