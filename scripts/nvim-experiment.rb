#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"

# 設定・データ・状態・キャッシュを分ける。ホストのファイルアクセスは隔離しない。
begin
  repo, status = Open3.capture2("chezmoi", "execute-template", "{{ .chezmoi.workingTree }}")
  exit(status.exitstatus || 128 + status.termsig) unless status.success?
  ENV["XDG_CONFIG_HOME"] = File.join(repo.strip, "experiments")
  ENV["NVIM_APPNAME"] = "nvim-experiment"
  exec("nvim", *ARGV)
rescue SystemCallError => error
  warn error.message
  exit(error.is_a?(Errno::ENOENT) ? 127 : 126)
end
