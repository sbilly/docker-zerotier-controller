FROM node:current-alpine as build-stage
LABEL Author="chang <lconly@gmail.com>"
LABEL Maintainer="chang <lconly@gmail.com>"

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories && \
    apk update && \
    apk add python3 alpine-sdk gcc wget git linux-headers libpq postgresql-dev bash jq

WORKDIR /src

# Prepaire Environment
COPY ./patch /src/patch
COPY ./config /src/config

# Downloading and build latest version ZeroTierOne
RUN echo 140.82.113.6                  api.github.com  >> /etc/hosts && \
    ZEROTIER_ONE_VERSION=`curl --silent "https://api.github.com/repos/zerotier/ZeroTierOne/releases" | jq -r ".[0].tag_name"` && \
    curl https://codeload.github.com/zerotier/ZeroTierOne/tar.gz/refs/tags/${ZEROTIER_ONE_VERSION} --output /tmp/ZeroTierOne.tar.gz && \
    mkdir -p /src && \
    cd /src && \
    tar fxz /tmp/ZeroTierOne.tar.gz && \
    mv /src/ZeroTierOne-* /src/ZeroTierOne && \
    rm -rf /tmp/ZeroTierOne.tar.gz && \
    cd /src/ && \
    python3 /src/patch/patch.py && \
    cd /src/ZeroTierOne && \
    make central-controller CPPFLAGS+=-w && \
    cd /src/ZeroTierOne/attic/world && \
    bash build.sh

FROM node:current-alpine

WORKDIR /app/ZeroTierOne

# ZeroTierOne
COPY --from=build-stage /src/ZeroTierOne/zerotier-one /app/ZeroTierOne/zerotier-one
RUN cd /app/ZeroTierOne && \
    ln -s zerotier-one zerotier-cli && \
    ln -s zerotier-one zerotier-idtool

# mkworld @ ZeroTierOne
COPY --from=build-stage /src/ZeroTierOne/attic/world/mkworld /app/ZeroTierOne/mkworld
COPY --from=build-stage /src/ZeroTierOne/attic/world/world.bin /app/config/world.bin
COPY --from=build-stage /src/config/world.c /app/config/world.c

# Envirment

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories && \
    apk update && \
    apk add libpq postgresql-dev postgresql jq curl bash wget && \
    mkdir -p /var/lib/zerotier-one/ && \
    ln -s /app/config/authtoken.secret /var/lib/zerotier-one/authtoken.secret

# Installing s6-overlay
RUN echo 140.82.113.6                  api.github.com  >> /etc/hosts && \
    echo 140.82.114.3                  github.com  >> /etc/hosts && \
    S6_OVERLAY_VERSION=`curl --silent "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | jq -r .tag_name` && \
    wget https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz -O /tmp/s6-overlay-amd64.tar.gz && \
    gunzip -c /tmp/s6-overlay-amd64.tar.gz | tar -xf - -C / && \
    rm -rf /tmp/s6-overlay-amd64.tar.gz

# s6-overlay
COPY ./s6-files/etc /etc/

# schema
COPY ./schema /app/schema/

EXPOSE 9993 9993/UDP
ENV S6_KEEP_ENV=1

ENTRYPOINT ["/init"]
CMD []