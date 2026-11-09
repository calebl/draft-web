require 'test_helper'

class IconsHelperTest < ActionView::TestCase
  test 'draws an icon as inline svg sized to the text' do
    svg = Nokogiri::HTML5.fragment(icon('desktop')).at_css('svg')

    assert_equal 'icon icon-desktop', svg['class']
    assert_equal '0 0 576 512', svg['viewBox']
    assert_equal '1.125em', svg['width']
    assert_equal '1em', svg['height']
    assert_equal 'true', svg['aria-hidden']
    assert_equal 'currentColor', svg.at_css('path')['fill']
    assert_predicate svg.at_css('path')['d'], :present?
  end

  test 'keeps extra classes so behaviour can find the icon' do
    svg = Nokogiri::HTML5.fragment(icon('arrows-alt', class_name: 'handle')).at_css('svg')

    assert_equal 'icon icon-arrows-alt handle', svg['class']
    assert_equal '1em', svg['width']
  end

  test 'every icon the pages use is drawn' do
    %w[sun moon desktop arrows-alt copy].each do |name|
      assert_includes icon(name), '<path'
    end
  end

  test 'an unknown icon is an error, not a blank space' do
    assert_raises(KeyError) { icon('nope') }
  end
end
