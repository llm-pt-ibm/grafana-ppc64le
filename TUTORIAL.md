# Manual build tutorial — Grafana 13.1.0 on IBM POWER9 (ppc64le)

This document walks through the full manual compilation process used to build Grafana 13.1.0 natively on an IBM Power9 server. It is the step-by-step reference behind the automated [`Dockerfile`](./Dockerfile), useful if you want to understand exactly what happens during the build, reproduce it outside Docker, or adapt it for a different environment.

For day-to-day use (pulling the image or rebuilding via Docker), see the [README](./README.md) instead.

## Environment

| Component | Version |
|---|---|
| Hardware | IBM POWER9, ~128GB RAM, 16 CPUs |
| OS | AlmaLinux 8.10 (ppc64le), compatible with RHEL 8.9/8.10 |
| Grafana | 13.1.0 |
| GCC | 11.2.1 (Toolset 11) |
| Go | 1.26.5 |
| Node.js | 22.22.2 |
| npm | 10.9.7 |
| Yarn | 4.15.0 |
| Python | 3.11 |
| @swc/core | 1.15.40 |

Grafana 13 requires Node.js 22 or higher, and the project specifies Yarn as its package manager.

## Basic tools

```bash
sudo dnf install -y \
    git \
    gcc \
    gcc-c++ \
    make \
    curl \
    tar \
    xz \
    python3.11
```

To use GCC Toolset 11:

```bash
sudo dnf install -y gcc-toolset-11
```

Activate GCC 11:

```bash
export PATH=/opt/rh/gcc-toolset-11/root/usr/bin:$PATH
```

Verify the versions:

```bash
gcc --version
g++ --version
```

## Installing Go

The Go version used for the build was 1.26.5 for linux/ppc64le. Install and configure it:

```bash
cd /tmp

wget https://go.dev/dl/go1.26.5.linux-ppc64le.tar.gz

rm -rf /usr/local/go
tar -C /usr/local -xzf go1.26.5.linux-ppc64le.tar.gz

echo 'export PATH=/usr/local/go/bin:$PATH' >> /etc/profile
source /etc/profile
```

Verify:

```bash
go version
go env GOOS GOARCH
```

Expected output:

```
go1.26.5 linux/ppc64le
linux
ppc64le
```

## Node.js and Yarn

Install Node.js 22:

```bash
cd /tmp

wget https://nodejs.org/dist/v22.22.2/node-v22.22.2-linux-ppc64le.tar.xz

tar -xJf node-v22.22.2-linux-ppc64le.tar.xz
mv node-v22.22.2-linux-ppc64le /usr/local/node

echo 'export PATH=/usr/local/node/bin:$PATH' >> /etc/profile
source /etc/profile
```

The project uses Yarn 4.15.0:

```bash
npm install --global corepack
corepack enable
corepack prepare yarn@4.15.0 --activate
```

Verify:

```bash
node --version
npm --version
yarn --version
```

## Compiling Grafana

### 1. Get the source code

Clone the official repository:

```bash
git clone https://github.com/grafana/grafana.git
cd grafana
```

To reproduce the exact build used in this project:

```bash
git checkout v13.1.0
```

Verify the version:

```bash
git describe --tags --exact-match
```

### 2. `@swc/core` dependency fix

The `@swc/core` version originally pinned in Grafana's `package.json` (`1.13.3`) does not have a pre-compiled binary for `linux-ppc64le`. This doesn't produce an "unsupported architecture" error and the frontend build fails less directly, while trying to resolve the native dependency. The fix is updating to `1.15.40`, a version that ships a native ppc64le binary.

In `package.json`, change:

```
"@swc/core": "1.13.3"
```

to:

```
"@swc/core": "1.15.40"
```

Then update the dependencies:

```bash
yarn install
```

This refreshes `yarn.lock` accordingly.

### 3. Install Grafana's dependencies

With Node.js, Yarn, and Go configured:

```bash
make deps
```

This command installs the dependencies needed for both backend and frontend. In Grafana's official flow, JavaScript dependencies are installed through Yarn.

### 4. Compile Grafana

The build can be run directly with:

```bash
make build
```

This generates the Go backend and the frontend assets. Grafana's Makefile uses `build-go` for the backend and `build-js` for the frontend assets.

At the end, the binary can be found at:

```
bin/grafana
```

On Power9, the result should indicate:

```
ELF 64-bit LSB executable, 64-bit PowerPC
```

You can also verify the version:

```bash
./bin/grafana server -v
# Version 13.1.0
```

## Using the resulting binary directly (without Docker)

If you want to run the compiled binary as-is, without packaging it into a Docker image, `bin/grafana` is a self-contained executable. Run it from the Grafana source directory so it can find the `public/` and `conf/` folders alongside it:

```bash
./bin/grafana server
```

Grafana will be available on port 3000 by default.

## See also

- [README.md](./README.md) — quick start with the pre-built Docker image, and how to rebuild for a new Grafana version using the multi-stage `Dockerfile`.
- [Dockerfile](./Dockerfile) — the automated version of this same process.