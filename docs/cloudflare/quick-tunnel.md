> **Fonte**: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/
> **Snapshot**: 19/06/2026
> **Formato**: Quick Tunnel docs (Cloudflare developers)

# Quick Tunnels

> Quick Tunnels are intended for testing and development only. For production use, create a remotely-managed tunnel.

Developers can use the TryCloudflare tool to experiment with Cloudflare Tunnel without adding a site to Cloudflare's DNS. TryCloudflare will launch a process that generates a random subdomain on `trycloudflare.com`. Requests to that subdomain will be proxied through the Cloudflare network to your web server running on localhost.

## Use TryCloudflare

1. Install `cloudflared` (v2020.5.1 or later)
2. Launch a web server that is available over localhost to `cloudflared`
3. Run the following terminal command to start a free tunnel:

```sh
cloudflared tunnel --url http://localhost:8080
```

`cloudflared` will generate a random subdomain when connecting to the Cloudflare network and print it in the terminal for you to use and share.

> TryCloudflare quick tunnels are currently not supported if a `config.yaml` configuration file is present in the `.cloudflared` directory.

## FAQ

### Use cases

- Create a web server for a project on your laptop that you want to share with others on different networks
- Test browser compatibility for a new site by creating a free Tunnel and testing the link in different browsers
- Run speed tests from different regions

### Limitations

- **200 concurrent requests** limit — HTTP 429 returned when exceeded
- **No SSE** (Server-Sent Events) support
- These limitations only apply to Quick Tunnels

### Legal

Your installation of cloudflared software constitutes a symbol of your signature indicating that you accept the terms of the Cloudflare License, Terms and Privacy Policy.
