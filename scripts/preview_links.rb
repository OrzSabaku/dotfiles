# frozen_string_literal: true

require 'json'

def main
  root = File.expand_path('..', __dir__)
  files_json = File.join(root, 'omarchy/files.json')
  abort "#{files_json} does not exist" unless File.file? files_json
  manifest = JSON.parse(File.read(files_json))

  abort 'the version must be 1' unless manifest['version'] == 1

  mappings = []
  manifest['files'].each do |entry|
    source = File.join(root, entry['source'])
    path = File.join(Dir.home, entry['path'])

    abort "the source file for the link does not exist: #{source}" unless File.file? source

    mappings << "#{abbreviate_home(source)} -> #{abbreviate_home(path)}"
  end

  puts mappings
end

def abbreviate_home(path) = path.gsub(Dir.home, '~')

main if __FILE__ == $PROGRAM_NAME
