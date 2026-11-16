#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "tempfile"
require "tmpdir"
require_relative "lib/commands"

class ZshPluginUpdate
  REPO = File.expand_path("..", __dir__)

  def run
    generations = File.join(xdg_directory("XDG_DATA_HOME", ".local/share"), "dotfiles/sheldon")
    FileUtils.mkdir_p(generations)
    generation = Dir.mktmpdir("generation.", generations)
    activated = false

    begin
      Dir.mktmpdir("zsh-plugins.") do |work|
        source = File.join(work, "sheldon.zsh")
        fetch_plugins(generation, source)
        validate_plugins(work, source)
        activate_plugins(source)
        activated = true
      end
    ensure
      # Sheldonは未使用の取得先を削除するため、現在のキャッシュとは別の世代で検証する。
      # 成功した世代はキャッシュから参照されるので残し、失敗した世代だけ削除する。
      FileUtils.remove_entry(generation) unless activated
    end
    puts "Validated Zsh plugins activated. Open a new terminal."
  end

  private

  def xdg_directory(variable, fallback)
    value = ENV[variable]
    value.nil? || value.empty? ? File.join(Dir.home, fallback) : value
  end

  def fetch_plugins(generation, source)
    File.open(source, "w") do |output|
      ScriptCommands.run!("sheldon", "--non-interactive", "--data-dir", generation,
        "source", "--relock", out: output)
    end
  end

  def validate_plugins(work, source)
    ScriptCommands.run!("zsh", "-n", source)
    checker = File.join(REPO, "scripts/check-zsh-plugins.zsh")
    ScriptCommands.run!({ "ZDOTDIR" => work }, "zsh", "-f", "-i", checker, source, work)
  end

  def activate_plugins(source)
    cache = File.join(xdg_directory("XDG_CACHE_HOME", ".cache"), "dotfiles")
    FileUtils.mkdir_p(cache)
    current = File.join(cache, "sheldon.zsh")
    backup_cache(current) if File.file?(current)

    # 同じディレクトリでrenameし、新しい端末が書き込み途中のキャッシュを読まないようにする。
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

ScriptCommands.main { ZshPluginUpdate.new.run } if $PROGRAM_NAME == __FILE__
