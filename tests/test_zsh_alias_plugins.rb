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
    # 実際のTOMLをSheldon自身で解釈する．取得先だけをローカルのフィクスチャへ置き換える．
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
    generated = write(@root / "generated.zsh", rendered)
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

  def test_generated_completions_are_registered_before_initialization
    # 実際の登録順を検証し，ネットワークや各CLIの実装には依存しない．
    tool("herdr", <<~'STUB')
      puts <<~'ZSH'
        #compdef herdr
        _herdr() { print -r -- 'herdr candidate'; }
        if [[ $funcstack[1] == _herdr ]]; then _herdr "$@"; fi
      ZSH
    STUB
    tool("lazygit", <<~'STUB')
      puts <<~'ZSH'
        #compdef lazygit
        _lazygit() { print -r -- 'lazygit candidate'; }
        compdef _lazygit lazygit
      ZSH
    STUB
    generated = @root / "generated completions"
    generated.mkpath
    generator = REPO / "home/dot_config/sheldon/generate-completions.zsh"
    # 導入していないCLIは省略できることも，この隔離したPATHで確認する．
    File.symlink(resolve_command("zsh"), @tools / "zsh")
    env = @env.merge("PATH" => @tools.to_s)
    checked_command("/usr/bin/zsh", generator.to_s, generated.to_s, env: env)

    assert_predicate (generated / "_herdr"), :file?
    refute_predicate (generated / "_gh"), :exist?

    fixture = write(@root / "plugin/src/_fixture", "#compdef fixture\n_arguments '*:file:_files'\n")
    configuration = (REPO / "home/dot_config/sheldon/plugins.toml").read.split("[plugins.zoxide]", 2).first
      .sub('github = "zsh-users/zsh-completions"', "local = #{fixture.dirname.dirname.to_s.to_json}")
    config = write(@root / "config/plugins.toml", configuration)
    write(@home / ".config/sheldon/completion-init.zsh",
      (REPO / "home/dot_config/sheldon/completion-init.zsh").read)
    rendered = checked_command(SHELDON, "--config-dir", config.dirname.to_s,
      "--data-dir", (@root / "data").to_s, "source")
    source = write(@root / "plugins.zsh", rendered)
    env = @env.merge("DOTFILES_ZSH_COMPLETIONS" => generated.to_s, "PATH" => "/usr/bin:/bin")
    # compinitの権限確認への応答は，この仮ホームの検証内だけで指定する．
    checked_pty_command("zsh", "-f", "-i", "-c", <<~'ZSH', "test", source.to_s, env: env, input: "y\n")
      [[ -t 0 && -t 1 && -t 2 ]] || exit 7
      original_fpath=("${fpath[@]}")
      autoload -Uz compaudit
      insecure_fpath=("${(@f)$(compaudit 2>/dev/null)}")
      # 実際のzsh.zshと同じく，匿名関数内でキャッシュを評価する．
      () {
        local plugin_source=$(<"$1")
        eval "$plugin_source"
        for directory in "${original_fpath[@]}"; do
          # compinitが安全でない検索先を除外するのは正しい動作．
          (( ${insecure_fpath[(Ie)$directory]} )) && continue
          (( ${fpath[(Ie)$directory]} )) || exit 3
        done
        autoload -Uz is-at-least
        is-at-least 5.0 || exit 4
      } "$1"
      [[ $_comps[herdr] == _herdr && $_comps[fixture] == _fixture ]] || exit 1
      [[ $(_herdr) == 'herdr candidate' ]] || exit 2
      [[ $_comps[lazygit] == _lazygit ]] || exit 5
      [[ $(_lazygit) == 'lazygit candidate' ]] || exit 6
    ZSH
  end

  def test_failed_completion_generation_keeps_previous_plugins_and_completions
    previous = write(@root / "data/dotfiles/sheldon/active/completions/_herdr", "# working completion\n")
    tool("zsh", "exit 23\n")

    assert_failed_update_preserves_cache("abort 'must not fetch after generation failure'\n")
    assert_equal "# working completion\n", previous.read
    assert_equal [previous.dirname.dirname], previous.dirname.dirname.parent.children
  end

  def test_generator_rejects_failed_empty_or_invalid_completion_output
    generator = REPO / "home/dot_config/sheldon/generate-completions.zsh"
    destination = @root / "completions"
    destination.mkpath
    File.symlink(resolve_command("zsh"), @tools / "zsh")
    env = @env.merge("PATH" => @tools.to_s)
    ["exit 23\n", "exit 0\n", "puts ')'\n"].each do |body|
      tool("herdr", body)
      _, _, status = Open3.capture3(env, "/usr/bin/zsh", generator.to_s, destination.to_s)

      refute_predicate status, :success?, body
    end
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
    _, stderr, status = Open3.capture3(env, *command)

    refute_predicate status, :success?
    assert_includes stderr, "Missing plugin function: fzf-tab-complete"
  end

  def assert_failed_update_preserves_cache(body)
    tool("sheldon", body)
    cache = write(@root / "cache/dotfiles/sheldon.zsh", "# working configuration\n")
    _, stderr, status = run_script("update-zsh-plugins")

    refute_predicate status, :success?, stderr
    assert_equal "# working configuration\n", cache.read
  end

  def test_update_uses_isolated_generation
    # 取得処理が取得先を掃除しても，稼働中のプラグインを壊さないこと．
    state = write(@root / "data/dotfiles/sheldon/active/plugin-state", "working plugins")

    assert_failed_update_preserves_cache(<<~'STUB')
      location = ARGV.fetch(ARGV.index("--data-dir") + 1)
      Dir.glob(File.join(location, "**/plugin-state")).each { |path| File.write(path, "damaged") }
      exit 23
    STUB
    assert_equal "working plugins", state.read
  end

  def test_failed_download_keeps_last_working_plugins
    assert_failed_update_preserves_cache("exit 23\n")
  end

  def test_invalid_generated_code_keeps_last_working_plugins
    assert_failed_update_preserves_cache("puts ')'\n")
  end
end
