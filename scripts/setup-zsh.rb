#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "shellwords"
require_relative "lib/commands"

# 通常のユーザー端末で実行する。sudo/chshの入力は端末に引き継ぐ。
class ZshSetup
  REPO = File.expand_path("..", __dir__)
  DEPENDENCIES = %w[zsh sheldon starship mise fzf zoxide eza bat chezmoi].freeze

  def run
    check_environment
    previous_shell = login_shell

    # 導入・適用・起動確認がすべて成功するまでログインシェルを変更しない。
    ScriptCommands.run!("omarchy", "pkg", "add", "zsh", "sheldon")
    zsh = check_dependencies
    apply_configuration
    ScriptCommands.run!(File.join(REPO, "scripts/update-zsh-plugins.rb"))
    check_startup

    save_previous_shell(previous_shell)
    change_login_shell(zsh, previous_shell)
    puts "Default shell: #{zsh}"
    puts "Open a new terminal; log out and back in if necessary."
    puts "To return to the previous login shell: chsh -s #{previous_shell.shellescape}"
  end

  private

  def check_environment
    raise "Run this script as your normal desktop user, without sudo." if Process.euid.zero?
    raise "This setup is for Omarchy." unless File.readlines("/etc/os-release", chomp: true).include?("ID=omarchy")
  end

  def login_shell
    username = ScriptCommands.capture!("id", "-un").strip
    entry = ScriptCommands.capture!("getent", "passwd", username).strip
    shell = entry.split(":", -1)[6]
    raise "Could not determine the current login shell." if shell.nil? || shell.empty?

    shell
  end

  def executable(name)
    ENV.fetch("PATH").split(File::PATH_SEPARATOR).map { |directory| File.join(directory, name) }
      .find { |path| File.file?(path) && File.executable?(path) }
  end

  def check_dependencies
    DEPENDENCIES.each do |name|
      raise "Missing dependency: #{name}" unless executable(name)
    end
    zsh = executable("zsh")
    unless File.readlines("/etc/shells", chomp: true).include?(zsh)
      raise "The installed shell is not registered in /etc/shells: #{zsh}"
    end

    zsh
  end

  def chezmoi(*arguments)
    ["chezmoi", "--source", REPO, *arguments]
  end

  def apply_configuration
    ScriptCommands.run!(*chezmoi("init"))
    profile = ScriptCommands.capture!(*chezmoi("execute-template", "{{ .profile }}")).strip
    raise "Select the omarchy environment in chezmoi init." unless profile == "omarchy"
    zsh_enabled = ScriptCommands.capture!(*chezmoi("execute-template", "{{ .apps.zsh }}")).strip
    raise "Enable apps.zsh in the chezmoi config first." unless zsh_enabled == "true"

    %w[.zshenv .zshrc .config/dotfiles/zsh.zsh].each do |name|
      content = ScriptCommands.capture!(*chezmoi("cat", File.join(Dir.home, name)))
      ScriptCommands.capture!("zsh", "-n", input: content)
    end
    ScriptCommands.run!(*chezmoi("diff"))
    ScriptCommands.run!(*chezmoi("apply"))
  end

  def check_startup
    ScriptCommands.run!("zsh", "-lic", <<~'ZSH')
      [[ -o interactive && $EDITOR == nvim && -n $OMARCHY_PATH ]] || exit 1
      whence -p mise starship fzf zoxide sheldon eza bat >/dev/null || exit 1
      print -r -- "Zsh startup OK"
    ZSH
  end

  def save_previous_shell(shell)
    directory = File.join(Dir.home, ".local/state/dotfiles")
    FileUtils.mkdir_p(directory)
    path = File.join(directory, "shell-before-zsh-#{Time.now.strftime('%Y%m%d-%H%M%S')}.txt")
    File.write(path, "#{shell}\n", perm: 0o600)
  end

  def change_login_shell(zsh, previous_shell)
    ScriptCommands.run!("chsh", "-s", zsh) unless previous_shell == zsh
    raise "Login shell change was not applied." unless login_shell == zsh
  end
end

ScriptCommands.main { ZshSetup.new.run } if $PROGRAM_NAME == __FILE__
