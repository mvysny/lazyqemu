# frozen_string_literal: true

require 'minitest/autorun'
require 'window'

class TestWindow < Minitest::Test
  def test_smoke
    w = Window.new('foo')
    w = Window.new
    w.rect = Rect.new(-1, 0, 20, 20)
    w.content = %w[a b c]
    w.content do
      %w[a b c]
    end
  end
end

class TestLogWindow < Minitest::Test
  def test_smoke
    w = LogWindow.new
    w.error 'foo'
    w.warning 'bar'
    w.info 'foo'
    w.debug 'quack'
  end
end
