# frozen_string_literal: true

require 'json'

def main
  root = File.expand_path('..', __dir__)
  files_json = File.join(root, 'omarchy/files.json')
  abort "#{files_json} does not exist" unless File.file? files_json
  manifest = JSON.parse(File.read(files_json))

  abort 'the version must be 1' unless manifest['version'] == 1

  mappings = []
  has_conflict = false
  manifest['files'].each do |entry|
    source = File.join(root, entry['source'])
    path = File.join(Dir.home, entry['path'])

    abort "the source file for the link does not exist: #{source}" unless File.file? source

    file_type = determine_file_type(path, source)
    has_conflict = true if %i[CONFLICT OTHER].include?(file_type)
    mappings << "#{file_type.to_s.ljust(8)} #{abbreviate_home(source)} -> #{abbreviate_home(path)}"
  end

  puts mappings
  exit 1 if has_conflict
end

def abbreviate_home(path) = path.gsub(Dir.home, '~')

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
    is_same_content ? :SAME : :CONFLICT
  elsif File.exist?(path)
    :OTHER
  else
    :MISSING
  end
end

main if __FILE__ == $PROGRAM_NAME
