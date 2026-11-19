# AGENTS.md

Draft is a Rails 8 + SQLite app: a peaceful, distraction-free place to write rough drafts. Product direction lives in `VISION.md`.

## Commands

Use Ruby 3.3.8 (pinned in `.tool-versions`); if `ruby -v` shows another version, run `mise install` and prefix commands with `mise exec --`.

- Install: `bundle install`
- Run locally: `bin/dev`
- Unit and integration tests: `bin/rails test`
- System tests (headless Chrome): `bin/rails test:system`
- Build assets: `SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile` (writes gitignored `public/assets`)

CI (`.github/workflows/draft.yml`) runs `bundle exec rake` and `bundle exec rake test:system`.

## Layout

- `app/` holds standard Rails code; the offline writing support is in `app/javascript/` (`offline_write.js`, `offline_new_session.js`).
- `test/` mirrors `app/`, with browser tests in `test/system/`.

Put temporary probes, scratch tests and generated output under /tmp or a gitignored directory, and make sure `git status` is clean of them before reporting work done.

Report checks as passed only after every check has finished and exited 0; name any check you did not run.
