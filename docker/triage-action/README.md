# `docker/triage-action`
A GitHub Action to triage Docker images using Buildx Bake.

This action evaluates the current GitHub event and determines which Docker images to build based on the event type. If the follwing conditions are met, it will allow the image to be pushed to the registry:

- If the GitHub event is not a `pull_request` and the branch is `main`, `develop`, or `next`, the Docker image will be pushed to the registry.

- For `pull_request` events, the image will not be pushed unless the pull request has the `docker:push` label. In that case, the image will be pushed with a `pr-<num>` tag.
