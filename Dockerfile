# syntax=docker/dockerfile:1

############################
# 1) Build obfs4proxy from source
############################
FROM golang:1.26-alpine AS obfs4-build

ARG OBFS4_REPO=https://github.com/Yawning/obfs4.git
ARG OBFS4_REF=master

RUN apk add --no-cache git build-base

WORKDIR /src/obfs4
RUN git clone --depth 1 ${OBFS4_REPO} . \
 && git fetch --depth 1 origin ${OBFS4_REF} \
 && git checkout -q FETCH_HEAD

RUN cd obfs4proxy && \
    go build -trimpath -ldflags="-s -w" -o /out/obfs4proxy .

############################
# 2) Runtime image with Tor
############################
FROM alpine:3.20

RUN apk add --no-cache \
      tor \
      su-exec \
      ca-certificates \
      tzdata \
      vim \
      iputils

COPY --from=obfs4-build /out/obfs4proxy /usr/bin/obfs4proxy

RUN mkdir -p /var/lib/tor /var/log/tor /etc/tor \
 && chown -R tor:tor /var/lib/tor /var/log/tor /etc/tor \
 && chmod 700 /var/lib/tor \
 && chmod 0755 /usr/bin/obfs4proxy

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# SOCKS (example in README uses 9050), DNS (9053)
EXPOSE 9050 9053

# torrc must be provided (volume mount) at /etc/tor/torrc
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["tor", "-f", "/etc/tor/torrc"]