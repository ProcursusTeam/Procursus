FROM debian:latest

LABEL maintainer="1Conan <me@1conan.com>"

# tzdata asks for interation
ENV DEBIAN_FRONTEND noninteractive
ENV TARGET_SYSROOT /sdks/target
ENV MACOSX_SYSROOT /sdks/macosx
ENV RUSTUP_HOME /opt/rust
ENV CARGO_HOME /opt/rust
ENV PATH "/opt/rust/bin:${PATH}"

COPY scripts /tmp/

RUN mkdir -p /opt/rust/
COPY config/cargo-config /opt/rust/config

RUN bash /tmp/procursus_install.sh

RUN apt install -y \
  libssl-dev \
  libplist-dev \
  libxml2-dev \
  zlib1g-dev \
  liblzma-dev \
  libreadline-dev \
  nano vim

RUN bash /tmp/build_tapi.sh
RUN bash /tmp/build_cctools.sh
RUN bash /tmp/build_ldid.sh
RUN bash /tmp/build_wrapper.sh

RUN bash /tmp/install_rust.sh

RUN rm -rf /tmp && mkdir -p /tmp && chmod 777 /tmp
RUN apt-get clean

COPY darwin /usr/lib/llvm-11/lib/clang/11.0.1/lib/darwin
RUN mv /usr/local/include /usr/local/include.bk

WORKDIR /workspace/
