# frozen_string_literal: true

require "json"
require "digest"

# @return [void]
def main
  home = ARGV[0] == "--home" ? File.expand_path(ARGV[1]) : Dir.home

  root = File.expand_path("..", __dir__)

  manifest = load_manifest(root)
  plan = build_plan(root, home, manifest)
  print_plan(plan, home)
  exit 1 if plan.any? { |record| %i[CONFLICT OTHER].include?(record[:status]) }
end

# @param root [String]
# @return [Hash{String => Object}]
def load_manifest(root)
  # @type [String]
  files_json = File.join(root, "omarchy/files.json")
  abort "#{files_json} does not exist" unless File.file?(files_json)

  # @type [Hash{String => Object}]
  manifest = JSON.parse(File.read(files_json))
  abort "the version must be 1" unless manifest["version"] == 1
  manifest
end

# @param root [String]
# @param home [String]
# @param manifest [Hash{String => Object}]
# @return [Array<Hash{Symbol => Object}>]
def build_plan(root, home, manifest)
  # @type [Array<Hash{String => String, Integer}>]
  files = manifest["files"]
  files.map do |entry|
    %w[source path].each do |key|
      is_unsafe_path = entry[key].start_with?("/") || entry[key].split("/").include?("..") || entry[key].empty?
      abort "Unsafe #{key}: #{entry[key].inspect}" if is_unsafe_path
    end

    source = File.join(root, entry["source"])
    path = File.join(home, entry["path"])

    abort "Symlinked parent of: #{path}" if symlink_in_parent?(path, home)
    abort "source is symbolic link: #{source}" if File.symlink? source
    abort "source for the link does not exist: #{source}" unless File.file? source
    abort "source is outside the repo #{source}" unless File.realpath(source).start_with?(File.join(root, "/"))

    file_type = determine_file_type(path, source)
    before = fingerprint(source)

    {
      source: source,
      path: path,
      status: file_type,
      before: before
    }
  end
end

# @param plan [Array<Hash{Symbol => Object}>]
# @param home [String]
# @return [void]
def print_plan(plan, home)
  plan.each do |record|
    status = record[:status].to_s.ljust(8)
    source = abbreviate_home(record[:source].to_s, home)
    path = abbreviate_home(record[:path].to_s, home)
    puts "#{status} #{source} -> #{path}"
  end
end

# @param path [String]
# @param home [String]
# @return [String]
def abbreviate_home(path, home)
  return "~" if path == home
  return path unless path.start_with?("#{home}/")

  path.sub(home, "~")
end

# @param path [String]
# @param home [String]
# @return [Boolean]
def symlink_in_parent?(path, home)
  parent = File.dirname(path)
  loop do
    break if parent == home || parent == "/"
    return true if File.symlink?(parent)

    parent = File.dirname(parent)
  end
  false
end

# @param path [String]
# @return [Integer]
def get_permission(path) = File.stat(path).mode & 0o777

# @param path [String]
# @return [Hash{Symbol => Object}, nil]
def fingerprint(path)
  if File.symlink?(path)
    {
      link: File.readlink(path),
      sha256: Digest::SHA256.hexdigest(File.binread(path))
    }
  elsif File.file?(path)
    {
      sha256: Digest::SHA256.hexdigest(File.binread(path)),
      mode: get_permission(path)
    }

  end
end

# @param path [String]
# @param source [String]
# @return [Symbol]
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

Status = Data.define(
  # @param ftype [String]
  :ftype,
  # @param hash [String]
  :hash,
  # @param permission [Integer]
  :permission,
  # @param link_to [String, nil]
  :link_to
)

# @param path [String]
# @return [void]
def determine_status(path)
  case inspect_path(path)
  in Status(ftype: "file", hash:, permission:, link_to:)
    puts "helo"
  else
    puts "he"
  end
end

# @param path [String]
# @return [Status, nil]
def inspect_path(path)
  return unless File.exist?(path)

  Status.new(
    ftype: File.ftype(path),
    hash: Digest::SHA256.hexdigest(File.binread(path)),
    permission: get_permission(path),
    link_to: File.readlink(path)
  )
end

main if __FILE__ == $PROGRAM_NAME
