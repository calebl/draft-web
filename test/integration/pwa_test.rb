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

  test 'home screen icons exist and are opaque' do
    manifest = JSON.parse(Rails.public_path.join('manifest.json').read)
    paths = ['/apple-touch-icon.png'] + manifest['icons'].pluck('src')
    paths.each do |path|
      png = Rails.public_path.join(path.delete_prefix('/')).binread
      # IHDR colour type byte: 2 = truecolour without alpha.
      assert_equal 2, png.getbyte(25), "#{path} should have no alpha channel"
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
