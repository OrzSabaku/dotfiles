# frozen_string_literal: true

# TODO: Support cross-platform functionality

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

    link_from = File.join(root, entry["source"])
    link_to = File.join(home, entry["path"])

    abort "Symlinked parent of: #{link_to}" if symlink_in_parent?(link_to, home)
    abort "source is symbolic link: #{link_from}" if File.symlink? link_from
    abort "source for the link does not exist: #{link_from}" unless File.file? link_from
    abort "source is outside the repo #{link_from}" unless File.realpath(link_from).start_with?(File.join(root, "/"))

    support = determine_status(link_to, link_from)
    status_link_to = inspect_path(link_to)

    {
      link_from: link_from,
      link_to: link_to,
      support: support,
      status_link_to: status_link_to
    }
  end
end

# @param plan [Array<Hash{Symbol => Object}>]
# @param home [String]
# @return [void]
def print_plan(plan, home)
  plan.each do |record|
    support = record[:support].to_s.ljust(8)
    link_from = abbreviate_home(record[:link_from].to_s, home)
    link_to = abbreviate_home(record[:link_to].to_s, home)
    puts "#{support} #{link_from} -> #{link_to}"
  end
end

# @param path [String]
# @param home [String]
# @return [String]
def abbreviate_home(path, home)
  # TODO: 流石に実装がダサすぎるのでpathnameのサポート開始次第書き換える
  return "~" if path == home
  return path unless path.start_with?("#{home}/")

  path.sub(home, "~")
end

# @param path [String]
# @param home [String]
# @return [Boolean]
def symlink_in_parent?(link_to, home)
  parent = File.dirname(link_to)
  loop do
    break if parent == home || parent == "/"
    return true if File.symlink?(parent)

    parent = File.dirname(parent)
  end
  false
end

Status = Data.define(
  # @param ftype [String]
  :ftype,
  # @param content_hash [String, nil]
  :content_hash,
  # @param permission [Integer, nil]
  :permission,
  # @param link_to [String, nil]
  :link_to
)

# @param link_to [String]
# @param link_from [String]
# @return [void]
def determine_status(link_to, link_from)
  case inspect_path(link_to)
  in ftype: "link"
    target_file = File.expand_path(File.readlink(link_to), File.dirname(link_to))
    link_from == target_file ? :LINKED : :CONFLICT
  in ftype: "file", content_hash:, permission:
    original_status = inspect_path(link_from)
    is_same_content = original_status.content_hash == content_hash
    is_same_mode = original_status.permission == permission

    is_same_content && is_same_mode ? :SAME : :CONFLICT
  in ftype: "missing"
    :MISSING
  else
    :OTHER
  end
end

# @param path [String]
# @return [Status]
def inspect_path(path)
  stat = begin
    File.lstat(path)
  rescue Errno::ENOENT
    nil
  end

  permission = stat.mode & 0o777 if stat&.file?
  content_hash = Digest::SHA256.hexdigest(File.binread(path)) if stat&.file?
  link_to = File.readlink(path) if stat&.symlink?

  Status.new(
    ftype: stat ? stat.ftype : "missing",
    content_hash: content_hash,
    permission: permission,
    link_to: link_to,
  )
end

main if __FILE__ == $PROGRAM_NAME

__END__

if __FILE__ == $PROGRAM_NAME
  to = "/home/sabaku/.zshrc"
  from = "/home/sabaku/dotfiles/omarchy/.zshrc"
  puts determine_status(to, from)

end
