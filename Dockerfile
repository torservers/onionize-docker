FROM alpine:latest
MAINTAINER "Moritz Bartl <moritz@torservers.net>"

ENV DOCKERGEN_VERSION 0.7.4

ENV DOCKER_HOST unix:///tmp/docker.sock

RUN apk -U --no-progress upgrade \
 && apk -U --no-progress add tor supervisor

ENV DOWNLOAD_URL https://github.com/jwilder/docker-gen/releases/download/$DOCKERGEN_VERSION/docker-gen-alpine-linux-amd64-$DOCKERGEN_VERSION.tar.gz
RUN wget -qO- $DOWNLOAD_URL | tar xvz -C /usr/local/bin

COPY files/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY files/docker-gen/torrc.tmpl /app/torrc.tmpl
COPY files/torrc.minimal /etc/torrc

RUN mkdir -p /var/lib/tor/onion_services && \
    chown -R tor /var/lib/tor/onion_services

VOLUME ["/var/lib/tor/"]

ENTRYPOINT ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
