FROM chambana/base:latest
MAINTAINER "Josh King <jking@chambana.net>"

ENV DOCKER_HOST unix:///tmp/docker.sock
ENV DOCKER_GEN_VERSION 0.7.1

EXPOSE 9001

ADD files/apt/tor.list /etc/apt/sources.list.d/tor.list
RUN gpg --keyserver keys.gnupg.net --recv 886DDD89 && \
    gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

RUN apt-get -qq update && \
    apt-get install -y --no-install-recommends ca-certificates \
                                               wget \
                                               supervisor \
                                               deb.torproject.org-keyring \
                                               tor && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup supervisord
ADD files/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# Install docker-gen
RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

ADD files/docker-gen/torrc.tmpl /app/torrc.tmpl

VOLUME ["/var/lib/tor/hidden_services"]

WORKDIR /app

## Add startup script.
ADD bin/run.sh /app/bin/run.sh
RUN chmod 0755 /app/bin/run.sh

ENTRYPOINT ["/app/bin/run.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
