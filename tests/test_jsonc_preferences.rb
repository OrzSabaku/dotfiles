# frozen_string_literal: true

require_relative "test_helper"
require_relative "../home/.chezmoitemplates/shared/jsonc-preferences"

class JsoncPreferencesTest < Minitest::Test
  def test_changes_only_the_requested_value
    original = <<~JSONC
      {
        // "theme": { "name": "disabled" },
        "plugins": ["https://example.com/a,}", /* 保持 */],
        "other": { "name": "dark" },
        "theme": { /* 好み */ "name": "dark", "mode": "system", },
      }
    JSONC
    result = JsoncPreferences.new(original).set(["theme", "name"], "system").to_s
    assert_equal original.sub('"name": "dark", "mode"', '"name": "system", "mode"'), result
    assert_equal result, JsoncPreferences.new(result).set(["theme", "name"], "system").to_s
  end

  def test_adds_a_missing_nested_setting_after_existing_comments
    original = "{\"plugins\": [\"local\"] // plugin comment\n}"
    result = JsoncPreferences.new(original).set(["theme", "name"], "system").to_s
    assert_equal "{\"plugins\": [\"local\"], // plugin comment\n\n\"theme\": {\"name\":\"system\"}\n}", result
  end

  def test_preserves_comments_inside_a_replaced_array
    original = '{"command": ["old", /* reason */ "arg"]}'
    result = JsoncPreferences.new(original).set(["command"], ["new"]).to_s
    assert_equal "{\"command\": /* reason */\n[\"new\"]}", result
  end

  def test_preserves_an_equal_value_and_its_escaping
    original = '{"name": "syst\u0065m"}'
    assert_equal original, JsoncPreferences.new(original).set(["name"], "system").to_s
  end

  def test_refuses_malformed_or_ambiguous_settings
    ['{"theme":', '{"theme": invalid}', '{"theme": 1, "theme": 2}', '{"theme": "dark"}'].each do |text|
      assert_raises(JSON::ParserError, ArgumentError, TypeError) do
        JsoncPreferences.new(text).set(["theme", "name"], "system")
      end
    end
  end
end
