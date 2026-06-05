# S2I Node.js Version Override Test Framework

Test framework for validating Node.js version selection in s2i-nodejs-container builds.

## Overview

This framework tests the ability to override Node.js versions during S2I builds using:
1. `package.json` `engines.node` field
2. `NODE_VERSION` environment variable
3. `.nvmrc` file

## Test Applications

Each test app is a minimal Node.js application with different version configurations:

```
test-apps/
├── node-14-exact/          # engines: "14.17.0"
├── node-14-caret/          # engines: "^14.0.0"
├── node-16-exact/          # engines: "16.13.0"
├── node-16-range/          # engines: ">=14.0.0 <17.0.0"
├── node-env-override/      # No engines, uses NODE_VERSION env
├── node-nvmrc/             # Uses .nvmrc file
└── node-default/           # No version spec (uses base image)
```

## Prerequisites

```bash
# Install S2I CLI
# Windows: Download from https://github.com/openshift/source-to-image/releases
choco install s2i

# Or use podman with s2i support
podman pull quay.io/openshift/origin-cli:latest
```

## Quick Start

### 1. Build Base Images (if not already built)

```bash
# From s2i-nodejs-container root
cd C:\path\to\s2i-nodejs-container

# Build Node.js 14 base image
make build TARGET=centos7 VERSIONS=14

# Build Node.js 16 base image
make build TARGET=centos7 VERSIONS=16
```

### 2. Run Test Suite

```bash
cd C:\Users\forti\.openclaw\workspace\s2i-nodejs-test

# Run all tests
.\run-tests.ps1

# Run specific test
.\run-tests.ps1 -TestName node-14-exact

# Run with verbose output
.\run-tests.ps1 -Verbose
```

## Test Cases

| Test Name | Version Spec | Expected Result |
|-----------|--------------|-----------------|
| `node-14-exact` | `"14.17.0"` | Node.js 14.17.0 |
| `node-14-caret` | `"^14.0.0"` | Node.js 14.x (latest 14.x) |
| `node-16-exact` | `"16.13.0"` | Node.js 16.13.0 |
| `node-16-range` | `">=14.0.0 <17.0.0"` | Node.js 16.x (latest in range) |
| `node-env-override` | Env: `NODE_VERSION=18.0.0` | Node.js 18.0.0 |
| `node-nvmrc` | `.nvmrc: "20.0.0"` | Node.js 20.0.0 |
| `node-default` | None | Base image version (14 or 16) |

## Manual Testing

### Test with package.json engines

```bash
cd test-apps/node-14-exact

# Build with S2I
s2i build . quay.io/centos7/nodejs-14-centos7:latest test-app-14 \
  --docker-config $HOME/.docker/config.json

# Run container
podman run -d -p 8080:8080 test-app-14

# Check Node.js version
podman exec -it <container-id> node --version
# Expected: v14.17.0
```

### Test with Environment Variable

```bash
cd test-apps/node-env-override

# Build with NODE_VERSION override
s2i build . quay.io/centos7/nodejs-14-centos7:latest test-app-env \
  --environment NODE_VERSION=18.0.0

# Verify
podman run --rm test-app-env node --version
# Expected: v18.0.0
```

### Test with .nvmrc

```bash
cd test-apps/node-nvmrc

# Build (should read .nvmrc automatically)
s2i build . quay.io/centos7/nodejs-14-centos7:latest test-app-nvmrc

# Verify
podman run --rm test-app-nvmrc node --version
# Expected: v20.0.0 (or whatever is in .nvmrc)
```

## Debugging Failed Builds

### View Build Logs

```bash
# Build with verbose output
s2i build . quay.io/centos7/nodejs-14-centos7:latest test-app \
  --loglevel 5
```

### Inspect Intermediate Image

```bash
# Build without cleanup
s2i build . quay.io/centos7/nodejs-14-centos7:latest test-app \
  --pull-policy never \
  --scripts-url image:///usr/libexec/s2i

# List layers
podman history test-app

# Run interactive shell
podman run -it --entrypoint /bin/bash test-app
```

### Check Assemble Script Execution

Look for these log lines in build output:
```
---> Installing application source ...
NPM_VERSION_OVERRIDE: 14.17.0
---> Installing Node.js version 14.17.0
---> Node.js v14.17.0 and npm 6.14.13 installed
```

If version override isn't working, you'll see:
```
NPM_VERSION_OVERRIDE: 
```
(empty = parsing failed)

## Expected Failures

These tests should fail gracefully:

| Test | Failure Mode | Expected Behavior |
|------|--------------|-------------------|
| `node-invalid-version` | `"node": "invalid"` | Fallback to base version + warning |
| `node-unavailable` | `"node": "99.0.0"` | Build fails with clear error |
| `node-malformed-json` | Invalid package.json | Fallback to base version + warning |

## Performance Benchmarks

Track build times for each approach:

```bash
# Time the build
Measure-Command {
  s2i build . quay.io/centos7/nodejs-14-centos7:latest test-app
}

# Typical expectations:
# - No override: ~30s
# - nvm install: ~90s (network dependent)
# - fnm install: ~45s
# - Pre-installed: ~35s (version switch only)
```

## CI Integration

Add to GitHub Actions:

```yaml
name: Test Node.js Version Override

on: [push, pull_request]

jobs:
  test-version-override:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install S2I
        run: |
          curl -L https://github.com/openshift/source-to-image/releases/download/v1.3.0/source-to-image-v1.3.0-linux-amd64.tar.gz | tar xz
          sudo mv s2i /usr/local/bin/
      
      - name: Build base image
        run: make build TARGET=centos7 VERSIONS=14
      
      - name: Run tests
        run: ./run-tests.sh
```

## Troubleshooting

### Issue: Version parsing returns empty

**Symptom:** `NPM_VERSION_OVERRIDE:` (empty in logs)

**Causes:**
- package.json missing `engines.node`
- Malformed package.json
- sed parsing bug

**Fix:**
```bash
# Test parsing manually
podman run --rm -i quay.io/centos7/nodejs-14-centos7:latest bash -c '
  echo "{\"engines\":{\"node\":\"^14.0.0\"}}" > package.json
  node -e "console.log(require('./package.json').engines.node)"
'
```

### Issue: nvm install fails

**Symptom:** `curl: (6) Could not resolve host: raw.githubusercontent.com`

**Causes:**
- Network unreachable during build
- DNS issues in container

**Fix:**
- Use pre-installed versions (Solution 3)
- Add retry logic to assemble script
- Ensure build host has network access

### Issue: PATH not updated after nvm use

**Symptom:** `node --version` shows old version after `nvm use`

**Causes:**
- nvm not properly sourced
- PATH not exported in S2I context

**Fix:**
```bash
# Ensure proper sourcing
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 14.17.0

# Force PATH update
export PATH="$NVM_DIR/versions/node/v14.17.0/bin:$PATH"
```

## Next Steps

After validating fixes:

1. ✅ Document working version override patterns
2. ✅ Update s2i-nodejs-container README
3. ✅ Add CI tests to upstream repo
4. ✅ Submit PR with fixed assemble script
5. ✅ Benchmark performance improvements

## References

- [S2I Documentation](https://github.com/openshift/source-to-image)
- [nvm Repository](https://github.com/nvm-sh/nvm)
- [fnm Repository](https://github.com/Schniz/fnm)
- [Node.js Release Schedule](https://nodejs.org/en/about/releases/)
