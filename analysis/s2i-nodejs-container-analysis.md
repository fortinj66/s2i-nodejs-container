# Repository Analysis: s2i-nodejs-container

**Source:** https://github.com/fortinj66/s2i-nodejs-container  
**Analysis Date:** 2026-06-05

## Overview

This repository contains Source-to-Image (S2I) builder templates for creating Node.js container images. It's a fork of the official [sclorg/s2i-nodejs-container](https://github.com/sclorg/s2i-nodejs-container) project, intended for building reproducible container images for OpenShift and general usage.

## Supported Versions

### Node.js Versions
- **NodeJS 14** (`/14/`)
- **NodeJS 16** (`/16/`)

### Base Operating Systems
- **RHEL:** 7, 8, 9
- **CentOS:** 7, Stream 9
- **Fedora:** (for NodeJS 14 & 16)

### Pre-built Images on Quay
| Version | Repository |
|---------|-----------|
| nodejs-12 | `quay.io/centos7/nodejs-12-centos7` |
| nodejs-14 | `quay.io/centos7/nodejs-14-centos7` |
| nodejs-16 | `quay.io/sclorg/nodejs-16-c9s` |
| Fedora nodejs-14 | `quay.io/fedora/nodejs-14` |
| Fedora nodejs-16 | `quay.io/fedora/nodejs-16` |

## Repository Structure

```
s2i-nodejs-container/
├── 14/                    # Node.js 14 image definition
│   ├── Dockerfile         # CentOS-based build
│   ├── Dockerfile.rhel7   # RHEL-based build
│   ├── s2i/bin/           # S2I lifecycle scripts
│   │   ├── assemble       # Build/install dependencies
│   │   ├── run            # Runtime entrypoint
│   │   └── usage          # Usage documentation
│   └── root/              # Additional files
├── 16/                    # Node.js 16 image definition
│   └── (same structure as 14/)
├── common/                # Shared Makefile code (submodule)
├── Makefile               # Build orchestration
└── README.md              # Documentation
```

## Key Components

### Dockerfile Features (NodeJS 14 & 16)

**Base Image:** `quay.io/centos7/s2i-core-centos7`

**Environment Variables:**
- `NODEJS_VERSION` - Major version (14 or 16)
- `NPM_RUN` - npm script to execute (default: `start`)
- `NPM_CONFIG_PREFIX` - Global npm modules location (`$HOME/.npm-global`)
- `PATH` - Includes SCL paths and global npm bin directories
- `LD_LIBRARY_PATH` - SCL library path

**Installed Packages:**
```bash
make gcc gcc-c++ git openssl-devel \
rh-nodejs${NODEJS_VERSION} \
rh-nodejs${NODEJS_VERSION}-npm \
rh-nodejs${NODEJS_VERSION}-nodejs-nodemon \
nss_wrapper
```

**Security:**
- Drops to non-root user (UID 1001)
- Restricts `/opt/app-root` permissions to user 1001 and group 0

### S2I Lifecycle Scripts

#### `assemble` (Build Phase)
1. Restores cached `node_modules` from `/tmp/artifacts` if available
2. Moves application source to working directory
3. **Version Override Support:** Reads `package.json` engines.node and installs specific Node.js version via nvm
4. **Proxy Configuration:** Supports HTTP_PROXY, HTTPS_PROXY environment variables
5. **NPM Mirror:** Supports custom NPM_MIRROR registry
6. **Build Modes:**
   - Development: `npm install` (all deps)
   - Production: `npm install` → `npm run build` → `npm prune`

Key features:
- Safe logging (redacts credentials in proxy URLs)
- NPM cache cleanup in production mode
- Permission fixing via `fix-permissions` helper

#### `run` (Runtime Phase)
1. Sources container user generation if available
2. **Development Mode:** Runs via `nodemon --inspect=$DEBUG_PORT` (default port: 5858)
3. **Production Mode:** Runs via `npm run $NPM_RUN`
4. Environment detection:
   - `DEV_MODE=true` → `NODE_ENV=development`, nodemon with debugging
   - `DEV_MODE=false` → `NODE_ENV=production`, standard npm execution

### Makefile

Uses shared `common/common.mk` submodule for build orchestration:

```makefile
BASE_IMAGE_NAME = nodejs
VERSIONS = 14 14-minimal 16 16-minimal
OPENSHIFT_NAMESPACES = 
```

**Build Commands:**
```bash
# CentOS build
make build TARGET=centos7 VERSIONS=16

# RHEL build (requires subscription)
make build TARGET=rhel7 VERSIONS=16

# Test
make test TARGET=centos7 VERSIONS=16
```

## Notable Features

### 1. SCL Integration
Uses Red Hat Software Collections Layer (SCL) for parallel Node.js version support without system conflicts.

### 2. Flexible Deployment
- **OpenShift Ready:** Includes proper labels for K8s/OpenShift integration
- **Podman/Docker Compatible:** Works with any OCI runtime
- **Non-root by Default:** Security-first approach with UID 1001

### 3. Development Workflow
- Hot reload via nodemon in dev mode
- Remote debugging on port 5858
- Volume-friendly (doesn't clean mounted npm cache/tmp dirs)

### 4. Enterprise Features
- Proxy support for corporate environments
- Custom NPM registry mirrors
- Build artifact caching for faster rebuilds
- RHEL certification pathway

## Potential Considerations

1. **Node.js Versions:** Currently provides 14 & 16; both are EOL or approaching EOL
   - Node.js 14 EOL: April 2023
   - Node.js 16 EOL: September 2023
   
2. **Base Images:** CentOS 7 is EOL (June 2024); may need migration to Stream 9 or alternative bases

3. **Submodule Dependency:** Requires `common/` submodule initialization:
   ```bash
   git clone --recursive https://github.com/fortinj66/s2i-nodejs-container.git
   # or
   git submodule update --init
   ```

4. **RHEL Builds:** Require active Red Hat subscription for legal builds

## Recommended Next Steps

If maintaining/extending this fork:

1. **Update Node.js versions** to current LTS (20, 22)
2. **Migrate base images** from CentOS 7 to UBI9 or Alpine
3. **Add GitHub Actions workflow** for automated builds (currently uses upstream sclorg workflows)
4. **Consider multi-arch builds** (arm64 support)
5. **Update security scanning** integration

---

*Analysis performed via OpenClaw github-win skill and web fetch*
