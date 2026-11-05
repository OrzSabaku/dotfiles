# frozen_string_literal: true

require "json"

def load_manifest(root)
  files_json = File.join(root, "omarchy/files.json")
  abort "#{files_json} does not exist" unless File.file?(files_json)
  manifest = JSON.parse(File.read(files_json))
  abort "the version must be 1" unless manifest["version"] == 1
  manifest
end

def build_plan(root, manifest)
  mappings = []
  manifest["files"].each do |entry|
    %w[source path].each do |key|
      is_unsafe_path = entry[key].start_with?("/") || entry[key].split("/").include?("..") || entry[key].empty?
      abort "Unsafe #{key}: #{entry[key].inspect}" if is_unsafe_path
    end

    source = File.join(root, entry["source"])
    path = File.join(Dir.home, entry["path"])

    abort "Symlinked parent of: #{path}" if symlink_in_parent?(path)
    abort "source is symbolic link: #{source}" if File.symlink? source
    abort "source for the link does not exist: #{source}" unless File.file? source
    abort "source is outside the repo #{source}" unless File.realpath(source).start_with?(File.join(root, "/"))

    file_type = determine_file_type(path, source)

    mappings <<
      {
        source: source,
        path: path,
        status: file_type
      }
  end

  mappings
end

def print_plan(plan)
  plan.each do |record|
    status = record[:status].to_s.ljust(8)
    source = abbreviate_home(record[:source])
    path = abbreviate_home(record[:path])
    puts "#{status} #{source} -> #{path}"
  end
end

def main
  root = File.expand_path("..", __dir__)
  manifest = load_manifest(root)
  plan = build_plan(root, manifest)
  print_plan(plan)
  exit 1 if plan.any? { |record| %i[CONFLICT OTHER].include?(record[:status]) }
end

def abbreviate_home(path) = path.gsub(Dir.home, "~")

def symlink_in_parent?(path)
  parent = File.dirname(path)
  loop do
    break if parent == Dir.home || parent == "/"
    return true if File.symlink?(parent)

    parent = File.dirname(parent)
  end
  false
end

def get_permission(path) = File.stat(path).mode & 0o777

def determine_file_type(path, source)
  if File.symlink?(path)
    target_file = File.expand_path(File.readlink(path), File.dirname(path))
    target_file == source ? :LINKED : :CONFLICT
  elsif File.file?(path)
    # Q. なぜテキストとして解釈しないのか？
    # A. 処理的には，バイト列として保存されているものをテキストとして解釈していることになる．
    # 1. 単純にオーバーヘッド．バイト列で実現可能ならバイト列でやりたい．
    # バイナリ比較ではCPUが得意とする定長バイト比較コマンドが叩けたり
    # 1Bでも違う箇所を見つけたら早期離脱できたりと比較という用途においてはかなり利点が多い．
    # 2. 処理系は自動的にデータを変換するものもある．改行コード，BOM，末尾の空白など．用途によってはそれも比較したい場合がある．
    # 3. 今回ではあまり関係ないが，バイナリファイルでも読み込める．
    # 4. ただし，このCRubyにおいては実装上当てはまらない箇所も多いのに留意されたい．本来ならFileUtilを使いたいところであるが，Spinelが未対応．
    is_same_content = File.binread(path) == File.binread(source)
    is_same_mode = get_permission(path) == get_permission(source)
    is_same_content && is_same_mode ? :SAME : :CONFLICT
  elsif File.exist?(path)
    :OTHER
  else
    :MISSING
  end
end

main if __FILE__ == $PROGRAM_NAME
