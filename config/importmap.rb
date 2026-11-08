# Pin npm packages by running ./bin/importmap
# Every module is served from vendor/javascript, so Draft can open without reaching
# outside sites.

pin 'application', preload: true
pin 'offline_write'
pin 'recent_stories', preload: true
pin '@hotwired/turbo-rails', to: '@hotwired--turbo-rails.js', preload: true # @8.0.16
pin '@rails/actioncable', to: '@rails--actioncable.js', preload: true # @7.1.3
pin '@rails/activestorage', to: '@rails--activestorage.js', preload: true # @7.1.3
pin 'jquery', preload: true # @3.7.1
pin 'sortablejs', preload: true # @1.15.0
pin '@hotwired/turbo', to: '@hotwired--turbo.js', preload: true # @8.0.13
pin '@rails/actioncable/src', to: '@rails--actioncable--src.js', preload: true # @7.1.3
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
