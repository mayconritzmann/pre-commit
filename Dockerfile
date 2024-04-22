FROM python:3.12-alpine

# Set environment variables to minimize image size and improve container security
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR /asdf

RUN adduser -s /bin/bash -h /asdf -D asdf

RUN apk add --virtual .asdf-deps --no-cache \
  bash \
  ca-certificates \
  curl \
  git \
  libc-dev \
  make \
  perl \
  unzip \
  && rm -rf /var/cache/apk/* \
  && find /usr/local -depth -type d -name '_pycache_' -exec rm -rf '{}' + \
  && rm -rf ~/.cache

SHELL ["/bin/bash", "-l", "-c"]

ENV PATH="${PATH}:/asdf/.asdf/shims:/asdf/.asdf/bin"

COPY --chown=asdf:asdf .tool-versions .
COPY --chown=asdf:asdf ./hack/add-tools.sh /installer/add-tools.sh

USER asdf

RUN git clone --depth 1 https://github.com/asdf-vm/asdf.git $HOME/.asdf && \
  echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc && \
  echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.profile && \
  source ~/.bashrc && \
  /installer/add-tools.sh

WORKDIR /code_validation

ONBUILD RUN /installer/add-tools.sh

CMD ["pre-commit", "--version"]
