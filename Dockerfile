# Multi-arch image (linux/amd64, linux/arm64). Arch is auto-detected at build time via uname -m (same pattern as remote-secret-syncer).
FROM cgr.dev/chainguard/wolfi-base:latest AS builder

ARG asdf_version

# Install dependencies (curl for downloading asdf binary; git required by asdf for plugins)
RUN apk add --no-cache \
    bash \
    curl \
    git \
    make \
    unzip \
    ca-certificates \
    python3 \
    py3-pip \
    perl

# Create non-root user
RUN adduser -D -s /bin/bash -h /home/asdf asdf
USER asdf
WORKDIR /installer

# Install asdf into standard location so we can copy to final stage
ENV ASDF_DIR="/home/asdf/.asdf" \
    ASDF_DATA_DIR="/home/asdf/.asdf" \
    PATH="/home/asdf/.asdf/shims:/home/asdf/.asdf/bin:$PATH"

# Copy version control and scripts
COPY --chown=asdf:asdf .tool-versions .
COPY --chown=asdf:asdf ./hack/add-tools.sh ./hack/entrypoint.sh .
RUN chmod +x add-tools.sh entrypoint.sh

# Download prebuilt asdf binary: auto-detect arch via uname -m (same pattern as remote-secret-syncer / kubectl)
RUN set -eu; \
    case "$(uname -m)" in \
        x86_64) ASDF_ARCH="amd64" ;; \
        aarch64|arm64) ASDF_ARCH="arm64" ;; \
        i386|386) ASDF_ARCH="386" ;; \
        *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    ASDF_VER="v${asdf_version#v}"; \
    mkdir -p /home/asdf/.asdf/bin; \
    curl -sSL "https://github.com/asdf-vm/asdf/releases/download/${ASDF_VER}/asdf-${ASDF_VER}-linux-${ASDF_ARCH}.tar.gz" | tar -xz -C /home/asdf/.asdf/bin; \
    chmod +x /home/asdf/.asdf/bin/asdf

# Pre-install plugins from image .tool-versions (PATH already has .asdf/bin)
RUN /installer/add-tools.sh .tool-versions

# ------------------------------------------------------------------------------------

FROM cgr.dev/chainguard/wolfi-base:latest

# Install only runtime essentials
RUN apk add --no-cache \
    python3 \
    py3-pip \
    curl \
    git \
    bash \
    make \
    ca-certificates \
    libatomic && \
    ln -sf python3 /usr/bin/python

# asdf environment
ENV ASDF_DATA_DIR="/home/asdf/.asdf"
ENV PATH="${ASDF_DATA_DIR}/shims:${ASDF_DATA_DIR}/bin:$PATH"

# Recreate non-root user
RUN adduser -D -s /bin/bash -h /home/asdf asdf
USER asdf
WORKDIR /home/asdf

# Copy asdf (with plugins) and scripts for client-side .tool-versions
COPY --from=builder --chown=asdf:asdf /home/asdf/.asdf /home/asdf/.asdf
COPY --from=builder /installer/add-tools.sh /installer/entrypoint.sh /installer/
# Profile: set asdf env and PATH for Go asdf (no asdf.sh — avoids NOTICE from old Bash impl)
USER root
RUN chown asdf:asdf /installer/add-tools.sh /installer/entrypoint.sh && chmod +x /installer/add-tools.sh /installer/entrypoint.sh && \
    printf '%s\n' 'export ASDF_DATA_DIR=/home/asdf/.asdf' 'export PATH="${ASDF_DATA_DIR}/shims:${ASDF_DATA_DIR}/bin:$PATH"' > /etc/profile.d/asdf.sh && chmod +x /etc/profile.d/asdf.sh

# GitLab CI and any bash child process get asdf in PATH
ENV BASH_ENV="/etc/profile.d/asdf.sh" \
    ENV="/etc/profile.d/asdf.sh" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER asdf
WORKDIR /code_validation

# Entrypoint: load asdf, install from client .tool-versions if present, then run command.
# When GitLab Runner invokes /bin/sh -c "script", we re-run the script in bash so BASH_ENV/profile apply (no before_script needed).
ENTRYPOINT ["/installer/entrypoint.sh"]

CMD ["pre-commit", "run", "--all-files", "--verbose", "--color", "always"]
