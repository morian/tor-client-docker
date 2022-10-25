## ALPINE_VER can be overwritten with --build-arg
## Pinned version tag from https://hub.docker.com/_/alpine
ARG ALPINE_VER=3.16

###########################
# First stage: build Tor from sources.
###########################
FROM alpine:${ALPINE_VER} AS builder

## TOR_VER can be overwritten with --build-arg at build time
## Default is the latest version with support for OnionV2.
ARG TOR_VER=0.4.7.10
ARG TOR_TAR=https://dist.torproject.org/tor-${TOR_VER}.tar.gz

## Install Tor build requirements.
RUN apk --no-cache add --update   \
      alpine-sdk                  \
      gnupg                       \
      libevent                    \
      libevent-dev                \
      openssl                     \
      openssl-dev                 \
      zlib                        \
      zlib-dev

## Build everything in a dedicated directory.
WORKDIR /build

## Get Tor source tarball file as well as its fingerprint and signature.
RUN wget ${TOR_TAR}                   \
 && wget ${TOR_TAR}.sha256sum         \
 && wget ${TOR_TAR}.sha256sum.asc

## Verify Tor source tarball fingerprint and signatures.
# This is performed using Nick Mathewson's key as well as the one from David Goulet.
RUN gpg --keyserver keys.openpgp.org --recv-keys 7A02B3521DC75C542BA015456AFEE6D49E92B601 \
 && gpg --keyserver keys.openpgp.org --recv-keys B74417EDDF22AC9F9E90F49142E86A2A11F48D36 \
 && gpg --verify tor-${TOR_VER}.tar.gz.sha256sum.asc tor-${TOR_VER}.tar.gz.sha256sum      \
 && sha256sum -c tor-${TOR_VER}.tar.gz.sha256sum

## Build and install Tor.
RUN tar xfz tor-${TOR_VER}.tar.gz \
 && cd tor-${TOR_VER}             \
 && ./configure                   \
      --prefix=/usr/              \
      --sysconfdir=/etc           \
      --localstatedir=/var        \
      --disable-html-manual       \
      --disable-manpage           \
      --disable-module-relay      \
      --disable-unittests         \
 && make install-strip


###########################
# Second stage: build the final container
###########################
FROM alpine:${ALPINE_VER} AS release

ARG TOR_HOME=/var/lib/tor

## Install Tor dependencies (binary files only).
RUN apk --no-cache add --update libevent openssl

## Create a Tor user for increased security.
RUN addgroup --gid 800 --system tor         \
 && adduser --uid 800 --system              \
            --gecos "Tor daemon"            \
            --home "${TOR_HOME}"            \
            --ingroup tor tor

COPY --from=builder /etc/tor/ /etc/tor/
COPY --from=builder /usr/bin/tor /usr/bin/tor
COPY --from=builder /usr/share/tor /usr/share/tor

RUN mkdir --mode=2755 /run/tor/   \
 && mkdir /etc/tor/torrc.d/       \
 && chown tor:tor /run/tor "${TOR_HOME}"
COPY ./conf/torrc /etc/tor/torrc

# Label the docker image.
LABEL name="Tor lightweight daemon container"
LABEL version=${TOR_VER}
LABEL url="https://www.torproject.org"

HEALTHCHECK --timeout=5s   \
  CMD echo PROTOCOLINFO | nc 127.0.0.1 9051 | grep -q '250 OK'
VOLUME ["/run/tor/", "${TOR_HOME}"]
EXPOSE 9050/tcp 9051/tcp
WORKDIR "${TOR_HOME}"
USER tor

CMD ["tor", "-f", "/etc/tor/torrc"]
