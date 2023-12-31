Tor running on Docker
=====================

This image contains is based on alpine and runs the Tor daemon for Socks and Control purposes.
Socks5 server is exposed on port TCP/9050, Control server is exposed on TCP/9051.


# Build the container

You can easily use the following variables to control which version of Tor you want to build:
- *ALPINE_VER*: set the version of alpine (base image)
- *TOR_VER*: set the version of Tor

```sh
docker build --build-arg TOR_VER="0.4.8.10" .
```

Tor archives are pulled from [Tor's distribution mirror](https://dist.torproject.org/) and
checked against PGP keys [mentionned by the Tor project](https://support.torproject.org/little-t-tor/verify-little-t-tor/).


# Use the container

Additional configuration entries can be provided by mounting a host directory to `/etc/tor/torrc.d/`
inside the container (all `.conf` files will be read).

If you want to maintain a consistent daemon state accross multiple runs, make sure to save
`/var/lib/tor` to a persistent docker volume as it is used by Tor to save its current state.


You can provide the hashed password for the controller from the command line:
```yaml
---
service:
  tor-client:
    image: morian42/tor-client:0.4.8.10
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
During the runtime, the authentication cookie used by the control port is located at
`/run/tor/control.authcookie`, which you can expose to the host or to the other containers
that might need it to correctly authenticate on the control port.
