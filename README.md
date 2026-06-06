# s2i-nodejs-container

Node.js S2I builder images - organized by branch.

## Branches

| Branch | Node.js | npm | Tag | Status |
|--------|---------|-----|-----|--------|
| **node-24** | 24.16.0 | 11.5.x | v24.16.0 | **Latest LTS** |
| node-16 | 16.20.2 | 8.19.4 | v16.20.2 | LTS |
| node-14 | 14.21.3 | 6.14.18 | v14.21.3 | LTS (Maintenance) |

## Usage

```bash
git clone --branch node-24 https://github.com/fortinj66/s2i-nodejs-container.git
cd s2i-nodejs-container
make build TARGET=centos7 VERSIONS=24
```

## Configuration

Each branch contains a `config.json` with the default Node.js version.
