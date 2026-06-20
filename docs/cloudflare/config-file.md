> **Fonte**: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/configuration-file/
> **Snapshot**: 19/06/2026
> **Formato**: Configuration file reference (Cloudflare developers)

# Configuration file

> Quick tunnels do not need a configuration file.

Locally-managed tunnels run as an instance of `cloudflared` on your machine. You can configure `cloudflared` properties by modifying command line parameters or by editing the tunnel configuration file.

In the absence of a configuration file, `cloudflared` will proxy outbound traffic through port `8080`.

## File structure for published applications

If you are exposing local services to the Internet, you can assign a public hostname to each service:

```yaml
tunnel: 6ff42ae2-765d-4adf-8112-31c55c1551ef
credentials-file: /root/.cloudflared/6ff42ae2-765d-4adf-8112-31c55c1551ef.json
ingress:
  - hostname: gitlab.widgetcorp.tech
    service: http://localhost:80
  - hostname: gitlab-ssh.widgetcorp.tech
    service: ssh://localhost:22
  - service: http_status:404
```

Configuration files that contain ingress rules must always include a catch-all rule that concludes the file.

## How traffic is matched

When `cloudflared` receives an incoming request, it evaluates each ingress rule from top to bottom to find which rule matches the request. Rules can match either the hostname or path of an incoming request, or both.

### Wildcards

You can use wildcards to match traffic to multiple subdomains. For example, if you set the `hostname` key to `*.example.com`, both `alpha.example.com` and `beta.example.com` will route traffic to your origin.

### Services

In addition to HTTP, `cloudflared` supports protocols like SSH, RDP, arbitrary TCP services, and Unix sockets.

```yaml
tunnel: 6ff42ae2-765d-4adf-8112-31c55c1551ef
credentials-file: /root/.cloudflared/6ff42ae2-765d-4adf-8112-31c55c1551ef.json
ingress:
  - hostname: example.com
    service: tcp://localhost:8000
  - hostname: staging.example.com
    service: unix:/home/production/echo.sock
  - hostname: test.example.com
    service: hello_world
  - service: http_status:404
```

## Validate ingress rules

```sh
cloudflared tunnel ingress validate
```

## Test ingress rules

```sh
cloudflared tunnel ingress rule https://foo.example.com
```
