# frozen_string_literal: true

require "json"

# JSONCの空白・コメントは触らず、指定されたキーの値だけを置き換える。
# 字句の位置を記録し、構文の検証自体は標準のJSONパーサーに任せる。
class JsoncPreferences
  Token = Struct.new(:text, :start, :finish)
  Node = Struct.new(:first, :last, :members)
  TOKEN = %r{"(?:\\.|[^"\\])*"|//[^\r\n]*|/\*.*?\*/|\s+|[{}\[\]:,]|true|false|null|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?}m

  def initialize(text)
    @text = (text.empty? ? "{}\n" : text).dup
  end

  def set(path, value)
    tokens = tokenize
    # JSONCで許されるコメントと末尾カンマだけを除いて検証する。
    json = tokens.each_with_index.filter_map do |token, index|
      token.text unless token.text == "," && ["}", "]"].include?(tokens[index + 1]&.text)
    end.join
    data = JSON.parse(json)
    @tokens = tokens
    @index = 0
    root = parse_value
    update(root, path, value) unless data.dig(*path) == value
    self
  end

  def to_s
    @text
  end

  private

  def tokenize
    tokens = []
    offset = 0
    @text.scan(TOKEN) do |raw|
      match = Regexp.last_match
      raise ArgumentError, "Invalid JSONC token" unless match.begin(0) == offset

      offset = match.end(0)
      next if raw.match?(%r{\A(?:\s|//|/\*)})

      tokens << Token.new(raw, match.begin(0), offset)
    end
    raise ArgumentError, "Invalid JSONC token" unless offset == @text.length

    tokens
  end

  def parse_value
    first = @tokens.fetch(@index)
    @index += 1
    members = nil
    case first.text
    when "{"
      members = {}
      until @tokens.fetch(@index).text == "}"
        key = JSON.parse(@tokens.fetch(@index).text)
        raise ArgumentError, "Duplicate JSONC key: #{key}" if members.key?(key)

        @index += 2 # キーとコロン。構文はJSON.parseで検証済み。
        members[key] = parse_value
        @index += 1 if @tokens.fetch(@index).text == ","
      end
      @index += 1
    when "["
      until @tokens.fetch(@index).text == "]"
        parse_value
        @index += 1 if @tokens.fetch(@index).text == ","
      end
      @index += 1
    end
    Node.new(first, @tokens.fetch(@index - 1), members)
  end

  def update(node, path, value)
    raise ArgumentError, "Expected a JSONC object" unless node.members

    key, *rest = path
    child = node.members[key]
    if child && !rest.empty?
      update(child, rest, value)
    elsif child
      original = @text[child.first.start...child.last.finish]
      # 配列など値の内部にあるコメントも、置換する値の直前に残す。
      comments = original.scan(TOKEN).select { |raw| raw.start_with?("//", "/*") }
      replacement = comments.map { |comment| "#{comment}\n" }.join + JSON.generate(value)
      @text[child.first.start...child.last.finish] = replacement
    else
      nested = rest.reverse_each.reduce(value) { |result, name| { name => result } }
      # コメントの後ろに追記し、最終値の直後にだけ区切りを加える。
      closing = node.last.start
      previous = @tokens[@tokens.index(node.last) - 1]
      @text.insert(closing, "\n#{JSON.generate(key)}: #{JSON.generate(nested)}\n")
      last_value = node.members.values.last
      @text.insert(last_value.last.finish, ",") if last_value && previous.text != ","
    end
  end
end
