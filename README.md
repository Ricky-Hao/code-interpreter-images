# Code Interpreter Images

Builds the six `linux/amd64` images required by LibreChat Code Interpreter and publishes them to GHCR. The source is checked out from an immutable upstream commit; this repository does not vendor or modify the upstream application.

## Pinned source

The current source revision is recorded in [`versions.env`](versions.env):

```text
LibreChat-AI/code-interpreter@2c7fb8fcd7113f0f78b2085e80adf651ea4e5359
```

Update the full commit SHA in that file to build a newer upstream revision. Pull requests validate every Dockerfile and target but do not publish images.

## Images

| GHCR package | Dockerfile | Target |
| --- | --- | --- |
| `codeapi-api` | `service/Dockerfile.api` | `production` |
| `codeapi-worker` | `service/Dockerfile.worker` | `production` |
| `codeapi-file-server` | `service/Dockerfile` | `production` |
| `codeapi-egress-gateway` | `service/Dockerfile.egress-gateway` | `production` |
| `codeapi-tool-call-server` | `service/Dockerfile.tool-call-server` | `production` |
| `codeapi-sandbox-runner` | `api/Dockerfile` | `sandbox-runner-baked` |

The matrix is maintained in [`images.json`](images.json). The baked sandbox runner has a separate three-hour job because it compiles the language runtimes and creates the MicroVM root disk during the build.

## Publishing

A push to `main`, or a manual run of **Build Code Interpreter images**, publishes to:

```text
ghcr.io/ricky-hao/<package>:upstream-<full-commit-sha>
ghcr.io/ricky-hao/<package>:upstream-<12-character-sha>
ghcr.io/ricky-hao/<package>:latest
```

`latest` is emitted only from the default branch. Each build also publishes an SBOM and provenance attestation. The Actions job summary records the content digest; use that digest for the strongest deployment pin instead of `latest`.

The workflow uses only the repository-scoped `GITHUB_TOKEN`. No registry password or personal access token is required. New GHCR packages may need their visibility changed to public after the first successful build if they will be pulled without an image pull secret.

## Validation

Static configuration check:

```bash
bash scripts/verify-config.sh
```

Validate all Docker targets against an upstream checkout at the pinned commit:

```bash
bash scripts/verify-config.sh /path/to/code-interpreter
```

The second command requires `jq`, Git, Docker Buildx, and a `linux/amd64` builder.