# Releases

This document lists the available Node.js container image releases.

## Current Releases

| Version | Node.js | npm | Release Date | Status |
|---------|---------|-----|--------------|--------|
| [v16.20.2](https://github.com/fortinj66/s2i-nodejs-container/releases/tag/v16.20.2) | 16.20.2 | 8.19.4 | 2026-06-05 | **Latest** |
| [v14.21.3](https://github.com/fortinj66/s2i-nodejs-container/releases/tag/v14.21.3) | 14.21.3 | 6.14.18 | 2026-06-05 | LTS |

## Image Tags

Images are available on Quay.io with the following tags:

### Node.js 16
```bash
podman pull quay.io/centos7/nodejs-16-centos7:16.20.2
podman pull quay.io/centos7/nodejs-16-centos7:latest
```

### Node.js 14
```bash
podman pull quay.io/centos7/nodejs-14-centos7:14.21.3
podman pull quay.io/centos7/nodejs-14-centos7:lts
```

## Release Schedule

Releases are created following the Node.js LTS schedule:

- **Node.js 14 (Fermium):** Maintenance until EOL (April 2023)
- **Node.js 16 (Gallium):** Active LTS until September 2023, then Maintenance until EOL (September 2024)

## Version Selection

Starting with the fix in v14.21.3/v16.20.2, you can specify the Node.js version in your `package.json`:

```json
{
  "name": "my-app",
  "version": "1.0.0",
  "engines": {
    "node": "16.20.2"
  }
}
```

The S2I build will automatically install the specified version during the build process.

## Building from Source

To build a specific release:

```bash
git clone https://github.com/fortinj66/s2i-nodejs-container.git
cd s2i-nodejs-container
git checkout v16.20.2  # or v14.21.3

# Build with make
make build TARGET=centos7 VERSIONS=16
```

## Previous Directory-Based Versions

Prior to June 2026, versions were organized by directory structure (e.g., `14/`, `16/`). The new release-based approach provides:

- ✅ Clear version history via Git tags
- ✅ Automatic changelog generation
- ✅ Better integration with CI/CD pipelines
- ✅ Semantic versioning support

## Creating New Releases

When Node.js releases new patch versions, create a new GitHub release:

```bash
# Authenticate with GitHub CLI
gh auth login

# Create release (example for v16.20.3)
gh release create v16.20.3 \
  --title "Node.js 16.20.3 (LTS)" \
  --notes "Node.js 16.20.3 LTS release with security updates"

# Push tag
git push origin v16.20.3
```

## Related Links

- [Node.js Release Schedule](https://nodejs.org/en/about/releases/)
- [Node.js 14 Changelog](https://github.com/nodejs/node/blob/main/doc/changelogs/CHANGELOG_V14.md)
- [Node.js 16 Changelog](https://github.com/nodejs/node/blob/main/doc/changelogs/CHANGELOG_V16.md)
- [Quay.io Repository](https://quay.io/repository/centos7/nodejs-16-centos7)
