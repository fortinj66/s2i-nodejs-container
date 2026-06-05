#!/bin/bash
# Create GitHub releases for Node.js versions
# Run this after: gh auth login

set -e

echo "Creating GitHub releases for s2i-nodejs-container..."
echo ""

# Node.js 14 release
echo "Creating release v14.21.3..."
gh release create v14.21.3 \
  --title "Node.js 14.21.3 (LTS)" \
  --notes "Node.js 14.21.3 LTS release

## Versions
- **Node.js:** 14.21.3
- **npm:** 6.14.18

## Changes from previous
- Updated to latest Node.js 14 LTS version
- Includes security updates and bug fixes
- Fixed version parsing from package.json engines field

## Installation
\`\`\`bash
make build TARGET=centos7 VERSIONS=14
\`\`\`

## Image Tags
- \`quay.io/centos7/nodejs-14-centos7:14.21.3\`
- \`quay.io/centos7/nodejs-14-centos7:latest\`

## Docker Pull
\`\`\`bash
podman pull quay.io/centos7/nodejs-14-centos7:14.21.3
\`\`\`"

echo "✓ Release v14.21.3 created"
echo ""

# Node.js 16 release
echo "Creating release v16.20.2..."
gh release create v16.20.2 \
  --title "Node.js 16.20.2 (LTS)" \
  --notes "Node.js 16.20.2 LTS release

## Versions
- **Node.js:** 16.20.2
- **npm:** 8.19.4

## Changes from previous
- Updated to latest Node.js 16 LTS version
- Includes security updates and bug fixes
- Fixed version parsing from package.json engines field

## Installation
\`\`\`bash
make build TARGET=centos7 VERSIONS=16
\`\`\`

## Image Tags
- \`quay.io/centos7/nodejs-16-centos7:16.20.2\`
- \`quay.io/centos7/nodejs-16-centos7:latest\`

## Docker Pull
\`\`\`bash
podman pull quay.io/centos7/nodejs-16-centos7:16.20.2
\`\`\`"

echo "✓ Release v16.20.2 created"
echo ""

echo "All releases created successfully!"
echo ""
echo "View releases at:"
echo "https://github.com/fortinj66/s2i-nodejs-container/releases"
