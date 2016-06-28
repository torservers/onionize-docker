#!/bin/bash - 
set -e

# Warn if the DOCKER_HOST socket does not exist
if [[ $DOCKER_HOST == unix://* ]]; then
	socket_file=${DOCKER_HOST#unix://}
	if ! [ -S $socket_file ]; then
		cat >&2 <<-EOT
			ERROR: you need to share your Docker host socket with a volume at $socket_file
			Typically you should run your jheretic/onionboat with: \`-v /var/run/docker.sock:$socket_file:ro\`
			See the documentation at https://git.io/voqk1
		EOT
		socketMissing=1
	fi
fi

# If the user has run the default command and the socket doesn't exist, fail
if [ "$socketMissing" = 1 -a "$1" = '/usr/bin/supervisord' -a "$2" = '-c' -a "$3" = '/etc/supervisor/supervisord.conf' ]; then
	exit 1
fi

# Set permissions
mkdir -p /var/lib/tor/hidden_services && \
    chown -R debian-tor:debian-tor /var/lib/tor && \
    chmod -R u=rw,u+X,go= /var/lib/tor

touch /etc/torrc && \
    chown debian-tor:debian-tor /etc/torrc && \
    chmod 0600 /etc/torrc

exec "$@"
