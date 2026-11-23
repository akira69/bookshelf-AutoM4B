FROM alpine:3.21 AS mp4v2

RUN apk add --no-cache build-base curl

RUN curl -fsSL https://github.com/enzo1982/mp4v2/releases/download/v2.1.3/mp4v2-2.1.3.tar.bz2 -o /tmp/mp4v2.tar.bz2 && \
    echo '033185c17bf3c5fdd94020c95f8325be2e5356558e3913c3d6547a85dd61f7f1  /tmp/mp4v2.tar.bz2' | sha256sum -c - && \
    tar -xjf /tmp/mp4v2.tar.bz2 -C /tmp && \
    cd /tmp/mp4v2-2.1.3 && \
    ./configure --prefix=/usr/local --disable-static --disable-debug && \
    make -j2 && make DESTDIR=/export install

RUN curl -fsSL https://github.com/sandreas/m4b-tool/releases/download/v0.5.2/m4b-tool.phar -o /export/m4b-tool.phar && \
    echo 'a3ea9b81a4e8ce10ecc85c1fc712c982ba2622f2ed0318fb558dadfad4a590fa  /export/m4b-tool.phar' | sha256sum -c -

FROM ghcr.io/linuxserver/baseimage-alpine:3.21

ARG TARGETPLATFORM

ENV XDG_CONFIG_HOME="/config/xdg" \
    COMPlus_EnableDiagnostics=0 \
    TMPDIR=/run/readarr-temp

RUN apk add -U --upgrade --no-cache \
    icu-libs \
    sqlite-libs \
    xmlstarlet \
    ffmpeg \
    php83 php83-curl php83-dom php83-fileinfo php83-intl php83-mbstring \
    php83-openssl php83-phar php83-simplexml php83-xml php83-xmlreader \
    php83-xmlwriter php83-zip && \
    ln -sf /usr/bin/php83 /usr/bin/php

COPY --from=mp4v2 /export/usr/local/bin/ /usr/local/bin/
COPY --from=mp4v2 /export/usr/local/lib/libmp4v2.so* /usr/local/lib/
COPY --from=mp4v2 /export/m4b-tool.phar /opt/m4b-tool/m4b-tool.phar
COPY docker/m4b-tool /usr/local/bin/m4b-tool
RUN chmod 755 /usr/local/bin/m4b-tool && m4b-tool --version

ARG GIT_BRANCH
ARG COMMIT_HASH
ARG BUILD_DATE
ARG METADATA_URL=https://api.bookinfo.pro
ARG HARDCOVER

LABEL maintainer="pennydreadful"

ENV METADATA_URL=${METADATA_URL}
ENV HARDCOVER=${HARDCOVER}

RUN mkdir -p /app/readarr

RUN --mount=type=bind,source=_output,target=_output \
    case "$TARGETPLATFORM" in \
    "linux/amd64") cp -r /_output/net6.0/linux-musl-x64 /app/readarr/bin ;; \
    "linux/arm64") cp -r /_output/net6.0/linux-musl-arm64 /app/readarr/bin ;; \
    "darwin/amd64") cp -r /_output/net6.0/osx-x64 /app/readarr/bin ;; \
    "darwin/arm64") cp -r /_output/net6.0/osx-arm64 /app/readarr/bin ;; \
    "windows/amd64") cp -r /_output/net6.0/win-x64 /app/readarr/bin ;; \
    *) echo "Unknown platform: $TARGETPLATFORM" && exit 1 ;; \
    esac; \
    cp -r /_output/UI /app/readarr/bin/UI

RUN echo -e "UpdateMethod=docker\nBranch=${GIT_BRANCH}\nPackageVersion=${COMMIT_HASH}}\nPackageAuthor=pennydreadful" > /app/readarr/package_info && \
    printf "version: ${COMMIT_HASH}}\nBuild-date: ${BUILD_DATE}" > /build_version

# copy local files
COPY docker/root/ /

# ports and volumes
EXPOSE 8787

VOLUME /config
