# Quick Start: Test Node.js Version Override Locally

## Step 1: Clone Your Repository

```bash
cd C:\Users\forti\.openclaw\workspace
git clone https://github.com/fortinj66/s2i-nodejs-container.git
cd s2i-nodejs-container
git submodule update --init
```

## Step 2: Build Base Images

```bash
# Build Node.js 14 base image (CentOS 7)
make build TARGET=centos7 VERSIONS=14

# Build Node.js 16 base image (CentOS 7)  
make build TARGET=centos7 VERSIONS=16

# Verify images exist
podman images | grep nodejs
```

Expected output:
```
quay.io/centos7/nodejs-14-centos7   latest   <image-id>   <size>
quay.io/centos7/nodejs-16-centos7   latest   <image-id>   <size>
```

## Step 3: Run Test Framework

```bash
cd C:\Users\forti\.openclaw\workspace\s2i-nodejs-test

# Install S2I CLI (if not already installed)
choco install s2i -y

# Run all tests
.\run-tests.ps1 -BaseImage "quay.io/centos7/nodejs-14-centos7:latest"

# Or run a specific test
.\run-tests.ps1 -TestName node-14-exact -Verbose
```

## Step 4: Manual Testing (Alternative)

If you prefer manual testing without the test framework:

### Test A: package.json engines field

```bash
cd C:\Users\forti\.openclaw\workspace\s2i-nodejs-test\test-apps\node-14-exact

# Build with S2I
s2i build . quay.io/centos7/nodejs-14-centos7:latest test-14-exact

# Run and check version
podman run --rm test-14-exact node --version
# Expected: v14.17.0 (if fix is working)
# Actual: v14.x.x (base image version, if not working)
```

### Test B: Environment variable override

```bash
cd C:\Users\forti\.openclaw\workspace\s2i-nodejs-test\test-apps\node-env-override

# Build with NODE_VERSION override
s2i build . quay.io/centos7/nodejs-14-centos7:latest test-env-override \
  --environment NODE_VERSION=18.0.0

# Check version
podman run --rm test-env-override node --version
# Expected: v18.0.0 (if fix is working)
```

### Test C: .nvmrc file

```bash
cd C:\Users\forti\.openclaw\workspace\s2i-nodejs-test\test-apps\node-nvmrc

# Build (should read .nvmrc)
s2i build . quay.io/centos7/nodejs-14-centos7:latest test-nvmrc

# Check version
podman run --rm test-nvmrc node --version
# Expected: v20.0.0 (if fix is working)
```

## Step 5: Analyze Results

### If tests PASS ✓
The version override is working correctly. Next steps:
- Test with your actual applications
- Consider adding more version combinations
- Document working patterns

### If tests FAIL ✗
The current implementation has issues. Apply fixes from:
`C:\Users\forti\.openclaw\workspace\analysis\s2i-nodejs-fixes.md`

**Quick diagnostic:**
```bash
# Build with verbose logging
s2i build . quay.io/centos7/nodejs-14-centos7:latest test-debug --loglevel 5

# Look for these lines in output:
# NPM_VERSION_OVERRIDE: <version>  <- Should show parsed version
# ---> Installing Node.js version <version>  <- Should show install attempt
```

**Common failure modes:**

| Symptom | Cause | Fix |
|---------|-------|-----|
| `NPM_VERSION_OVERRIDE:` (empty) | Parsing failed | Fix sed commands or use node parser |
| `curl: Could not resolve host` | Network issue during nvm install | Use pre-installed versions |
| Version unchanged after install | PATH not updated | Fix nvm sourcing in assemble script |

## Step 6: Apply Fixes and Retest

After applying fixes to `s2i-nodejs-container/14/s2i/bin/assemble`:

```bash
# Rebuild base image with fixed assemble script
cd s2i-nodejs-container
make build TARGET=centos7 VERSIONS=14

# Retest
cd ..\s2i-nodejs-test
.\run-tests.ps1
```

## Expected Timeline

| Activity | Time |
|----------|------|
| Clone repo + init submodules | 2 min |
| Build base images (first time) | 15-30 min |
| Run test suite | 10-20 min |
| Apply fixes | 30 min |
| Rebuild + retest | 15-30 min |

**Total:** ~1.5-2 hours for first complete cycle

## Troubleshooting

### "make: *** No rule to make target 'common/common.mk'"
```bash
git submodule update --init
```

### "podman: command not found"
```bash
choco install podman -y
# OR use docker instead (update scripts accordingly)
```

### "s2i: command not found"
```bash
choco install s2i -y
# OR download manually from https://github.com/openshift/source-to-image/releases
```

### Build fails with permission errors on Windows
```bash
# Run PowerShell as Administrator
# Or adjust file permissions:
icacls test-apps /grant Users:F /T
```

### Network timeouts during nvm install
This is expected with the current broken implementation. It's one of the bugs we're testing for! After applying fixes (pre-installed versions), this should resolve.
