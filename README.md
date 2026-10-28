# Getting Started

Draft runs as a local app for a single person: there is no sign up or log in.
On first visit it creates a local user that owns your stories. If you point it
at an existing database, it acts as the oldest account in it. When writing
sessions exist, the home page links to the most recently updated one.

## Running Locally

Requires Ruby 3.3.8 (see `.tool-versions`; `mise install` or `asdf install`
will fetch it) and SQLite.

```sh
bin/setup     # install gems, prepare the database, start the server
```

Then open [http://localhost:3000](http://localhost:3000). After the first run,
start the server with `bin/dev` (set `PORT` to use a different port).

Run the tests with:

```sh
bin/rails test
bin/rails test:system   # needs Chrome
```

## Running in a Devcontainer
You can easily set up and run this project in a [VS Code Devcontainer](https://code.visualstudio.com/docs/devcontainers/containers):

1. **Open in VS Code/Cursor**
   - Make sure you have the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) installed.
   - Open this project folder in VS Code.
   - When prompted, reopen the folder in the devcontainer, or use the command palette: `Dev Containers: Reopen in Container`.

2. **Initial Setup**
   - The devcontainer will automatically build and run `bin/setup --skip-server` to install dependencies and prepare the database.
   - If you need to re-run setup, use:
     ```sh
     bin/setup --skip-server
     ```

3. **Start the Rails Server**
   - In the devcontainer terminal, run:
     ```sh
     bin/dev
     ```
   - The app will be available at [http://localhost:10000](http://localhost:10000) on your host machine.

## Up and Running
* the devcontainer.json configuration will also copy your ssh settings for github to the docker container so you can
use git without needing to reauthenticate

## Running with Docker

### Build the image

```sh
bin/docker-build
```

Or pass a custom tag:

```sh
bin/docker-build v1.0.0
```

This tags the image as both `draft:<tag>` and `draft:<git-sha>`.

### Run the container

```sh
bin/docker-run
```

The app will be available at [http://draft.localhost](http://draft.localhost). To use a different port:

```sh
PORT=3001 bin/docker-run
```

Named volumes (`draft-data` and `draft-storage`) persist the database and uploaded files across container restarts.

### Allowed hosts

In production, set `RAILS_ALLOWED_HOSTS` to a comma-separated list of host names or
addresses (for example `myhost.example.ts.net,100.64.0.1`) to reject requests for any
other `Host`. When it is unset, every host is accepted.

## Feedback

The feedback button comes from the [pocket-kit](https://github.com/calebl/pocket-kit) gem,
configured in `config/initializers/pocket_kit.rb`. Set `DRAFT_FEEDBACK_COMMAND` in the server
environment to a command (split like a shell word list, but run without a shell) to show a
feedback button in the page header. Sending runs the command with
`--request-id draft-feedback-<uuid> --json -` appended and the message on stdin: a
`Draft feedback (screen: controller#action)` line, a blank line, the typed text, then a
`Device:` block describing the browser (user agent, screen, window and visible size, pixel
ratio, home screen app, color scheme) when it reported them. Exit status 0 or 3 counts as sent. Feedback is limited to 2,000 characters and five
submissions per minute. When the variable is unset, the button is hidden and the endpoint
returns 404.

## Error monitoring

Error monitoring also comes from pocket-kit, configured in the same initializer. Set
`DRAFT_ERRORS_COMMAND` in the server environment to a command (run the same way as the
feedback command) to report unhandled request exceptions, exceptions that escape a job, and
uncaught errors in the page. Each report runs the command with
`--request-id draft-errors-<uuid> --json -` appended and the JSON report on stdin, its text
starting `Draft error (source: ...)`. Repeats of the same error within ten minutes are
counted and sent with the next report rather than run again. When the variable is unset,
nothing is reported.

## Running behind tailscale serve

On a machine on a tailnet, draft-web can run as a systemd user service that listens only
on `127.0.0.1:3000`, with `tailscale serve` providing the https address on port 8444. This
follows the [pocket-kit local app pattern](https://github.com/calebl/pocket-kit/blob/main/docs/local-app-pattern.md).

The install lives under `~/.local/share/draft-web/`: the app checkout in `app/`, the
SQLite database in `data/`, `bin/start` copied to `bin/start`, and secrets (such as
`SECRET_KEY_BASE`) in `secrets.env`, mode `600`, never committed.

```sh
cp bin/start ~/.local/share/draft-web/bin/start
cp deploy/draft-web.service ~/.config/systemd/user/draft-web.service
# edit RAILS_ALLOWED_HOSTS to the machine's tailnet name, e.g. mybox.tail1234.ts.net
systemctl --user daemon-reload
systemctl --user enable --now draft-web
loginctl enable-linger "$USER"
tailscale serve --bg --https=8444 http://127.0.0.1:3000
```

The unit sets `RAILS_ASSUME_SSL=true` because tailscale terminates TLS and forwards plain
http, and `RAILS_FORCE_SSL=false` because forcing SSL sends HSTS for the shared tailnet
host name, which would break other plain-http ports on the same machine. Adjust the ruby
path in `PATH` to match the installed version.
