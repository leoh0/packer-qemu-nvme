FROM ubuntu:18.04 as qemu

RUN apt update && apt-get install -y \
    python \
    git \
    gcc \
    pkg-config \
    libglib2.0-dev \
    libpixman-1-dev \
    libaio-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

RUN git clone https://github.com/OpenChannelSSD/qemu-nvme.git \
    && cd qemu-nvme/ \
    && ./configure --python=/usr/bin/python2 --enable-kvm --static --target-list=x86_64-softmmu --enable-linux-aio --prefix=/opt/qemu/qemu-nvme \
    && make -j8

FROM golang:buster as packer

RUN go get github.com/mitchellh/gox
RUN go get github.com/hashicorp/packer

WORKDIR $GOPATH/src/github.com/hashicorp/packer

RUN XC_OS=linux XC_ARCH=amd64 /bin/bash scripts/build.sh

FROM ubuntu:18.04

RUN apt update && apt-get install -y \
    qemu \
    qemu-common \
    qemu-utils \
    qemu-system-x86 \
    qemu-system \
    qemu-kvm \
    && rm -rf /var/lib/apt/lists/*

COPY --from=qemu /work/qemu-nvme/x86_64-softmmu/qemu-system-x86_64 /usr/bin/qemu-system-nvme-x86_64
COPY --from=packer /go/bin/packer /usr/bin/packer

ENTRYPOINT ["/usr/bin/packer"]
