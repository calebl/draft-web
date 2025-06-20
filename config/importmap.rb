# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'https://ga.jspm.io/npm:@hotwired/turbo-rails@8.0.16/app/javascript/turbo/index.js',
                             preload: true
pin '@rails/actioncable',
    to: 'https://ga.jspm.io/npm:@rails/actioncable@7.1.3/app/assets/javascripts/actioncable.esm.js', preload: true
pin '@rails/activestorage',
    to: 'https://ga.jspm.io/npm:@rails/activestorage@7.1.3/app/assets/javascripts/activestorage.esm.js', preload: true
pin 'jquery', to: 'https://ga.jspm.io/npm:jquery@3.7.1/dist/jquery.js', preload: true
pin 'sortablejs', to: 'https://ga.jspm.io/npm:sortablejs@1.15.0/modular/sortable.esm.js', preload: true
pin 'toastr', to: 'https://ga.jspm.io/npm:toastr@2.1.4/toastr.js', preload: true
pin '@hotwired/turbo', to: 'https://ga.jspm.io/npm:@hotwired/turbo@8.0.13/dist/turbo.es2017-esm.js', preload: true
pin '@rails/actioncable/src', to: 'https://ga.jspm.io/npm:@rails/actioncable@7.1.3/src/index.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
