# Node.js 24 Release Instructions

## Latest Version Info (as of 2026-06-05)

- **Node.js:** 24.16.0 "Krypton" (LTS)
- **npm:** 11.5.x (bundled)
- **Release Date:** May 21, 2026
- **Status:** Current LTS

## Key Features in Node.js 24

- Temporal API enabled by default
- V8 JavaScript engine 14.6
- Undici 8.0 for HTTP client
- Improved performance and security updates

## Create GitHub Release

### Option 1: Using GitHub CLI

```bash
cd C:\Users\forti\.openclaw\workspace\s2i-nodejs-container

# Authenticate (if not already done)
gh auth login

# Create release
gh release create v24.16.0 \
  --title "Node.js 24.16.0 (LTS)" \
  --notes "Node.js 24.16.0 LTS release (Krypton)

## Versions
- **Node.js:** 24.16.0
- **npm:** 11.5.x

## Features
- Temporal API enabled by default
- V8 engine 14.6
- Undici 8.0
- Latest LTS release (May 2026)

## Installation
\`\`\`bash
make build TARGET=centos7 VERSIONS=24
\`\`\`

## Image Tags
- \`quay.io/centos7/nodejs-24-centos7:24.16.0\`
- \`quay.io/centos7/nodejs-24-centos7:latest\`"
```

### Option 2: Manual via GitHub Web UI

1. Go to: https://github.com/fortinj66/s2i-nodejs-container/releases/new
2. Tag version: `v24.16.0`
3. Release title: `Node.js 24.16.0 (LTS)`
4. Copy release notes from above
5. Click "Publish release"

## Build and Push Container Image

After creating the release:

```bash
# Build Node.js 24 image
make build TARGET=centos7 VERSIONS=24

# Tag and push to Quay.io
podman tag localhost/nodejs-24-centos7 quay.io/centos7/nodejs-24-centos7:24.16.0
podman push quay.io/centos7/nodejs-24-centos7:24.16.0

# Also tag as latest
podman tag localhost/nodejs-24-centos7 quay.io/centos7/nodejs-24-centos7:latest
podman push quay.io/centos7/nodejs-24-centos7:latest
```

## Update Documentation

After the release is created, update RELEASES.md:

```markdown
| [v24.16.0](link) | 24.16.0 | 11.5.x | 2026-06-05 | **Current LTS** |
```

## Verify Release

- Check GitHub: https://github.com/fortinj66/s2i-nodejs-container/releases
- Check Quay.io: https://quay.io/repository/centos7/nodejs-24-centos7

## Next Patch Release

When Node.js 24.17.0 is released, repeat this process with the new version number.
