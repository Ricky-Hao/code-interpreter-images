#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_file="${repo_root}/images.json"

# shellcheck source=/dev/null
source "${repo_root}/versions.env"

if [[ ! "${UPSTREAM_REPOSITORY}" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    echo "Invalid UPSTREAM_REPOSITORY: ${UPSTREAM_REPOSITORY}" >&2
    exit 1
fi

if [[ ! "${UPSTREAM_SHA}" =~ ^[0-9a-f]{40}$ ]]; then
    echo "UPSTREAM_SHA must be a full lowercase Git commit SHA" >&2
    exit 1
fi

jq -e '
    def expected_services:
        [
            {"image": "codeapi-api", "dockerfile": "service/Dockerfile.api", "target": "production"},
            {"image": "codeapi-egress-gateway", "dockerfile": "service/Dockerfile.egress-gateway", "target": "production"},
            {"image": "codeapi-file-server", "dockerfile": "service/Dockerfile", "target": "production"},
            {"image": "codeapi-tool-call-server", "dockerfile": "service/Dockerfile.tool-call-server", "target": "production"},
            {"image": "codeapi-worker", "dockerfile": "service/Dockerfile.worker", "target": "production"}
        ];

    def expected_sandbox:
        {"image": "codeapi-sandbox-runner", "dockerfile": "api/Dockerfile", "target": "sandbox-runner-baked"};

    def valid_image:
        (type == "object")
        and ((keys | sort) == ["dockerfile", "image", "target"])
        and ((.image | type) == "string")
        and (.image | test("^codeapi-[a-z0-9-]+$"))
        and ((.dockerfile | type) == "string")
        and (.dockerfile | test("^[A-Za-z0-9._/-]+$"))
        and (.dockerfile | contains("..") | not)
        and ((.target | type) == "string")
        and (.target | test("^[A-Za-z0-9._-]+$"));

    (.services | type == "array" and length == 5)
    and (.sandbox | valid_image)
    and ([.services[] | valid_image] | all)
    and (.services | sort_by(.image) == expected_services)
    and (.sandbox == expected_sandbox)
' "${config_file}" >/dev/null

if [[ $# -gt 1 ]]; then
    echo "Usage: $0 [upstream-source-directory]" >&2
    exit 1
fi

if [[ $# -eq 1 ]]; then
    source_dir="$(cd "$1" && pwd)"
    actual_sha="$(git -C "${source_dir}" rev-parse HEAD)"

    if [[ "${actual_sha}" != "${UPSTREAM_SHA}" ]]; then
        echo "Upstream checkout is ${actual_sha}; expected ${UPSTREAM_SHA}" >&2
        exit 1
    fi

    while IFS=$'\t' read -r image dockerfile target; do
        if [[ ! -f "${source_dir}/${dockerfile}" ]]; then
            echo "Missing Dockerfile for ${image}: ${dockerfile}" >&2
            exit 1
        fi

        echo "Checking ${image} (${dockerfile}, target ${target})"
        docker buildx build \
            --check \
            --platform linux/amd64 \
            --target "${target}" \
            --file "${source_dir}/${dockerfile}" \
            "${source_dir}"
    done < <(jq -r '[.services[], .sandbox][] | [.image, .dockerfile, .target] | @tsv' "${config_file}")
fi

echo "Configuration is valid for ${UPSTREAM_REPOSITORY}@${UPSTREAM_SHA}"