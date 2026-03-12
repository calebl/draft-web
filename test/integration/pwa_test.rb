require 'test_helper'

class PwaTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'manifest.json is served with correct content type' do
    get '/manifest.json'
    assert_response :success
    manifest = JSON.parse(response.body)
    assert_equal 'Draft', manifest['name']
    assert_equal 'standalone', manifest['display']
    assert manifest['icons'].any? { |icon| icon['sizes'] == '512x512' }
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
    sign_in users(:bob)
    get root_path
    assert_response :success

    assert_select 'link[rel="manifest"][href="/manifest.json"]'
    assert_select 'meta[name="theme-color"]'
    assert_select 'link[rel="apple-touch-icon"]'
    assert_includes response.body, 'navigator.serviceWorker.register'
  end

  test 'application layout includes PWA tags' do
    sign_in users(:bob)
    get stories_path
    assert_response :success

    assert_select 'link[rel="manifest"][href="/manifest.json"]'
    assert_select 'meta[name="theme-color"]'
    assert_select 'link[rel="apple-touch-icon"]'
    assert_includes response.body, 'navigator.serviceWorker.register'
  end
end
