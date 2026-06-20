> **Fonte**: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/downloads/
> **Snapshot**: 19/06/2026
> **Formato**: Downloads page (Cloudflare developers)

# Downloads

Cloudflare Tunnel requires the installation of a lightweight server-side daemon, `cloudflared`, to connect your infrastructure to Cloudflare.

## GitHub repository

`cloudflared` is an open source project maintained by Cloudflare.

- [All releases](https://github.com/cloudflare/cloudflared/releases)
- [Release notes](https://github.com/cloudflare/cloudflared/blob/master/RELEASE_NOTES)

## Latest release

### Linux

| Type | amd64 / x86-64 | ARM | ARM64 |
|---|---|---|---|
| Binary | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64) | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm) | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64) |
| .deb | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb) | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm.deb) | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb) |
| .rpm | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm) | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm.rpm) | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-aarch64.rpm) |

### macOS

```sh
brew install cloudflared
```

### Windows

| Type | 32-bit | 64-bit |
|---|---|---|
| Executable | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-386.exe) | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe) |
| MSI | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-386.msi) | [Download](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.msi) |

### Docker

A Docker image is available on DockerHub: `cloudflare/cloudflared`

## Deprecated releases

Cloudflare supports versions of `cloudflared` that are within one year of the most recent release.

## Installation for PRoot Ubuntu (ARM64)

```sh
# Download the .deb package
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb

# Install inside proot
dpkg -i cloudflared-linux-arm64.deb
```
