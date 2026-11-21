# frozen_string_literal: true

require_relative "test_helper"

class GitConfigTest < RepositoryTest
  def git_config(*arguments)
    checked_command("git", "config", "--file", (REPO / "home/dot_config/git/config").to_s,
      "--no-includes", *arguments).strip
  end

  def test_public_config_enables_signing_without_identity_or_key
    git_config("--name-only", "--list").lines(chomp: true).each do |key|
      refute_includes %w[user.name user.email user.signingkey], key.downcase
      refute key.downcase.start_with?("credential.")
    end
    assert_equal "true", git_config("--get", "commit.gpgsign")
    assert_equal "ssh", git_config("--get", "gpg.format")
    assert_equal "true", git_config("--get", "user.useconfigonly")
    assert_equal "~/.config/git/config.private", git_config("--get", "include.path")
  end

  def test_private_files_are_ignored
    %w[home/dot_config/git/config.private home/dot_config/git/allowed_signers
      home/dot_git-credentials home/dot_ssh/id_ed25519].each do |name|
      checked_command("git", "check-ignore", "--no-index", name)
    end
  end
end
