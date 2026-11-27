#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "shellwords"
require "open3"

# 通常のユーザー端末で実行する．sudo/chshの入力は端末に引き継ぐ．
class ZshSetup
  DEPENDENCIES = %w[zsh sheldon starship mise fzf zoxide eza bat chezmoi].freeze

  def run
    check_environment
    previous_shell = login_shell

    # 導入・適用・起動確認がすべて成功するまでログインシェルを変更しない．
    system("omarchy", "pkg", "add", "zsh", "sheldon", exception: true)
    zsh = check_dependencies
    apply_configuration
    updater = if RUBY_ENGINE == "spinel"
      File.join(File.dirname(File.realpath("/proc/self/exe")), "update-zsh-plugins")
    else
      File.join(@repo, "scripts/update-zsh-plugins.rb")
    end
    system([updater, updater], exception: true)
    check_startup

    save_previous_shell(previous_shell)
    change_login_shell(zsh, previous_shell)
    puts "Default shell: #{zsh}"
    puts "Open a new terminal; log out and back in if necessary."
    puts "To return to the previous login shell: chsh -s #{previous_shell.shellescape}"
  rescue SystemCallError, RuntimeError => error
    warn error.message
    status = $?
    exit 1 if status.nil? || status.success?
    exit(status.exitstatus || 128 + status.termsig)
  rescue Interrupt
    exit 130
  end

  private

  def check_environment
    raise "Run this script as your normal desktop user, without sudo." if Process.euid.zero?
    raise "This setup is for Omarchy." unless File.readlines("/etc/os-release", chomp: true).include?("ID=omarchy")
  end

  def login_shell
    username, status = Open3.capture2("id", "-un")
    exit(status.exitstatus || 128 + status.termsig) unless status.success?
    entry, status = Open3.capture2("getent", "passwd", username.strip)
    exit(status.exitstatus || 128 + status.termsig) unless status.success?
    shell = entry.strip.split(":", -1)[6]
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
    ["chezmoi", "--source", @repo, *arguments]
  end

  def apply_configuration
    # CIのソース配置ではなく，利用者がchezmoiで管理するチェックアウトを使う．
    repo, status = Open3.capture2("chezmoi", "execute-template", "{{ .chezmoi.workingTree }}")
    exit(status.exitstatus || 128 + status.termsig) unless status.success?
    @repo = repo.strip
    system(*chezmoi("init"), exception: true)
    profile, status = Open3.capture2(*chezmoi("execute-template", "{{ .profile }}"))
    exit(status.exitstatus || 128 + status.termsig) unless status.success?
    raise "Select the omarchy environment in chezmoi init." unless profile.strip == "omarchy"
    zsh_enabled, status = Open3.capture2(*chezmoi("execute-template", "{{ .apps.zsh }}"))
    exit(status.exitstatus || 128 + status.termsig) unless status.success?
    raise "Enable apps.zsh in the chezmoi config first." unless zsh_enabled.strip == "true"

    %w[.zshenv .zshrc .config/dotfiles/zsh.zsh].each do |name|
      content, status = Open3.capture2(*chezmoi("cat", File.join(Dir.home, name)))
      exit(status.exitstatus || 128 + status.termsig) unless status.success?
      _, status = Open3.capture2("zsh", "-n", stdin_data: content)
      exit(status.exitstatus || 128 + status.termsig) unless status.success?
    end
    system(*chezmoi("diff"), exception: true)
    system(*chezmoi("apply"), exception: true)
  end

  def check_startup
    system("zsh", "-lic", <<~'ZSH', exception: true)
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
    system("chsh", "-s", zsh, exception: true) unless previous_shell == zsh
    raise "Login shell change was not applied." unless login_shell == zsh
  end
end

ZshSetup.new.run if $PROGRAM_NAME == __FILE__
