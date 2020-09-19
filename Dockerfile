FROM alpine:latest as builder
LABEL MAINTAINER="Rex Zeng <rex@rexskz.info>"

# Latest stable version
ARG OPENCC_VERSION="ver.1.0.5"
ARG GO_AVIF_VERSION="v0.1.0"
ARG AOM_VERSION="v1.0.0"

RUN apk add cmake doxygen g++ make git python3 \
    && cd /tmp && git clone https://github.com/BYVoid/OpenCC.git && cd OpenCC \
    && git checkout -b ${OPENCC_VERSION} \
    && make \
    && make install \
    && mkdir -p /usr/lib64 \
    && cp /usr/lib/libopencc.so /usr/lib64/libopencc.so \
    && apk del make doxygen cmake

FROM openresty/openresty:1.17.8.2-5-alpine

# COPY opencc binary
COPY --from=builder /usr/lib64 /usr/lib64
COPY --from=builder /usr/lib /usr/lib
COPY --from=builder /usr/share/opencc /usr/share/opencc
COPY --from=builder /usr/bin/opencc* /usr/bin/

# Set timezone
ENV TZ=Asia/Hong_Kong
RUN apk add tzdata \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && apk del tzdata

# avif and webp support
RUN apk add curl libwebp aom-dev \
    && curl https://github.com/Kagami/go-avif/releases/download/${GO_AVIF_VERSION}/avif-linux-x64 > /usr/bin/avif \
    && rm -rf /var/cache/apk/*
