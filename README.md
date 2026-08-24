# Code Interpreter Images

This repository is retained as a read-only record of the former upstream-image
and patch workflows. Its GitHub Actions have been retired, and its existing
`codeapi-*` GHCR packages remain available only for rollback.

Active source maintenance, tests, and all six `linux/amd64` image builds now
live in [`Ricky-Hao/code-interpreter`](https://github.com/Ricky-Hao/code-interpreter).
That repository publishes immutable `code-interpreter-*` images from one source
commit through `.github/workflows/build-images.yml`.

Do not publish new images from this repository. Historical files are preserved
to document the old migration path.
