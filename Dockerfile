# build docker-gen intermediate container
FROM golang:alpine AS build-docker-gen

LABEL stage=intermediate

## Install build dependencies for docker-gen
RUN apk add --update \
        curl \
        gcc \
        git \
        make \
        musl-dev

## Build docker-gen
RUN go get github.com/jwilder/docker-gen \
    && cd /go/src/github.com/jwilder/docker-gen \
    && git fetch --tags \
    && git -c advice.detachedHead=false checkout $(git describe --tags $(git rev-list --tags --max-count=1)) \
    && make get-deps \
    && make all

# build onionize container
FROM alpine:latest
MAINTAINER "Moritz Bartl <moritz@torservers.net>"

ENV DOCKER_HOST unix:///tmp/docker.sock

RUN apk -U --no-progress upgrade \
 && apk -U --no-progress add tor supervisor

## Copy docker-gen binary from build stage
COPY --from=build-docker-gen /go/src/github.com/jwilder/docker-gen/docker-gen /usr/local/bin/

COPY files/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY files/docker-gen/torrc.tmpl /app/torrc.tmpl
COPY files/torrc.minimal /etc/torrc

RUN mkdir -p /var/lib/tor/onion_services && \
    chown -R tor /var/lib/tor/onion_services

VOLUME ["/var/lib/tor/"]

ENTRYPOINT ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
