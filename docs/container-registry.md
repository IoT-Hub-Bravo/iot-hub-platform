# Build and Push Docker Image — Workflow Documentation

## Overview

This workflow builds the Django application Docker image and publishes it to GitHub Container Registry (GHCR) at `ghcr.io`. It is triggered automatically when a new version tag is pushed.

Image publishing is tied to the release cycle — a tag signals a stable, deploy-ready version. Pushing to `main` never publishes an image.

---

## Registry

GitHub Container Registry (`ghcr.io`) was chosen as the target registry. It is natively integrated with GitHub, supports fine-grained access control via repository permissions, and requires no third-party account or additional secrets — authentication is handled automatically using the built-in `GITHUB_TOKEN`.

Published images are scoped to the repository and visible under its **Packages** section. The image name is derived directly from the repository name, keeping naming consistent and automatic.

---

## Versioning

Image tags are generated automatically from the git tag that triggered the workflow. Pushing `v1.2.3` produces both a versioned tag and `latest`. OCI-standard labels are also applied, including source URL, commit revision, creation timestamp, and version.

---

## Security

The workflow operates with the minimum permissions required: read access to the repository contents, write access to packages, and two additional permissions for image signing. The published image is cryptographically signed, binding it to the exact source code, workflow, and repository it was built from.

---

## Verifying the Published Image

The attestation can be verified using the GitHub CLI:

```bash
gh attestation verify oci://ghcr.io/[organization/user]/[package-name]:[version] --repo [organization/user]/[repo name]
```

---

## Pulling the Published Image

The published image appears under the **Packages** section of the repository on GitHub, and can be pulled directly via the CLI using the versioned tag or `latest`

```bash
docker pull ghcr.io/[organization/user]/[package-name]:[version]
```

or in Dockerfile

```Dockerfile
FROM ghcr.io/[organization/user]/[package-name]:[version]
```