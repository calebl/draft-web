# Getting Started

## Requirements
* install ruby on rails: http://www.installrails.com/

## Running in a Devcontainer (Recommended)
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
   - The app will be available at [http://localhost:8080](http://localhost:8080) on your host machine.

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
docker run -p 3000:3000 -v draft-db:/rails/db -v draft-storage:/rails/storage draft:latest
```

The app will be available at [http://localhost:3000](http://localhost:3000). The `-v` flags create named volumes so your database and uploaded files persist across container restarts.

### Running at draft.localhost with Traefik

If you want to run draft alongside other local dev servers without port conflicts, use a shared [Traefik](https://traefik.io/) reverse proxy.

**1. One-time setup — start a shared Traefik instance:**

```sh
docker network create proxy

docker run -d \
  --name traefik \
  --network proxy \
  -p 80:80 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  traefik:v3.0 \
  --providers.docker \
  --providers.docker.exposedByDefault=false \
  --entrypoints.web.address=:80
```

**2. Run draft with Traefik labels:**

```sh
docker run -d \
  --name draft \
  --network proxy \
  -v draft-db:/rails/db \
  -v draft-storage:/rails/storage \
  -l traefik.enable=true \
  -l 'traefik.http.routers.draft.rule=Host(`draft.localhost`)' \
  -l traefik.http.services.draft.loadbalancer.server.port=3000 \
  draft:latest
```

The app will be available at [http://draft.localhost](http://draft.localhost). Other projects can use the same Traefik instance with their own `*.localhost` hostnames.