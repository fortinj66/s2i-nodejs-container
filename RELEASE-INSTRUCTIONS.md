# Release Creation Instructions

## Latest Versions (as of 2026-06-05)

- **Node.js 14:** v14.21.3 with npm 6.14.18
- **Node.js 16:** v16.20.2 with npm 8.19.4

## Steps to Create Releases

### 1. Authenticate with GitHub CLI

```bash
gh auth login
```

Follow the prompts to authenticate.

### 2. Run the Release Script

```bash
cd C:\Users\forti\.openclaw\workspace\s2i-nodejs-container
bash create-releases.sh
```

This will create two GitHub releases:
- `v14.21.3` - Node.js 14 LTS
- `v16.20.2` - Node.js 16 LTS

### 3. Verify Releases

Visit: https://github.com/fortinj66/s2i-nodejs-container/releases

### 4. Build and Push Images (Optional)

After creating releases, build and push the container images to Quay.io:

```bash
# Build Node.js 14
make build TARGET=centos7 VERSIONS=14
podman tag localhost/nodejs-14-centos7 quay.io/centos7/nodejs-14-centos7:14.21.3
podman push quay.io/centos7/nodejs-14-centos7:14.21.3

# Build Node.js 16
make build TARGET=centos7 VERSIONS=16
podman tag localhost/nodejs-16-centos7 quay.io/centos7/nodejs-16-centos7:16.20.2
podman push quay.io/centos7/nodejs-16-centos7:16.20.2
```

## Future Releases

When Node.js releases new patch versions:

1. Check latest versions at https://nodejs.org/dist/
2. Update `create-releases.sh` with new version numbers
3. Run the script to create new GitHub releases
4. Build and push updated container images

## Manual Release Creation

If you prefer to create releases manually:

```bash
# Node.js 14
gh release create v14.21.3 \
  --title "Node.js 14.21.3 (LTS)" \
  --notes "Node.js 14.21.3 LTS release with security updates"

# Node.js 16
gh release create v16.20.2 \
  --title "Node.js 16.20.2 (LTS)" \
  --notes "Node.js 16.20.2 LTS release with security updates"
```

## Git Tags

The releases use semantic versioning tags:
- `v14.21.3`
- `v16.20.2`

These tags point to commits that include the updated Dockerfiles and assemble scripts for those specific versions.
