FROM centos:8 as build-stage

ENV NODE_OPTIONS=--openssl-legacy-provider
ENV NODE_VERSION=17.x
ENV ZEROTIER_ONE_VERSION=1.8.7
ENV LIBPQXX_VERSION=7.6.1

ENV PATCH_ALLOW=0
    
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://linuxsoft.cern.ch/centos-vault|g' /etc/yum.repos.d/CentOS-Linux-* && \
    echo -e 'deltarpm=0\ntimeout=300\nminrate=100' >> /etc/yum.conf

RUN curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo && \
    rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg && \
    curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION} | bash - && \
    dnf install -y nodejs yarn python3 wget git bash jq postgresql-devel curl gcc-c++ glibc-headers tar make diffutils patch cargo openssl-devel

WORKDIR /src

# Prepaire Environment
COPY ./patch /src/patch
COPY ./config /src/config

# Downloading and build latest libpqxx
RUN curl https://codeload.github.com/jtv/libpqxx/tar.gz/refs/tags/${LIBPQXX_VERSION} --output /tmp/libpqxx.tar.gz && \
    mkdir -p /src && \
    cd /src && \
    tar fxz /tmp/libpqxx.tar.gz && \
    mv /src/libpqxx-* /src/libpqxx && \
    rm -rf /tmp/libpqxx.tar.gz && \
    cd /src/libpqxx && \
    /src/libpqxx/configure --disable-documentation --with-pic && \
    make && \
    make install

# Downloading and build latest version ZeroTierOne
RUN curl https://codeload.github.com/zerotier/ZeroTierOne/tar.gz/refs/tags/${ZEROTIER_ONE_VERSION} --output /tmp/ZeroTierOne.tar.gz && \
    mkdir -p /src && \
    cd /src && \
    tar fxz /tmp/ZeroTierOne.tar.gz && \
    mv /src/ZeroTierOne-* /src/ZeroTierOne && \
    rm -rf /tmp/ZeroTierOne.tar.gz

RUN python3 /src/patch/patch.py

RUN cd /src/ZeroTierOne && \
    make central-controller CPPFLAGS+=-w && \
    cd /src/ZeroTierOne/attic/world && \
    bash build.sh

# Downloading and build latest tagged zero-ui
RUN ZERO_UI_VERSION=`curl --silent "https://api.github.com/repos/dec0dOS/zero-ui/tags" | jq -r '.[0].name'` && \
    curl https://codeload.github.com/dec0dOS/zero-ui/tar.gz/refs/tags/${ZERO_UI_VERSION} --output /tmp/zero-ui.tar.gz && \
    mkdir -p /src/ && \
    cd /src && \
    tar fxz /tmp/zero-ui.tar.gz && \
    mv /src/zero-ui-* /src/zero-ui && \
    rm -rf /tmp/zero-ui.tar.gz && \
    cd /src/zero-ui && \
    yarn install && \
    yarn installDeps && \
    yarn build

FROM centos:8

WORKDIR /app/ZeroTierOne

# libpqxx
COPY --from=build-stage /usr/local/lib/libpqxx.la /usr/local/lib/libpqxx.la
COPY --from=build-stage /usr/local/lib/libpqxx.a /usr/local/lib/libpqxx.a

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
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://linuxsoft.cern.ch/centos-vault|g' /etc/yum.repos.d/CentOS-Linux-* && \
    echo -e 'deltarpm=0\ntimeout=300\nminrate=100' >> /etc/yum.conf

RUN curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo && \
    rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg && \
    curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION} | bash - && \
    dnf update -y && \
    dnf module enable -y postgresql:10 && \
    dnf install -y nodejs yarn postgresql-server libpq wget git bash jq postgresql-devel tar gcc-c++ make xz openssl && \
    mkdir -p /var/lib/zerotier-one/ && \
    ln -s /app/config/authtoken.secret /var/lib/zerotier-one/authtoken.secret

# Installing s6-overlay
RUN S6_OVERLAY_VERSION=`curl --silent "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | jq -r .tag_name | sed 's/^v//'` && \
    cd /tmp && \
    curl --silent --location https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz --output s6-overlay-noarch-${S6_OVERLAY_VERSION}.tar.xz && \
    curl --silent --location https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz --output s6-overlay-x86_64-${S6_OVERLAY_VERSION}.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch-${S6_OVERLAY_VERSION}.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64-${S6_OVERLAY_VERSION}.tar.xz && \
    rm -f /tmp/*.xz

# Frontend @ zero-ui
COPY --from=build-stage /src/zero-ui/frontend/build /app/frontend/build/

# Backend @ zero-ui
WORKDIR /app/backend
COPY --from=build-stage /src/zero-ui/backend/package*.json /app/backend
RUN yarn install && \
    ln -s /app/config/world.bin /app/frontend/build/static/planet
COPY --from=build-stage /src/zero-ui/backend /app/backend

# s6-overlay
COPY ./s6-files/etc /etc/
RUN chmod +x /etc/services.d/*/run

# schema
COPY ./schema /app/schema/

EXPOSE 3000 4000 9993 9993/UDP
ENV S6_KEEP_ENV=1

ENTRYPOINT ["/init"]
CMD []
