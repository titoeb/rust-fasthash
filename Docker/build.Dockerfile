FROM ubuntu:16.04

# Setup dev environment to be able to build fasthash.
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.59.0

RUN apt-get update \
    && apt-get upgrade \
    && apt-get install --yes build-essential software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
    && apt-get update -y \
    && apt-get upgrade --yes \
    && apt-get install --yes gcc-6 g++-6 wget xz-utils 

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
    amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338' ;; \
    armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='67777ac3bc17277102f2ed73fd5f14c51f4ca5963adadf7f174adf4ebc38747b' ;; \
    arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='32a1532f7cef072a667bac53f1a5542c99666c4071af0c9549795bbdb2069ec1' ;; \
    i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='e50d1deb99048bc5782a0200aa33e4eea70747d49dffdc9d06812fd22a372515' ;; \
    *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.24.3/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

## Built fasthash
ENV CC=gcc-6 \
    CXX=g++-6 \
    CFLAGS=-lgcc \
    LLVM_VERSION=6.0 \
    RUST_BACKTRACE=full \
    RUSTFLAGS="-C target-cpu=native"

WORKDIR /rust-fasthash
COPY .travis/before_install.sh /rust-fasthash/.travis/
RUN .travis/before_install.sh llvm 

COPY Cargo.toml /rust-fasthash/
COPY fasthash /rust-fasthash/fasthash
COPY fasthash-sys /rust-fasthash/fasthash-sys-fork

ENV LLVM_CONFIG_PATH=root/llvm/bin/llvm-config

RUN cargo update