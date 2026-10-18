require 'test_helper'

class PwaTest < ActionDispatch::IntegrationTest
  test 'manifest.json is served with correct content type' do
    get '/manifest.json'
    assert_response :success
    manifest = response.parsed_body
    assert_equal 'Draft', manifest['name']
    assert_equal 'standalone', manifest['display']
    assert(manifest['icons'].any? { |icon| icon['sizes'] == '512x512' })
    assert(manifest['icons'].any? { |icon| icon['purpose'] == 'maskable' })
  end

  # IHDR colour type byte: 2 = truecolour without alpha, 6 = with alpha.
  def png_color_type(path)
    Rails.public_path.join(path.delete_prefix('/')).binread.getbyte(25)
  end

  test 'manifest launcher icons are opaque' do
    manifest = JSON.parse(Rails.public_path.join('manifest.json').read)
    manifest['icons'].reject { |icon| icon['purpose'] == 'monochrome' }.each do |icon|
      assert_equal 2, png_color_type(icon['src']), "#{icon['src']} should have no alpha channel"
    end
  end

  test 'themeable icons keep a transparent background' do
    manifest = JSON.parse(Rails.public_path.join('manifest.json').read)
    monochrome = manifest['icons'].select { |icon| icon['purpose'] == 'monochrome' }.pluck('src')
    assert_not_empty monochrome
    (['/apple-touch-icon.png'] + monochrome).each do |path|
      assert_equal 6, png_color_type(path), "#{path} should have an alpha channel"
    end
  end

  test 'service worker is served' do
    get '/sw.js'
    assert_response :success
    assert_includes response.body, 'CACHE_NAME'
  end

  test 'offline page is served' do
    get '/offline.html'
    assert_response :success
    assert_includes response.body, "You're offline"
  end

  test 'home layout includes PWA tags' do
    act_as users(:bob)
    get root_path
    assert_response :success

    assert_select 'link[rel="manifest"][href="/manifest.json"]'
    assert_select 'meta[name="theme-color"]'
    assert_select 'link[rel="apple-touch-icon"]'
    assert_includes response.body, 'navigator.serviceWorker.register'
  end

  test 'application layout includes PWA tags' do
    act_as users(:bob)
    get stories_path
    assert_response :success

    assert_select 'link[rel="manifest"][href="/manifest.json"]'
    assert_select 'meta[name="theme-color"]'
    assert_select 'link[rel="apple-touch-icon"]'
    assert_includes response.body, 'navigator.serviceWorker.register'
  end
end
