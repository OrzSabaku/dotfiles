#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "tempfile"
require "tmpdir"
require "open3"
require "shellwords"

class ZshPluginUpdate
  def run
    repo, status = Open3.capture2("chezmoi", "execute-template", "{{ .chezmoi.workingTree }}")
    exit(status.exitstatus || 128 + status.termsig) unless status.success?
    @repo = repo.strip
    generations = File.join(xdg_directory("XDG_DATA_HOME", ".local/share"), "dotfiles/sheldon")
    FileUtils.mkdir_p(generations)
    generation = Dir.mktmpdir("generation.", generations)
    activated = false

    begin
      Dir.mktmpdir("zsh-plugins.") do |work|
        source = File.join(work, "sheldon.zsh")
        generate_completions(generation)
        fetch_plugins(generation, source)
        validate_plugins(work, source)
        activate_plugins(source)
        activated = true
      end
    ensure
      # Sheldonは未使用の取得先を削除するため，現在のキャッシュとは別の世代で検証する．
      # 成功した世代はキャッシュから参照されるので残し，失敗した世代だけ削除する．
      FileUtils.remove_entry(generation) unless activated
    end
    puts "Validated Zsh plugins activated. Open a new terminal."
  rescue SystemCallError, RuntimeError => error
    warn error.message
    status = $?
    exit 1 if status.nil? || status.success?
    exit(status.exitstatus || 128 + status.termsig)
  rescue Interrupt
    exit 130
  end

  private

  def xdg_directory(variable, fallback)
    value = ENV[variable]
    value.nil? || value.empty? ? File.join(Dir.home, fallback) : value
  end

  def fetch_plugins(generation, source)
    File.open(source, "w") do |output|
      output.puts("DOTFILES_ZSH_COMPLETIONS=#{Shellwords.escape(File.join(generation, 'completions'))}")
      output.flush
      system("sheldon", "--non-interactive", "--data-dir", generation,
        "source", "--relock", out: output, exception: true)
    end
  end

  def generate_completions(generation)
    directory = File.join(generation, "completions")
    FileUtils.mkdir_p(directory)
    generator = File.join(@repo, "home/dot_config/sheldon/generate-completions.zsh")
    system("zsh", generator, directory, exception: true)
  end

  def validate_plugins(work, source)
    system("zsh", "-n", source, exception: true)
    checker = File.join(@repo, "scripts/check-zsh-plugins.zsh")
    system({ "ZDOTDIR" => work }, "zsh", "-f", "-i", checker, source, work, exception: true)
  end

  def activate_plugins(source)
    cache = File.join(xdg_directory("XDG_CACHE_HOME", ".cache"), "dotfiles")
    FileUtils.mkdir_p(cache)
    current = File.join(cache, "sheldon.zsh")
    backup_cache(current) if File.file?(current)

    # 同じディレクトリでrenameし，新しい端末が書き込み途中のキャッシュを読まないようにする．
    Tempfile.create([".sheldon.", ".zsh"], cache) do |pending|
      FileUtils.copy_file(source, pending.path)
      File.chmod(0o600, pending.path)
      File.rename(pending.path, current)
    end
  end

  def backup_cache(current)
    backup = File.join(Dir.home, ".local/state/dotfiles/backups",
      "zsh-plugins-#{Time.now.strftime('%Y%m%d-%H%M%S')}")
    FileUtils.mkdir_p(backup, mode: 0o700)
    FileUtils.cp(current, File.join(backup, "sheldon.zsh"))
  end
end

ZshPluginUpdate.new.run if $PROGRAM_NAME == __FILE__
