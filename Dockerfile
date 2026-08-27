# ---------------------------------------------------------------------------
# Stage 1 — Builder
# Compiles Grafana from source natively for ppc64le.
# To build a new Grafana version, just override GRAFANA_VERSION:
#   docker build --build-arg GRAFANA_VERSION=v0.13.2 -t ufcgibm/grafana-ppc64le:0.13.2-ppc64le .
# ---------------------------------------------------------------------------
FROM almalinux:8 AS builder

ARG GRAFANA_VERSION=v13.1.0
ARG GO_VERSION=1.26.5
ARG NODE_VERSION=22.22.2
ARG YARN_VERSION=4.15.0
ARG SWC_CORE_VERSION=1.15.40

RUN dnf install -y \
        git \
        gcc \
        gcc-c++ \
        gcc-toolset-11 \
        make \
        curl \
        tar \
        xz \
        python3.11 \
    && dnf clean all

ENV GCC_TOOLSET_HOME=/opt/rh/gcc-toolset-11/root/usr
ENV PATH="/usr/local/node/bin:/usr/local/go/bin:${GCC_TOOLSET_HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin"
ENV LD_LIBRARY_PATH="${GCC_TOOLSET_HOME}/lib64:${GCC_TOOLSET_HOME}/lib"
ENV CC="${GCC_TOOLSET_HOME}/bin/gcc"
ENV CXX="${GCC_TOOLSET_HOME}/bin/g++"
ENV PYTHON=/usr/bin/python3.11

# Cache locations — set explicitly so Go/Yarn/Corepack don't fall back to
# a $HOME that may not be writable inside the container.
ENV GOPATH=/opt/grafana-build/go
ENV GOMODCACHE=/opt/grafana-build/go/pkg/mod
ENV GOCACHE=/opt/grafana-build/go-cache
ENV COREPACK_HOME=/opt/grafana-build/corepack
ENV YARN_CACHE_FOLDER=/opt/grafana-build/yarn-cache

# Go
RUN curl -fsSL -o /tmp/go.tar.gz \
        "https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz" \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz

# Node.js + Yarn (via Corepack)
RUN curl -fsSL -o /tmp/node.tar.xz \
        "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.xz" \
    && tar -xJf /tmp/node.tar.xz -C /tmp \
    && mv /tmp/node-v${NODE_VERSION}-linux-ppc64le /usr/local/node \
    && rm /tmp/node.tar.xz \
    && npm install --global corepack \
    && corepack enable \
    && corepack prepare "yarn@${YARN_VERSION}" --activate

# --- Grafana source ---
WORKDIR /src
RUN git clone --depth 1 --branch ${GRAFANA_VERSION} https://github.com/grafana/grafana.git

WORKDIR /src/grafana

# Known gotcha: the @swc/core version pinned upstream may not ship a
# native binary for linux-ppc64le. Force a version that does, then
# refresh the lockfile.
RUN sed -i "s/\"@swc\\/core\": \".*\"/\"@swc\\/core\": \"${SWC_CORE_VERSION}\"/" package.json \
    && yarn install

RUN make deps
RUN make build

# Sanity check: fail the build early if the binary isn't a ppc64le ELF.
RUN file ./bin/grafana | grep -q "64-bit PowerPC" \
    && ./bin/grafana server -v

# ---------------------------------------------------------------------------
# Stage 2 — Runtime
# ---------------------------------------------------------------------------
FROM almalinux:8

RUN dnf install -y \
        ca-certificates \
        tzdata \
    && dnf clean all

WORKDIR /usr/share/grafana

COPY --from=builder /src/grafana/bin/grafana /usr/share/grafana/bin/grafana
COPY --from=builder /src/grafana/public /usr/share/grafana/public
COPY --from=builder /src/grafana/conf /usr/share/grafana/conf

RUN chmod +x /usr/share/grafana/bin/grafana

EXPOSE 3000
CMD ["/usr/share/grafana/bin/grafana", "server"]
