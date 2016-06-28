# Onionboat
A docker wrapper for [Tor](https://torproject.org) hidden services. It uses [docker-gen](https://github.com/jwilder/docker-gen) to configure Tor automatically when other containers are connected to the same network. The advantage of this approach is that it allows for optional network isolation and doesn't require building any containers yourself.

## Usage
*Excerpted from https://nonconformity.net/2016/06/10/onionboat-using-docker-for-easy-tor-hidden-services/*

I created Onionboat as a take on the kind of thing that [nginx-proxy](https://github.com/jwilder/nginx-proxy) does, but applied to hidden services. Onionboat is a Docker container that not only installs and runs Tor, but will automatically configure Tor to expose other Docker containers as hidden services. **Warning: this solution hasn't been security audited, and is posted as a fun experiment. The overall security of Docker containers and isolation of their networks is likely to vary based on your Linux distribution.**

To try it (assuming you have Docker installed on your Linux box; I haven't tried it on other systems), just run the Onionboat container:

`docker run --name onionboat -d -p 9001:9001 -v /var/run/docker.sock:/tmp/docker.sock:ro jheretic/onionboat`

This will download the Onionboat image and create a running container instance from it called `onionboat`. Now you'll want to create an isolated network that doesn't have access to the internet for your services to reside in:

`docker network create -o "com.docker.network.bridge.enable_ip_masquerade=false" faraday`

This created a network called `faraday` that has IP masquerading disabled, meaning it won't be able to access the internet. Now attach `faraday` to the running `onionboat` container:

`docker network connect faraday onionboat`

Now the `onionboat` container is connected to two networks: the default docker bridge providing internet connectivity, and the isolated `faraday` network where we'll start our services. For the purposes of this tutorial, we'll use the stock nginx image just so it's easy to see it working. Start an nginx instance connected to the `faraday` network with a special environment variable:

`docker run -d --net faraday -e HIDDENSERVICE_NAME=nginx nginx`

The environment variable `HIDDENSERVICE_NAME` is read by `docker-gen` running in the `onionboat` container, which according to its template identifies it as something that should be added to the list of hidden services in `torrc`. It automatically uses whichever port is exposed by the container by default; if there's more than one, it uses port 80 by default but that behavior can be overridden by specifying a `HIDDENSERVICE_PORT` environment variable as well. Containers specifying the same `HIDDENSERVICE_NAME` are added to the same service. In this way, you can have multiple different containers providing services on different ports of the same .onion address. To see if it worked and to find out what .onion address was assigned, you can execute the following command:

`docker exec onionboat cat /var/lib/tor/hidden_services/<HIDDENSERVICE_NAME>/hostname`

Where `<HIDDENSERVICE_NAME>` is replaced with the name you provided in the environment variable. This should print out a long hash followed by .onion, for instance (a fake example):

`m44Fr7zzjYuDvQmQfvwXRhCS.onion`

Now if you open the [Tor browser](https://www.torproject.org/download/download-easy.html.en) and paste the .onion address into the address bar, you should see the default nginx page:

![default_page](https://nonconformity.net/content/images/2016/06/default_page.png)

Awesome! But the best part is that the nginx container can't access the internet, so it's much harder for it to leak network data! One caveat for this method is that it will only work for services that do not need to connect out to the internet, in an anonymized fashion or otherwise. If you're running a service that needs access to the internet over the Tor network, you'll need to either configure your service so that it proxies its connection over Tor, or you can look into some experimental work on [a custom Tor network driver for Docker](https://github.com/jfrazelle/onion).

Many thanks to [Jason Wilder](http://jasonwilder.com/), whose `docker-gen` utility does most of the heavy lifting here, and as always to the [Tor project](https://torproject.org).
