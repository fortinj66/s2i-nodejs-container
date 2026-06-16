# Contributing to s2i-nodejs-container

Thank you for contributing. This document covers everything you need to build, test, and submit changes to this repository.

---

## Table of Contents

1. [Clone and Set Up](#1-clone-and-set-up)
2. [Branch Naming Convention](#2-branch-naming-convention)
3. [Build an Image Locally](#3-build-an-image-locally)
4. [Run the Tests](#4-run-the-tests)
5. [Submit a Pull Request](#5-submit-a-pull-request)
6. [Create a New Node.js Version Branch](#6-create-a-new-nodejs-version-branch)

---

## 1. Clone and Set Up

```bash
git clone https://github.com/fortinj66/s2i-nodejs-container.git
cd s2i-nodejs-container
```

**Prerequisites:**

| Tool | Purpose |
|------|---------|
| `git` | Version control |
| `podman` or `docker` | Build and run container images |
| `bash` | Run S2I scripts and test suite |
| `make` | Build targets (optional; wraps podman/docker commands) |

No additional language runtimes or package managers are required on the host. Node.js runs inside the container.

---

## 2. Branch Naming Convention

Each branch tracks a single Node.js LTS version:

```
node-<MAJOR>
```

Examples:

| Branch | Node.js version |
|--------|----------------|
| `node-14` | Node.js 14 LTS |
| `node-24` | Node.js 24 LTS |

**Rules:**

- Branch from the previous LTS branch when creating a new version (see [Section 6](#6-create-a-new-nodejs-version-branch)).
- Do not commit cross-version changes to a single branch.
- `master` is the integration branch; version branches are the primary development targets.
- Feature branches for a specific version: `node-<MAJOR>/<short-description>` (e.g., `node-24/fix-assemble-tmp`).

---

## 3. Build an Image Locally

### Using `make`

```bash
# Build all supported targets for the current branch
make build
```

The `Makefile` reads `VERSIONS` (set to the Node.js major version for this branch) and `BASE_IMAGE_NAME`.

### Using `podman` or `docker` directly

```bash
# RHEL 9 / UBI 9 (primary supported target)
podman build -f Dockerfile.rhel9 -t s2i-nodejs-24:local .

# CentOS Stream 9
podman build -f Dockerfile.c9s -t s2i-nodejs-24-c9s:local .

# RHEL 8 / UBI 8 (legacy; excluded from active CI)
podman build -f Dockerfile.rhel8 -t s2i-nodejs-24-rhel8:local .
```

**Excluded targets** — the following Dockerfiles are present in the repository but excluded from active builds (see `.exclude-*` sentinel files). Do not submit changes targeting these:

| Dockerfile | Reason excluded |
|------------|----------------|
| `Dockerfile` | CentOS 7 origin — EOL |
| `Dockerfile.rhel7` | RHEL 7 — EOL |
| `Dockerfile.fedora` | Fedora 35 base — EOL |

### Verify the built image

```bash
podman run --rm s2i-nodejs-24:local node --version   # expect: v24.x
podman run --rm s2i-nodejs-24:local npm --version    # expect: 10.x or later
```

---

## 4. Run the Tests

### Bash syntax check (no container required)

Verify all S2I scripts are syntactically valid:

```bash
bash -n s2i/bin/assemble s2i/bin/run s2i/bin/usage s2i/bin/save-artifacts
```

A clean run produces no output and exits 0.

### Static string checks (no container required)

```bash
# NODEJS_VERSION must be set to the correct major in all active Dockerfiles
grep "NODEJS_VERSION=" Dockerfile.rhel9 Dockerfile.c9s Dockerfile.rhel8

# npm config get tmp must not appear in assemble (removed in npm v7+)
grep -c "npm config get tmp" s2i/bin/assemble   # must return 0

# No residual old-version strings in README or usage
grep "nodejs-16\|nodejs:16" README.md s2i/bin/usage   # must return nothing
```

### Black-box acceptance test suite

The full acceptance test suite is located at:

```
crew/state/s2i-node24-fix-bb-tests.sh
```

Run it from the repository root:

```bash
bash crew/state/s2i-node24-fix-bb-tests.sh
# or with an explicit repo path:
bash crew/state/s2i-node24-fix-bb-tests.sh /path/to/s2i-nodejs-container
```

**Expected result:** `PASS=51 FAIL=0 SKIP=0` (or `SKIP=4` if no container runtime is available — runtime tests are skipped automatically when `podman`/`docker` is absent).

### Runtime / smoke tests (container runtime required)

```bash
IMAGE=s2i-nodejs-24:local
podman build -f Dockerfile.rhel9 -t $IMAGE .
podman run --rm $IMAGE node --version    # must start with v24.
podman run --rm $IMAGE npm --version     # must be 10.x or later
```

> **Note on short-name resolution:** If `podman` requires interactive TTY confirmation for short-name image pulls (common in non-interactive/CI environments), prefix the build with the full registry path or configure `/etc/containers/registries.conf` to add `docker.io` and `registry.access.redhat.com` to the unqualified search list.

### CI (GitHub Actions)

The workflow at `.github/workflows/build-test.yml` runs automatically on push and pull request to `node-24`. It covers:

- Bash syntax check on all S2I scripts
- Static checks: `NODEJS_VERSION`, `npm config get tmp` absence, no `nodejs-16` residuals
- Container build + smoke tests (marked `continue-on-error: true` for environments without a container runtime)

---

## 5. Submit a Pull Request

1. **Branch from the correct version branch:**
   ```bash
   git checkout node-24
   git pull origin node-24
   git checkout -b node-24/my-fix
   ```

2. **Make your changes.** Follow the file scope rules in [Section 6](#6-create-a-new-nodejs-version-branch) — only touch files relevant to your change.

3. **Run the full test suite before pushing** (see [Section 4](#4-run-the-tests)):
   - `bash -n` on all S2I scripts — must pass
   - Black-box test suite — must return 0 FAILs
   - If you have a container runtime: build and smoke-test the image

4. **Commit with a clear message:**
   ```
   fix: <short description>

   - What changed and why
   - Which files were modified
   - Reference to spec or issue if applicable
   ```

5. **Push and open a PR** targeting the correct version branch (`node-24`, not `master`):
   ```bash
   git push origin node-24/my-fix
   ```
   Then open a pull request from `node-24/my-fix` → `node-24`.

6. **In the PR description:**
   - Summarise what changed and why
   - List the files modified
   - Paste or link the bb-test output showing 0 FAILs
   - Reference any spec document or issue number

---

## 6. Create a New Node.js Version Branch

When a new Node.js LTS version is released, create a new branch from the most recent existing version branch.

### Step 1 — Create the branch

```bash
# Example: branching node-26 from node-24
git checkout node-24
git pull origin node-24
git checkout -b node-26
```

### Step 2 — Update every file in this checklist

Work through each file below. Do not skip any. Do not change `NODEJS_VERSION` in Dockerfiles manually — it is set via build args or environment; verify it is already correct before proceeding.

---

#### `Dockerfile.rhel9`

| String to find | Replace with |
|----------------|-------------|
| `CNB_STACK_ID=com.redhat.stacks.ubi9-nodejs-24` | `CNB_STACK_ID=com.redhat.stacks.ubi9-nodejs-26` |
| `io.buildpacks.stack.id="com.redhat.stacks.ubi9-nodejs-24"` | `io.buildpacks.stack.id="com.redhat.stacks.ubi9-nodejs-26"` |

Verify: `grep "CNB_STACK_ID\|io.buildpacks.stack.id" Dockerfile.rhel9`

---

#### `Dockerfile.c9s`

| String to find | Replace with |
|----------------|-------------|
| `CNB_STACK_ID=com.redhat.stacks.c9s-nodejs-24` | `CNB_STACK_ID=com.redhat.stacks.c9s-nodejs-26` |
| `io.buildpacks.stack.id="com.redhat.stacks.c9s-nodejs-24"` | `io.buildpacks.stack.id="com.redhat.stacks.c9s-nodejs-26"` |

Verify: `grep "CNB_STACK_ID\|io.buildpacks.stack.id" Dockerfile.c9s`

---

#### `Dockerfile.rhel8`

| String to find | Replace with |
|----------------|-------------|
| `CNB_STACK_ID=com.redhat.stacks.ubi8-nodejs-24` | `CNB_STACK_ID=com.redhat.stacks.ubi8-nodejs-26` |
| `io.buildpacks.stack.id="com.redhat.stacks.ubi8-nodejs-24"` | `io.buildpacks.stack.id="com.redhat.stacks.ubi8-nodejs-26"` |

> Note: `Dockerfile.rhel8` is excluded from active CI (`.exclude-rhel8`). Update the labels for static correctness even though the file is not built.

---

#### `s2i/bin/usage`

| String to find | Replace with |
|----------------|-------------|
| `nodejs-24` (in the heredoc description line) | `nodejs-26` |
| `24/test/test-app/` (in the `s2i build` example) | `26/test/test-app/` |
| `nodejs-24-${DISTRO}` (in the image name argument) | `nodejs-26-${DISTRO}` |

Verify no residuals: `grep "nodejs-24" s2i/bin/usage` — must return nothing.
Syntax check: `bash -n s2i/bin/usage`

---

#### `s2i/bin/assemble`

No version string changes required. However, verify the `npm config get tmp` block is absent — it must have been removed when branching from `node-24`. If it is present (e.g., branching from an older base), remove it:

```bash
# Block to remove (if present):
NPM_TMP=$(npm config get tmp)
if ! mountpoint $NPM_TMP; then
    echo "---> Cleaning the $NPM_TMP/npm-*"
    rm -rf $NPM_TMP/npm-*
fi
```

The `npm config get cache` block immediately below it is valid — preserve it.

Syntax check: `bash -n s2i/bin/assemble`

---

#### `README.md`

| String to find | Replace with |
|----------------|-------------|
| `NodeJS 24 container image` (title) | `NodeJS 26 container image` |
| `Node.JS 24` (prose) | `Node.JS 26` |
| `Node.js 24` (prose) | `Node.js 26` |
| `nodejs-24` (all occurrences) | `nodejs-26` |
| `nodejs:24` (imagestream refs) | `nodejs:26` |
| `ubi9/nodejs-24` (all occurrences) | `ubi9/nodejs-26` |
| `FROM ubi9/nodejs-24` (Dockerfile examples) | `FROM ubi9/nodejs-26` |

Verify no residuals: `grep "nodejs-24\|nodejs:24\|ubi9/nodejs-24" README.md` — must return nothing.

---

#### `cccp.yml`

| String to find | Replace with |
|----------------|-------------|
| `job-id: nodejs-24-c9s` | `job-id: nodejs-26-c9s` |

Verify: `cat cccp.yml`

---

#### `config.json`

Update the version metadata:

```json
{
  "nodejsVersion": "26",
  "defaultNpmVersion": "bundled",
  "description": "Node.js 26 LTS (<codename>)"
}
```

---

#### `Makefile`

| String to find | Replace with |
|----------------|-------------|
| `VERSIONS = 24` | `VERSIONS = 26` |

---

#### `.github/workflows/build-test.yml`

| String to find | Replace with |
|----------------|-------------|
| `node-24` (branch triggers, 2 occurrences) | `node-26` |
| `NODEJS_VERSION=24` (static check) | `NODEJS_VERSION=26` |

Verify: `grep "node-24\|NODEJS_VERSION=24" .github/workflows/build-test.yml` — must return nothing.

---

### Step 3 — Verify the full checklist

```bash
# No residual old-version strings anywhere
grep -r "nodejs-24\|nodejs:24\|ubi9/nodejs-24\|node-24" \
  Dockerfile.rhel9 Dockerfile.c9s Dockerfile.rhel8 \
  s2i/bin/usage README.md cccp.yml config.json Makefile \
  .github/workflows/build-test.yml

# Bash syntax
bash -n s2i/bin/assemble s2i/bin/run s2i/bin/usage s2i/bin/save-artifacts

# Build and smoke test
podman build -f Dockerfile.rhel9 -t s2i-nodejs-26:local .
podman run --rm s2i-nodejs-26:local node --version   # expect: v26.x
podman run --rm s2i-nodejs-26:local npm --version    # expect: 10.x or later
```

### Step 4 — Commit and push

```bash
git add -A
git commit -m "feat: Node.js 26 branch - single version structure"
git push origin node-26
```

### Step 5 — Open a PR

Open a pull request from `node-26` → `master` (or the appropriate integration branch). Reference this checklist in the PR description and include the output of the smoke tests.

---

## Questions?

Open an issue or reach out via the project's standard communication channels.
