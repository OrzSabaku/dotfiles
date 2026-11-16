# frozen_string_literal: true

require "open3"
require "shellwords"

# シェル文字列を組み立てず、コマンドと引数を分けて実行する。
module ScriptCommands
  class CommandFailed < StandardError
    attr_reader :exit_code

    def initialize(arguments, status)
      @exit_code = status.exitstatus || 128 + status.termsig
      super("Command failed (#{exit_code}): #{arguments.reject { |argument| argument.is_a?(Hash) }.shelljoin}")
    end
  end

  def self.run!(*arguments, **options)
    environment, command, command_args = split_arguments(arguments)
    return if system(environment, [command, command], *command_args, **options, exception: false)

    raise CommandFailed.new(arguments, $?)
  end

  def self.capture!(*arguments, input: "")
    environment, command, command_args = split_arguments(arguments)
    stdout, stderr, status = Open3.capture3(environment, [command, command], *command_args, stdin_data: input)
    warn stderr unless stderr.empty?
    raise CommandFailed.new(arguments, status) unless status.success?

    stdout
  end

  def self.split_arguments(arguments)
    command_arguments = arguments.dup
    environment = command_arguments.first.is_a?(Hash) ? command_arguments.shift : {}
    command, *command_args = command_arguments
    [environment, command, command_args]
  end
  private_class_method :split_arguments

  def self.main
    yield
  rescue CommandFailed => error
    warn error.message
    exit error.exit_code
  rescue SystemCallError, RuntimeError => error
    warn error.message
    exit 1
  rescue Interrupt
    exit 130
  end
end
