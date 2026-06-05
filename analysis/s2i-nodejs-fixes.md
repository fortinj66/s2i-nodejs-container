# Fixes for Node.js Version Selection in s2i-nodejs-container

## Problem Summary

The current implementation allows selecting Node.js/npm versions from package.json `engines.node` field, but it's unreliable due to:
- Fragile version parsing
- nvm installation during build (slow, insecure, unreliable)
- Incorrect environment variable precedence
- PATH propagation issues in S2I context

---

## Solution 1: Fix Current nvm Approach (Minimal Changes)

**File:** `14/s2i/bin/assemble` and `16/s2i/bin/assemble`

### Issues to Fix:

```bash
# CURRENT (BROKEN):
NPM_VERSION_OVERIDE_INTERNAL=$(node -e "console.log(require('./package.json').engines.node);" | \
    sed -e "s/[\^~]//g" |  sed -e "s/.\0//" | sed -e "s/undefined//")

NPM_VERSION_OVERIDE=${NPM_VERSION_OVERIDE_INTERNAL:-$NPM_VERSION_OVERIDE}
```

### Fixed Version:

```bash
# Parse engines.node from package.json with proper error handling
parse_node_version() {
    if [ ! -f "./package.json" ]; then
        return 1
    fi
    
    local version_spec
    version_spec=$(node -e "
        const pkg = require('./package.json');
        const spec = pkg.engines?.node || '';
        // Extract first version number from spec like '^14.17.0' or '>=14.0.0 <16.0.0'
        const match = spec.match(/(\d+)\.(\d+)\.?(\d*)/);
        if (match) {
            console.log(match[1] + '.' + match[2] + (match[3] ? '.' + match[3] : ''));
        }
    " 2>/dev/null)
    
    if [ -n "$version_spec" ] && [ "$version_spec" != "null" ]; then
        echo "$version_spec"
        return 0
    fi
    return 1
}

# Environment variable takes precedence, then package.json
if [ -z "$NPM_VERSION_OVERRIDE" ]; then
    NPM_VERSION_OVERRIDE=$(parse_node_version) || true
fi

if [ -n "$NPM_VERSION_OVERRIDE" ]; then
    echo "---> Installing Node.js version $NPM_VERSION_OVERRIDE"
    
    # Install nvm silently
    export NVM_DIR="$HOME/.nvm"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | PROFILE=/dev/null bash
    
    # Load nvm
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    
    # Install and use requested version
    unset NPM_CONFIG_PREFIX
    if ! nvm install "$NPM_VERSION_OVERRIDE"; then
        echo "ERROR: Failed to install Node.js $NPM_VERSION_OVERRIDE"
        exit 1
    fi
    
    nvm use "$NPM_VERSION_OVERRIDE"
    nvm alias default "$NPM_VERSION_OVERRIDE"
    
    # Verify installation
    echo "---> Node.js $(node --version) and npm $(npm --version) installed"
fi
```

### Key Improvements:
1. ✅ Proper semver parsing (handles `^`, `~`, ranges)
2. ✅ Error handling for missing package.json or engines field
3. ✅ Silent nvm install (no progress bar)
4. ✅ Sets nvm default alias
5. ✅ Version verification after install
6. ✅ Fixed variable name typo: `NPM_VERSION_OVERIDE` → `NPM_VERSION_OVERRIDE`

---

## Solution 2: Use fnm Instead of nvm (Recommended)

**Why fnm?**
- Faster (written in Rust)
- Single binary (no shell sourcing complexity)
- Better for CI/CD and containers
- Simpler PATH management

### Implementation:

```bash
# Add to Dockerfile (before COPY s2i/bin/)
RUN curl -fsSL https://github.com/Schniz/fnm/releases/download/v1.35.1/fnm-linux.zip \
    -o /tmp/fnm.zip && \
    unzip /tmp/fnm.zip -d /usr/local/bin/ && \
    rm /tmp/fnm.zip && \
    chmod +x /usr/local/bin/fnm

# Updated assemble script:
parse_node_version() {
    if [ ! -f "./package.json" ]; then
        return 1
    fi
    
    node -e "
        const pkg = require('./package.json');
        const spec = pkg.engines?.node || '';
        const match = spec.match(/(\d+)\.(\d+)\.?(\d*)/);
        if (match) {
            console.log(match[1] + '.' + match[2] + (match[3] ? '.' + match[3] : ''));
        }
    " 2>/dev/null
}

# Environment variable takes precedence, then package.json
if [ -z "$NODE_VERSION" ]; then
    NODE_VERSION=$(parse_node_version) || true
fi

if [ -n "$NODE_VERSION" ]; then
    echo "---> Installing Node.js version $NODE_VERSION"
    
    export FNM_DIR="$HOME/.fnm"
    mkdir -p "$FNM_DIR"
    
    # Install and use version
    if ! fnm install "$NODE_VERSION"; then
        echo "ERROR: Failed to install Node.js $NODE_VERSION"
        exit 1
    fi
    
    # Set up environment
    eval "$(fnm env)"
    fnm use "$NODE_VERSION"
    fnm default "$NODE_VERSION"
    
    echo "---> Node.js $(node --version) and npm $(npm --version) installed"
fi
```

---

## Solution 3: Multi-Version Base Images (Best for Production)

Instead of runtime version selection, pre-install multiple Node.js versions using SCL or nvm aliases, then select at build time:

### Dockerfile Changes:

```dockerfile
# Install multiple Node.js versions via SCL or nvm
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | PROFILE=/dev/null bash && \
    source $HOME/.nvm/nvm.sh && \
    nvm install 14 && \
    nvm install 16 && \
    nvm install 18 && \
    nvm install 20 && \
    nvm alias default 16 && \
    nvm cache clear

# Modify assemble to just switch versions
if [ -n "$NODE_VERSION" ]; then
    echo "---> Switching to Node.js $NODE_VERSION"
    source $HOME/.nvm/nvm.sh
    nvm use "$NODE_VERSION"
    echo "---> Using Node.js $(node --version)"
fi
```

### Benefits:
- ✅ No network calls during build
- ✅ Faster builds (versions pre-installed)
- ✅ More reliable (no curl failures)
- ✅ Can validate all versions at image build time

### Trade-offs:
- Larger base image (~200-300MB extra per version)
- Need to predetermine which versions to support

---

## Solution 4: Use Corepack for npm/yarn Version Management

For npm/yarn version selection (not Node.js itself):

```bash
# In Dockerfile
RUN corepack enable

# In assemble, after determining Node.js version:
if [ -f "./package.json" ]; then
    PACKAGE_MANAGER=$(node -e "
        const pkg = require('./package.json');
        const pm = pkg.packageManager;
        if (pm) {
            console.log(pm);
        }
    " 2>/dev/null || true)
    
    if [ -n "$PACKAGE_MANAGER" ]; then
        echo "---> Using package manager: $PACKAGE_MANAGER"
        corepack install --global "$PACKAGE_MANAGER"
    fi
fi
```

---

## Recommended Approach by Use Case

| Use Case | Recommended Solution |
|----------|---------------------|
| Quick fix, minimal changes | Solution 1 (fix current nvm) |
| Modern, reliable builds | Solution 2 (fnm) |
| Production, multi-version support | Solution 3 (pre-installed versions) |
| npm/yarn version control only | Solution 4 (corepack) |

---

## Additional Recommendations

### 1. Add Version Validation

```bash
validate_version() {
    local version="$1"
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "ERROR: Invalid Node.js version format: $version"
        echo "Expected format: MAJOR.MINOR.PATCH (e.g., 14.17.0)"
        return 1
    fi
    return 0
}
```

### 2. Support .nvmrc Files

```bash
# Check for .nvmrc if no engines.node
if [ -z "$NODE_VERSION" ] && [ -f ".nvmrc" ]; then
    NODE_VERSION=$(cat .nvmrc | tr -d '[:space:]')
    echo "---> Using Node.js version from .nvmrc: $NODE_VERSION"
fi
```

### 3. Add Fallback Logic

```bash
# If requested version fails, fall back to base image version
if [ -n "$NODE_VERSION" ]; then
    BASE_VERSION=$(node --version | sed 's/^v//')
    if ! install_node "$NODE_VERSION"; then
        echo "WARNING: Failed to install Node.js $NODE_VERSION"
        echo "Falling back to base image version $BASE_VERSION"
        NODE_VERSION="$BASE_VERSION"
    fi
fi
```

### 4. Documentation Updates

Update README.md to document:
- How to specify Node.js version (env var, package.json, .nvmrc)
- Supported version formats
- Fallback behavior
- Troubleshooting steps

---

## Example package.json Configurations

```json
{
  "name": "my-app",
  "version": "1.0.0",
  "engines": {
    "node": "16.13.0",
    "npm": "8.1.0"
  }
}
```

```json
{
  "name": "my-app",
  "version": "1.0.0",
  "engines": {
    "node": ">=14.0.0 <17.0.0"
  },
  "packageManager": "yarn@3.2.0"
}
```

```bash
# Or use .nvmrc file:
echo "16.13.0" > .nvmrc
```

```bash
# Or set environment variable in BuildConfig:
env:
  - name: NODE_VERSION
    value: "16.13.0"
```

---

## Testing Checklist

After implementing fixes:

- [ ] Test with exact version in package.json (`"node": "16.13.0"`)
- [ ] Test with semver range (`"node": "^14.0.0"`)
- [ ] Test with missing engines field (should use base version)
- [ ] Test with missing package.json (should use base version)
- [ ] Test with invalid version (should fail gracefully)
- [ ] Test with .nvmrc file
- [ ] Test with NODE_VERSION environment variable
- [ ] Test proxy configuration still works
- [ ] Test production vs development mode
- [ ] Test build artifact caching still works
