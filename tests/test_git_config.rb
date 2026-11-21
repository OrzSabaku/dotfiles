# frozen_string_literal: true

require_relative "test_helper"

class GitConfigTest < RepositoryTest
  def git_config(*arguments)
    checked_command("git", "config", "--file", (REPO / "home/dot_config/git/config").to_s,
      "--no-includes", *arguments).strip
  end

  def test_public_config_enables_signing_without_identity_or_key
    keys = git_config("--name-only", "--list").downcase.lines(chomp: true)

    assert_empty keys & %w[user.name user.email user.signingkey]
    refute keys.any? { |key| key.start_with?("credential.") }
    assert_equal "true", git_config("--get", "commit.gpgsign")
    assert_equal "ssh", git_config("--get", "gpg.format")
    assert_equal "true", git_config("--get", "user.useconfigonly")
    assert_equal "~/.config/git/config.private", git_config("--get", "include.path")
  end

  def test_private_files_are_ignored
    names = %w[home/dot_config/git/config.private home/dot_config/git/allowed_signers
      home/dot_git-credentials home/dot_ssh/id_ed25519 home/dot_ssh/private_id_ed25519
      home/dot_config/mozc/user_dictionary.db home/dot_config/fcitx5/config.bak
      home/dot_config/fcitx5/conf/cached_layouts home/dot_codex/private_auth.json
      home/dot_config/private_amp/private_secrets.json home/dot_config/private_gh/private_hosts.yml
      home/dot_config/opencode/private_auth.json home/dot_pi/agent/private_auth.json]
    result = checked_command("git", "check-ignore", "--no-index", "--stdin", input: names.join("\n") + "\n")

    assert_equal names.sort, result.lines(chomp: true).sort
  end
end
