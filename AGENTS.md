# opencode_termux

Scripts para gerenciar OpenCode Web com Cloudflare Tunnel no Termux (Android).

## Estrutura

- `bin/opencode-web.sh` — Manager fire-and-forget: inicia proot + OpenCode + Tunnel em background, notifica via ntfy.sh
- `bin/opencode-web-stop.sh` — Stopper: kill grace + cleanup
- `run-cloudflare-tunnel.sh` — Script executado dentro do proot (inicia opencode web + cloudflared + ntfy)
- `shell/aliases.sh` — Aliases para bash

## Uso

```bash
source shell/aliases.sh    # ou adicionar ao ~/.bashrc
opencode_web               # inicia
opencode_web_stop          # para
```

## Config

Variáveis de ambiente (ou `.env` no diretório do projeto):
- `OPENCODE_PORT` — porta local (default 4096)
- `NTFY_TOPIC` — tópico ntfy.sh para notificação push
- `PROJECT_DIR` — diretório com `run-cloudflare-tunnel.sh`

## Dependências

- Termux (F-Droid)
- proot-distro + Ubuntu
- opencode CLI (`npm install -g @anthropic-ai/opencode`)
- cloudflared
- curl
- ntfy app (Android, para receber notificações)
