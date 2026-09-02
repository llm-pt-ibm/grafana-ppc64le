# grafana-ppc64le

[Grafana](https://grafana.com/) is an open-source platform for data visualization and monitoring, widely used to create interactive dashboards from sources like Prometheus, Elasticsearch, and others.

This repository provides a native build of Grafana for IBM POWER9 (ppc64le), since the official project does not publish binaries for this architecture. IBM maintains official images on Docker Hub, but the latest versions are outdated. This project builds Grafana from source using a multi-stage Docker build, making it easy to upgrade without repeating the manual build process. See [Upgrading to a new version](#upgrading-to-a-new-version) below.

This work is part of the [Multi-Arch](#) project, a collaboration between UFCG, IBM, and Flex Brazil focused on porting, validating, and optimizing applications for ppc64le.

## Quick Start

Download the pre-built image:

```bash
docker pull ufcgibm/grafana-ppc64le:13.1.0-ppc64le

docker run -d \
  --name grafana-ppc64le \
  -p 3000:3000 \
  ufcgibm/grafana-ppc64le:13.1.0-ppc64le
```

Grafana will be available at `http://localhost:3000`.

## Building from Source

```bash
docker build -t ufcgibm/grafana-ppc64le:13.1.0-ppc64le .
```

## Upgrading to a New Version

When a new Grafana release is available, override the build args instead of repeating the manual steps from scratch:

```bash
docker build \
  --build-arg GRAFANA_VERSION=v13.2.0 \
  --build-arg SWC_CORE_VERSION=1.15.40 \
  -t ufcgibm/grafana-ppc64le:13.2.0-ppc64le .
```

The `SWC_CORE_VERSION` may also need to change — see [Known Issues](#known-issues).

## Build Environment

| Component | Version |
|---|---|
| Base image | almalinux:8 |
| GCC | Toolset 11 (11.2.1) |
| Go | 1.26.5 |
| Node.js | 22.22.2 |
| Yarn | 4.15.0 |
| Python | 3.11 |

Validated on an IBM Power9 server (ppc64le, 16 CPUs) running AlmaLinux 8.10.

## Known Issues

### `@swc/core` does not have a native binary for ppc64le in the version pinned by Grafana

Grafana's frontend build (Node.js + Yarn + Nx + Webpack) depends on `@swc/core`. The version pinned in Grafana's `package.json` at the time of this build (`1.13.3`) does not have a native binary for `linux-ppc64le`.

Fix: update to a version that does (`1.15.40` worked for Grafana 13.1.0) and update the lockfile with `yarn install`. The Dockerfile does this automatically via the `SWC_CORE_VERSION` build arg — check the [swc releases on GitHub](https://github.com/swc-project/swc/releases) if a future Grafana version requires a different value.

### Some built-in datasource plugins fail to start (expected)

During startup, logs may show errors like:

```
Could not start plugin backend" pluginId=elasticsearch error="fork/exec .../gpx_grafana_elasticsearch_datasource_linux_ppc64le: no such file or directory"
```

This is expected and does not indicate a broken build. Plugins such as Elasticsearch and Zipkin are distributed as separate pre-compiled binaries (they are not part of `make build`), and the official project only publishes these binaries for architectures like amd64/arm64, not ppc64le. Grafana logs the error but continues to function normally; core functionality (dashboards, Prometheus datasource, etc.) is not affected.

## Compatibility Matrix

| Grafana Version | Status | Notes |
|---|---|---|
| 13.1.0 | ✅ Validated | `@swc/core` updated to 1.15.40. `/api/health` confirmed OK. Built-in Elasticsearch/Zipkin plugins fail to start (expected, see Known Issues). |

## Disclaimer

This work is not an official release or software distribution by IBM, and is not developed or supported by IBM or Grafana Labs.

This work was developed by the Universidade Federal de Campina Grande (UFCG), a Brazilian public university, as part of a Research, Development, and Innovation project conducted in partnership with IBM and Flex Brazil.
