> **Fonte**: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/configure-tunnels/run-parameters/
> **Snapshot**: 19/06/2026
> **Formato**: Tunnel run parameters reference (Cloudflare developers)

# Tunnel run parameters

This page lists the configuration flags for the `cloudflared tunnel run` command.

## Parameters

### `autoupdate-freq`

| Syntax | Default |
|---|---|
| `cloudflared tunnel --autoupdate-freq <FREQ> run <UUID or NAME>` | 24h |

Configures the frequency of `cloudflared` updates.

### `config`

| Syntax | Default |
|---|---|
| `cloudflared tunnel --config <PATH> run <UUID or NAME>` | `~/.cloudflared/config.yml` |

Specifies the path to a configuration file in YAML format.

### `edge-bind-address`

| Syntax | Environment Variable |
|---|---|
| `cloudflared tunnel --edge-bind-address <IP> run <UUID or NAME>` | `TUNNEL_EDGE_BIND_ADDRESS` |

Specifies the outgoing IP address used to establish a connection between `cloudflared` and the Cloudflare global network.

### `edge-ip-version`

| Syntax | Default | Environment Variable |
|---|---|---|
| `cloudflared tunnel --edge-ip-version <VERSION> run <UUID or NAME>` | 4 | `TUNNEL_EDGE_IP_VERSION` |

Specifies the IP address version (IPv4 or IPv6). Available values: `auto`, `4`, `6`.

### `grace-period`

| Syntax | Default | Environment Variable |
|---|---|---|
| `cloudflared tunnel --grace-period <PERIOD> run <UUID or NAME>` | 30s | `TUNNEL_GRACE_PERIOD` |

When `cloudflared` receives SIGINT/SIGTERM it will stop accepting new requests, wait for in-progress requests to terminate, then shut down.

### `logfile`

| Syntax | Environment Variable |
|---|---|
| `cloudflared tunnel --logfile <PATH> run <UUID or NAME>` | `TUNNEL_LOGFILE` |

Saves application log to this file.

### `loglevel`

| Syntax | Default | Environment Variable |
|---|---|---|
| `cloudflared tunnel --loglevel <VALUE> run <UUID or NAME>` | info | `TUNNEL_LOGLEVEL` |

Specifies the verbosity of logging. Available values: `debug`, `info`, `warn`, `error`, `fatal`.

### `metrics`

| Syntax | Environment Variable |
|---|---|
| `cloudflared tunnel --metrics <IP:PORT> run <UUID or NAME>` | `TUNNEL_METRICS` |

Exposes a Prometheus endpoint on the specified IP address and port.

### `no-autoupdate`

| Syntax | Environment Variable |
|---|---|
| `cloudflared tunnel --no-autoupdate run <UUID or NAME>` | `NO_AUTOUPDATE` |

Disables automatic `cloudflared` updates.

### `pidfile`

| Syntax | Environment Variable |
|---|---|
| `cloudflared tunnel --pidfile <PATH> run <UUID or NAME>` | `TUNNEL_PIDFILE` |

Writes the application's process identifier (PID) to this file after the first successful connection.

### `protocol`

| Syntax | Default | Environment Variable |
|---|---|---|
| `cloudflared tunnel --protocol <VALUE> run <UUID or NAME>` | auto | `TUNNEL_TRANSPORT_PROTOCOL` |

Specifies the protocol used to establish a connection. Available values: `auto`, `http2`, `quic`.

### `region`

| Syntax | Environment Variable |
|---|---|
| `cloudflared tunnel --region <VALUE> run <UUID or NAME>` | `TUNNEL_REGION` |

Allows you to choose the regions to which connections are established. Currently the only available value is `us`.

### `retries`

| Syntax | Default | Environment Variable |
|---|---|---|
| `cloudflared tunnel --retries <VALUE> run <UUID or NAME>` | 5 | `TUNNEL_RETRIES` |

Specifies the maximum number of retries for connection/protocol errors. Retries use exponential backoff.

### `tag`

| Syntax | Environment Variable |
|---|---|
| `cloudflared tunnel --tag <KEY=VAL> run <UUID or NAME>` | `TUNNEL_TAG` |

Specifies custom tags used to identify this tunnel.

### `token`

| Syntax | Environment Variable |
|---|---|
| `cloudflared tunnel run --token <TUNNEL_TOKEN>` | `TUNNEL_TOKEN` |

Associates the `cloudflared` instance with a specific tunnel (remotely-managed tunnels only).

### `token-file`

| Syntax | Environment Variable |
|---|---|
| `cloudflared tunnel run --token-file <PATH>` | `TUNNEL_TOKEN_FILE` |

Associates the `cloudflared` instance with a specific tunnel using a file (remotely-managed tunnels only, requires 2025.4.0+).
