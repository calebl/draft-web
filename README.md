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