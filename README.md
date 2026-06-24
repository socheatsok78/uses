## About
A shared-workflow for various tasks for [@socheatsok78](https://github.com/socheatsok78).

## Example
Here is an example of how to use this workflow in your repository. It can be used in other workflows by calling it with the appropriate inputs.

### `.github/workflows/docker.yml`
```yaml
name: Docker

on:
  workflow_dispatch:
  push:
    branches:
      - main
      - develop
  pull_request:
    types: [opened, synchronize, reopened]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  docker:
    uses: socheatsok78/uses/.github/workflows/docker-buildx-bake.yml@main
    permissions:
      contents: read
      packages: write
    with:
      permit-login: ${{ github.event_name != 'pull_request' }}
      permit-push: ${{ github.event_name != 'pull_request' }}
```
