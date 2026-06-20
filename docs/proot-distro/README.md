> **Fonte**: https://github.com/termux/proot-distro
> **Snapshot**: 19/06/2026
> **Formato**: Raw README.md do repositório oficial

# PRoot-Distro

PRoot-Distro is a utility for managing rootless Linux containers in
[Termux](https://termux.dev) and on regular Linux hosts. It uses
[proot](https://proot-me.github.io/) to provide a chroot-like
environment without requiring root access on the device.

Containers are created by pulling Docker/OCI images directly from
Docker Hub or any compatible registry — or by extracting a local
tarball / OCI image archive. The container filesystem is assembled from
the image layers and stored locally, ready to be entered at any time.

PRoot-Distro can also **build** OCI images from a Dockerfile (no Docker
daemon required), storing the result in the local manifest cache or
exporting it as a standalone OCI tarball.

---

## Table of contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Quick start](#quick-start)
4. [Commands](#commands-reference)
5. [How PRoot-Distro works](#how-proot-distro-works)
6. [Storage layout](#storage-layout)
7. [Environment variables](#environment-variables)
8. [Limitations](#limitations)

---

## Introduction

PRoot-Distro lets you run a full Linux userland — Ubuntu, Debian,
Alpine, Arch, openSUSE, distroless server images, anything available as
a Docker/OCI image — on top of Termux on an Android device, or on top
of a regular Linux distribution, **without** root, **without** a kernel
module, and **without** a Docker daemon.

### Installation

#### On Termux (Android)

```sh
pkg install proot-distro
```

This pulls in `proot` automatically as a dependency.

#### On a regular Linux host

```sh
sudo apt install proot python3-pip
pip install proot-distro
```

### Quick start

```sh
# Install Ubuntu 24.04 from Docker Hub
proot-distro install ubuntu:24.04

# Start a shell inside the container
proot-distro login ubuntu

# Run a single command and exit
proot-distro login ubuntu -- /bin/uname -a

# List all installed containers
proot-distro list

# Rebuild from scratch (loses all in-container data)
proot-distro reset ubuntu

# Permanently remove a container
proot-distro remove ubuntu
```

---

## Commands reference

The `pd` short alias works everywhere `proot-distro` does.

### `install` — Install a container

```
proot-distro install [OPTIONS] (IMAGE or PATH)
```

Pull a Docker/OCI image and create a container from it, or extract one
from a local archive file.

**Options:**

| Option | Description |
|---|---|
| `-n`, `--name NAME` | Set a custom local name for the container |
| `-a`, `--architecture ARCH` | Override the target CPU architecture |
| `-q`, `--quiet` | Suppress non-error output |

### `login` — Start a shell inside a container

```
proot-distro login [OPTIONS] CONTAINER [-- COMMAND ...]
```

Spawn an interactive shell (or a custom command) inside an installed
container.

**Options always available:**

| Option | Description |
|---|---|
| `-u`, `--user USER` | Log in as USER (default: `root`) |
| `-P`, `--redirect-ports` | Redirect privileged ports 1–1023 to higher numbers |
| `--shared-home` | Bind the host home directory into the container |
| `--shared-tmp` | Bind the host `$PREFIX/tmp` to `/tmp` inside the container |
| `--shared-x11` | Bind `$PREFIX/tmp/.X11-unix` to `/tmp/.X11-unix` |
| `-b`, `--bind SRC[:DST]` | Bind a custom path (repeatable) |
| `--emulator PATH` | Override the QEMU emulator binary |
| `--kernel STRING` | Customize the kernel release string |
| `--hostname STRING` | Customize the hostname inside the container |
| `-w`, `--work-dir PATH` | Set the initial working directory |
| `-e`, `--env VAR=VALUE` | Set an environment variable in the guest |
| `--get-proot-cmd` | Print the fully assembled proot command line and exit |

**Options available only on Termux (Android):**

| Option | Description |
|---|---|
| `--isolated` | Skip non-essential host bindings |
| `--minimal` | Bare-minimum proot (only /dev, /proc, /sys) |
| `--no-link2symlink` | Disable proot's hard-link emulation |
| `--no-sysvipc` | Disable System V IPC emulation |
| `--no-kill-on-exit` | Wait for all child processes before exiting |

### `run` — Run the image-defined entrypoint

```
proot-distro run [OPTIONS] CONTAINER [-- ARG ...]
```

Run the `Entrypoint` and/or `Cmd` defined in the container's Docker
image manifest.

### `list` — List installed containers

```
proot-distro list
```

### `remove` — Delete a container

```
proot-distro remove [OPTIONS] CONTAINER
```

### `reset` — Reinstall a container from scratch

```
proot-distro reset CONTAINER
```

### `backup` — Archive a container

```
proot-distro backup [OPTIONS] CONTAINER
```

### `restore` — Restore a container from a backup

```
proot-distro restore [OPTIONS] [BACKUP_FILE]
```

### `copy` — Copy files to or from a container

```
proot-distro copy [OPTIONS] [CONTAINER:]SRC [CONTAINER:]DEST
```

### `sync` — Synchronize files to or from a container

```
proot-distro sync [OPTIONS] [CONTAINER:]SRC [CONTAINER:]DEST
```

### `clear-cache` — Delete the download cache

```
proot-distro clear-cache
```

---

## How PRoot-Distro works

### 1. OCI registry client

The `install` command speaks the standard OCI Distribution protocol
directly over `urllib`:

- Public images on **Docker Hub** require no flags
- Public images on **other registries** are addressed by full reference
- Manifest lists are resolved to the platform that matches your CPU
- Each layer blob is downloaded with its **SHA-256 verified**

### 2. The proot utility

[proot](https://proot-me.github.io/) is a user-space implementation of
`chroot`, `mount --bind`, and `binfmt_misc`. It uses Linux's `ptrace`
mechanism to intercept system calls made by the guest process and
rewrite filesystem paths on the fly.

When you run `proot-distro login ubuntu`, PRoot-Distro `exec`s into a
`proot` command line that looks roughly like:

```sh
env PATH=… HOME=/root … \
  proot --kill-on-exit --link2symlink --sysvipc \
        --kernel-release=… -L \
        --change-id=0:0 \
        --rootfs=/…/containers/ubuntu/rootfs --cwd=/root \
        --bind=/dev --bind=/proc --bind=/sys \
        --bind=/storage --bind=/system --bind=/apex … \
        /bin/sh -l
```

---

## Storage layout

All runtime data is stored under `$RUNTIME_DIR`:

- **Termux**: `$TERMUX__PREFIX/var/lib/proot-distro/`
- **Regular Linux**: `$XDG_DATA_HOME/proot-distro/`

| Path | Contents |
|---|---|
| `containers/<name>/rootfs/` | Container root filesystem |
| `containers/<name>/manifest.json` | Image reference, arch, full OCI manifest, full image config |
| `containers/<name>/rootfs/.l2s/` | Proot link2symlink (l2s) backing store |
| `locks/<name>.lock` | Per-container POSIX flock |
| `$BASE_CACHE_DIR/oci_layers/` | Cached OCI layer blobs |
| `$BASE_CACHE_DIR/oci_manifests/` | Cached resolved single-arch manifests |
| `$BASE_CACHE_DIR/build_cache_index.json` | build cache index |

---

## Environment variables

| Variable | Effect |
|---|---|
| `TERMUX__PREFIX` | Override Termux prefix path |
| `TERMUX__HOME` | Override the Termux home path |
| `TERMUX_APP__PACKAGE_NAME` | Override the Termux app package |
| `XDG_DATA_HOME` | On non-Termux hosts, base for proot-distro data |
| `XDG_CACHE_HOME` | On non-Termux hosts, base for proot-distro cache |
| `PD_DOCKER_AUTH` | Credentials for pulling/pushing Docker/OCI images |
| `PD_FORCE_NO_COLORS` | Disables ANSI colors in output |
| `PROOT_VERBOSE` | Inherited and forwarded to proot for debugging |
| `TERM`, `COLORTERM` | Inherited from host and exported into guest |

---

## Limitations

### PRoot limitations

- **Performance**: ptrace-based, slower than native
- **Kernel features**: features that depend on Linux kernel modules do not work
- **No real root**: proot uses UID/GID remapping to fake root
- **No background services**: starting service supervisors is generally not possible
- **No cgroups / namespaces**: features that need real Linux kernel namespaces do not work
- **No nesting**: PRoot-Distro refuses to run inside another `proot`

### PRoot-Distro limitations

- **Registry authentication**: only the `PD_DOCKER_AUTH` environment variable is supported
- **No zstd-compressed layers**: Python's `tarfile` module does not support zstd
- **No live state migration**: backup/restore archive the rootfs but not in-memory state
- **Termux-only flags on non-Termux hosts**: `--isolated`, `--minimal`, `--no-link2symlink`, `--no-sysvipc`, and `--no-kill-on-exit` are not exposed when running outside Termux
