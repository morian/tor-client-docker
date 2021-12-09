Docker for Tor
==============

This image contains is based on alpine and runs the Tor daemon for Socks and Control purposes.
Socks5 server is exposed on port TCP/9050, Control server is exposed on TCP/9051.

Additional configuration entries can be provided by mounting a host directory to `/etc/tor/torrc.d/`
inside the container (all `.conf` files will be read).

If you want to maintain a consistent daemon state accross multiple runs, make sure to save
`/var/lib/tor` to a persistent docker volume as it is used by Tor to save its current state.

The daemon runs with an unprivileged user for additional security, with uid and gid 800.
During the runtime, the authentication cookie used by the control port is located at
`/run/tor/control.authcookie`, which you can expose to the host or to the other containers
that might need it to correctly authenticate on the control port.
