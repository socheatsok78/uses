#!/bin/bash
# shellcheck disable=SC2086

echo "Running Docker Triage action..."

# GitHub Actions helpers
gh_group() { echo "::group::$1"; }
gh_group_end() { echo "::endgroup::"; }
gh_set_output() { echo "$1=$2" >> "$GITHUB_OUTPUT"; }
gh_warning() { echo "::warning::$*"; }
gh_error() { echo "::error::$*"; }
gh_set_env() { 
	export "$1"="$2"
	echo "$1=$2" >> "$GITHUB_ENV";
}

DOCKER_BAKE_FILE="${GITHUB_ACTION_PATH}/docker-triage-action.hcl"
DOCKER_BAKE_OUTPUT_PUSH=false

gh_group "Evaluating GitHub context..."
# TODO: This logic is a bit complex, need to simplify it.
if [[ "${GITHUB_REF_TYPE}" == "tag" ]]; then
	# If it's a tag push, we want to push the Docker image regardless of the branch or labels.
	DOCKER_BAKE_OUTPUT_PUSH=true
elif [[ "${GITHUB_EVENT_NAME}" == "push" ]] || [[ "${GITHUB_EVENT_NAME}" == "workflow_dispatch" ]]; then
	case "${GITHUB_REF_NAME}" in
		main|develop|next)
			DOCKER_BAKE_OUTPUT_PUSH=true
		;;
		*)
			DOCKER_BAKE_OUTPUT_PUSH=false
		;;
	esac
elif [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]; then
	# If the GITHUB_EVENT_PATH file exists, and check for the "docker:push" label
	if [ ! -f "${GITHUB_EVENT_PATH}" ]; then
		gh_error "GITHUB_EVENT_PATH file does not exist: ${GITHUB_EVENT_PATH}"
		exit 1
	fi
	DOCKER_BAKE_OUTPUT_PUSH=`jq '.pull_request.labels | any(.name == "docker:push")' "${GITHUB_EVENT_PATH}"`
fi

echo "+ GITHUB_EVENT_NAME=${GITHUB_EVENT_NAME}"
echo "+ GITHUB_REF_NAME=${GITHUB_REF_NAME}"
echo "+ DOCKER_BAKE_OUTPUT_PUSH=${DOCKER_BAKE_OUTPUT_PUSH}"
echo
gh_group_end

gh_group 'Generating "docker-triage-action" target...'
cat <<EOT >${DOCKER_BAKE_FILE}
target "docker-triage-action" {
	output = [
		"push=${DOCKER_BAKE_OUTPUT_PUSH},type=image"
	]
}
EOT
docker buildx bake -f "${DOCKER_BAKE_FILE}" docker-triage-action --print
gh_group_end

echo "Output:"
echo "- bake-file = ${DOCKER_BAKE_FILE}"
gh_set_output "bake-file" "${DOCKER_BAKE_FILE}"

# Warn if the image will not be pushed, to avoid confusion for users who expect it to be pushed.
if [[ "${DOCKER_BAKE_OUTPUT_PUSH}" == "false" ]]; then
	echo "Notice:"
	gh_warning "The Docker image will not be pushed to the registry. To enable pushing, either push to a tag, push to main/develop/next branches, or add the 'docker:push' label to the pull request."
fi
