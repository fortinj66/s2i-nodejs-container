#!/bin/bash
# Fixed assemble script for s2i-nodejs-container
# Replace 14/s2i/bin/assemble and 16/s2i/bin/assemble with this version

# Prevent running assemble in builders different than official STI image.
[ -d "/usr/src/app" ] && exit 0

set -e

safeLogging () {
    if [[ $1 =~ http[s]?://.*@.*$ ]]; then
        echo $1 | sed 's/^.*@/redacted@/'
    else
        echo $1
    fi
}

# Parse Node.js version from package.json with proper semver handling
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

# Check for .nvmrc file if no version specified
check_nvmrc() {
    if [ -f ".nvmrc" ]; then
        local nvmrc_version
        nvmrc_version=$(cat .nvmrc | tr -d '[:space:]')
        if [ -n "$nvmrc_version" ]; then
            echo "$nvmrc_version"
            return 0
        fi
    fi
    return 1
}

shopt -s dotglob
if [ -d /tmp/artifacts ] && [ "$(ls /tmp/artifacts/ 2>/dev/null)" ]; then
    echo "---> Restoring previous build artifacts ..."
    mv -T --verbose /tmp/artifacts/node_modules "${HOME}/node_modules"
fi

echo "---> Installing application source ..."
mv /tmp/src/* ./

# Fix source directory permissions
fix-permissions ./

# Determine Node.js version: env var > package.json engines > .nvmrc > base image
NODE_VERSION_TO_INSTALL=""

# Environment variable takes highest precedence
if [ -n "$NODE_VERSION" ]; then
    NODE_VERSION_TO_INSTALL="$NODE_VERSION"
    echo "---> Using Node.js version from NODE_VERSION env: $NODE_VERSION_TO_INSTALL"
elif NODE_VERSION_TO_INSTALL=$(parse_node_version); then
    echo "---> Using Node.js version from package.json engines: $NODE_VERSION_TO_INSTALL"
elif NODE_VERSION_TO_INSTALL=$(check_nvmrc); then
    echo "---> Using Node.js version from .nvmrc: $NODE_VERSION_TO_INSTALL"
else
    echo "---> No version override specified, using base image version $(node --version)"
fi

# Install requested version using nvm
if [ -n "$NODE_VERSION_TO_INSTALL" ]; then
    echo "---> Installing Node.js version $NODE_VERSION_TO_INSTALL"
    
    export NVM_DIR="$HOME/.nvm"
    
    # Install nvm silently (only if not already installed)
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        echo "---> Installing nvm..."
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | PROFILE=/dev/null bash
    fi
    
    # Load nvm
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    
    # Unset NPM_CONFIG_PREFIX to avoid conflicts
    unset NPM_CONFIG_PREFIX
    
    # Install and use requested version
    if ! nvm install "$NODE_VERSION_TO_INSTALL"; then
        echo "ERROR: Failed to install Node.js $NODE_VERSION_TO_INSTALL"
        echo "Falling back to base image version"
        NODE_VERSION_TO_INSTALL=""
    else
        nvm use "$NODE_VERSION_TO_INSTALL"
        nvm alias default "$NODE_VERSION_TO_INSTALL"
        echo "---> Node.js $(node --version) and npm $(npm --version) installed"
    fi
fi

# Configure npm proxy settings
if [ ! -z "$HTTP_PROXY" ]; then
    echo "---> Setting npm http proxy to $(safeLogging $HTTP_PROXY)"
    npm config set proxy $HTTP_PROXY
fi

if [ ! -z "$http_proxy" ]; then
    echo "---> Setting npm http proxy to $(safeLogging $http_proxy)"
    npm config set proxy $http_proxy
fi

if [ ! -z "$HTTPS_PROXY" ]; then
    echo "---> Setting npm https proxy to $(safeLogging $HTTPS_PROXY)"
    npm config set https-proxy $HTTPS_PROXY
fi

if [ ! -z "$https_proxy" ]; then
    echo "---> Setting npm https proxy to $(safeLogging $https_proxy)"
    npm config set https-proxy $https_proxy
fi

# Change the npm registry mirror if provided
if [ -n "$NPM_MIRROR" ]; then
    npm config set registry $NPM_MIRROR
fi

# Set the DEV_MODE to false by default.
if [ -z "$DEV_MODE" ]; then
  export DEV_MODE=false
fi

# If NODE_ENV is not set by the user, then NODE_ENV is determined by whether
# the container is run in development mode.
if [ -z "$NODE_ENV" ]; then
  if [ "$DEV_MODE" == true ]; then
    export NODE_ENV=development
  else
    export NODE_ENV=production
  fi
fi

if [ "$NODE_ENV" != "production" ]; then
    echo "---> Building your Node application from source"
    npm install
else
    echo "---> Installing all dependencies"
    NODE_ENV=development npm install
    
    #do not fail when there is no build script
    echo "---> Building in production mode"
    npm run build --if-present
    
    echo "---> Pruning the development dependencies"
    npm prune
    
    NPM_TMP=$(npm config get tmp)
    if ! mountpoint $NPM_TMP; then
        echo "---> Cleaning the $NPM_TMP/npm-*"
        rm -rf $NPM_TMP/npm-*
    fi
    
    # Clear the npm's cache and tmp directories only if they are not a docker volumes
    NPM_CACHE=$(npm config get cache)
    if ! mountpoint $NPM_CACHE; then
        echo "---> Cleaning the npm cache $NPM_CACHE"
        #As of npm@5 even the 'npm cache clean --force' does not fully remove the cache directory
        # instead of $NPM_CACHE* use $NPM_CACHE/*.
        # We do not want to delete .npmrc file.
        rm -rf "${NPM_CACHE:?}/"
    fi
fi

# Fix source directory permissions
fix-permissions ./
