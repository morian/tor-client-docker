Tor running on Docker
=====================

This image is based on alpine and runs the Tor daemon for Socks and Control purposes.
Socks5 server is exposed on port TCP/9050, Control server is exposed on TCP/9051.

## How to use?

Additional configuration entries can be provided by mounting a host directory to `/etc/tor/torrc.d/`
inside the container (all `.conf` files will be read).

If you want to maintain a consistent daemon state accross multiple runs, make sure to mount
`/var/lib/tor` in a persistent docker volume as it is used by Tor to save its current state.
This would speed up the starting process and lower the load on the network.

Pre-built images are [available in docker hub](https://hub.docker.com/repository/docker/morian42/tor-client/).

You can also provide the hashed password for the controller from the command line:
```yaml
---
service:
  tor-client:
    image: "morian42/tor-client:0.4.8.21"
    ports:
      - "127.0.0.1:9050:9050"
      - "127.0.0.1:9051:9051"
    command: [
        "tor", "-f", "/etc/tor/torrc",
        "HashedControlPassword",
        "16:E748903F3251DDC1608A105ABAECC28B159ADD1A22455F36CE1A58B292"
    ]
```

This password can be generated with the following command:
```console
$ tor --hash-password password
16:E748903F3251DDC1608A105ABAECC28B159ADD1A22455F36CE1A58B292
```

The daemon runs with an unprivileged user for additional security, with uid and gid 800.

The authentication cookie used to connect to the control port is located at
`/run/tor/control.authcookie`. You can set a docker volume mount point to `/run/tor/`
to provide access to this cookie file and start interacting with the daemon.
Such mount would also make it possible to make this file accessible from another container.


## How to build images?

The following build variables are used to control both the alpine and Tor versions:
- *ALPINE_VER*: set the version of alpine (base image)
- *TOR_VER*: set the version of Tor to build

```sh
docker build --build-arg TOR_VER="0.4.8.21" .
```

Tor archives are pulled from [Tor's distribution mirror](https://dist.torproject.org/) and
checked against PGP keys [mentionned by the Tor project](https://support.torproject.org/little-t-tor/verify-little-t-tor/).
