# frozen_string_literal: true

require_relative "test_helper"

class ZshAliasPluginsTest < RepositoryTest
  def setup
    super
    skip "Zsh and Sheldon are required" unless resolve_command("zsh") && SHELDON
  end

  def test_real_sheldon_template_preserves_upstream_aliases
    fixture = @root / "plugin"
    sources = {
      "plugins/globalias/globalias.plugin.zsh" => "globalias() { :; }\n",
      "lib/clipboard.zsh" => "clipcopy() { :; }\n",
      "lib/git.zsh" => "git_current_branch() { print main; }\ngit_main_branch() { print main; }\n",
      "plugins/git/git.plugin.zsh" => <<~'ZSH',
        alias gcm='git checkout $(git_main_branch)'
        alias gcmsg='git commit --message'
        alias gwip='git commit --no-gpg-sign'
        alias unsafe='git -c commit.gpgsign=false commit'
      ZSH
      "plugins/docker/docker.plugin.zsh" => "alias dps='docker ps'\n",
      "plugins/docker-compose/docker-compose.plugin.zsh" => "alias dcupd='docker compose up -d'\n"
    }
    sources.each { |name, content| write(fixture / name, content) }
    helper = REPO / "home/dot_config/sheldon/omz-aliases.zsh"
    write(@home / ".config/sheldon/omz-aliases.zsh", helper.read)
    # 実際のTOMLをSheldon自身で解釈する。取得先だけをローカルのフィクスチャへ置き換える。
    configuration = (REPO / "home/dot_config/sheldon/plugins.toml").read.split("[plugins.", 2).first
    configuration += <<~TOML
      [plugins.fixture]
      local = #{fixture.to_s.to_json}
      use = ["plugins/git/git.plugin.zsh"]
      apply = ["omz-aliases"]
    TOML
    config = write(@root / "config/plugins.toml", configuration)
    rendered = checked_command(SHELDON, "--config-dir", config.dirname.to_s,
      "--data-dir", (@root / "data").to_s, "source")
    generated = write(@root / "generated.zsh", rendered.stdout)
    tool("docker", "exit 0\n")
    checked_command("zsh", "-f", "-c", <<~'ZSH', "test", generated.to_s)
      alias gcm='git commit -m'
      alias gcad='git commit -a --amend'
      source "$1"
      zmodload zsh/parameter
      [[ $aliases[gcm] == 'git checkout $(git_main_branch)' ]] || exit 1
      [[ $aliases[gcmsg] == 'git commit --message' ]] || exit 2
      (( ! ${+aliases[gcad]} )) || exit 3
      [[ $aliases[gwip] == 'git commit --no-gpg-sign' ]] || exit 6
      [[ $aliases[unsafe] == 'git -c commit.gpgsign=false commit' ]] || exit 7
      [[ $aliases[dps] == 'docker ps' && $aliases[dcupd] == 'docker compose up -d' ]] || exit 4
      (( ${+functions[git_current_branch]} && ${+functions[clipcopy]} && ${+functions[globalias]} )) || exit 5
    ZSH
  end

  def test_completion_checks_accept_upstream_function_names
    checker = (REPO / "scripts/check-zsh-plugins.zsh").read
    preflight = checker.split("zmodload zsh/parameter", 2).first
    source = write(@root / "plugins.zsh", <<~'ZSH')
      compdef() { :; }
      fzf-tab-complete() { :; }
      globalias() { :; }
      _zsh_highlight() { :; }
      typeset -g FAST_HIGHLIGHT_VERSION=1.55
      fzf-history-widget() { :; }
      zle -N fzf-history-widget
      fpath+=(/fixture/zsh-completions/src)
    ZSH
    env = @env.merge("ZDOTDIR" => @root.to_s)
    command = ["zsh", "-f", "-i", "-c", preflight, "test", source.to_s, @root.to_s]
    checked_command(*command, env: env)
    source.write(source.read.sub("fzf-tab-complete() { :; }", ""))
    result = run_command(*command, env: env)
    refute_equal 0, result.exit_code
    assert_includes result.stderr, "Missing plugin function: fzf-tab-complete"
  end

  def assert_failed_update_preserves_cache(body)
    tool("sheldon", body)
    cache = write(@root / "cache/dotfiles/sheldon.zsh", "# working configuration\n")
    result = run_script("update-zsh-plugins")
    refute_equal 0, result.exit_code
    assert_equal "# working configuration\n", cache.read
  end

  def test_update_uses_isolated_generation
    assert_failed_update_preserves_cache(<<~'STUB')
      index = ARGV.index("--data-dir")
      exit 23 if index && ARGV.fetch(index + 1).include?("generation.")
      File.write(File.join(ENV.fetch("XDG_CACHE_HOME"), "dotfiles/sheldon.zsh"), "damaged")
      exit 24
    STUB
  end

  def test_failed_download_keeps_last_working_plugins
    assert_failed_update_preserves_cache("exit 23\n")
  end

  def test_invalid_generated_code_keeps_last_working_plugins
    assert_failed_update_preserves_cache("puts ')'\n")
  end
end
