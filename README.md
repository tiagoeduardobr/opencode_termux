# opencode_termux

Tudo que você precisa para rodar [OpenCode](https://github.com/anthropics/claude-code/tree/main) no Termux (Android)
como um serviço web acessível de qualquer lugar via Cloudflare Tunnel, com notificação push.

> **Público-alvo**: Android 14+ (arm64, MIUI/Xiaomi), Termux F-Droid + proot-distro Ubuntu.
> Testado com Xiaomi 14T, Android 14, MIUI HyperOS.

---

## Estrutura do repositório

```
opencode_termux/
├── .config/opencode/              ← GLOBAL: skills, agents, config (symlink de ~/.config/opencode)
│   ├── opencode.jsonc             ← config global do opencode
│   ├── skills/                    ← 27 skills (25 globais + 2 do parecer_descritivo)
│   │   ├── code-reviewer/
│   │   ├── executing-plans/
│   │   ├── design-system-patterns/
│   │   ├── design-tokens/
│   │   ├── fastapi-expert/
│   │   └── ...
│   └── agents/                    ← agentes subagent (git-commit, code-review)
│       ├── git-commit.md
│       └── code-review.md
├── opencode.json                  ← config DO PROJETO (aponta para skills e agents locais)
├── bin/
│   ├── opencode-web.sh            ← manager fire-and-forget
│   └── opencode-web-stop.sh       ← stopper
├── run-cloudflare-tunnel.sh       ← script executado dentro do proot
├── shell/aliases.sh               ← aliases para bash
├── scripts/setup.sh               ← configuração inicial em qualquer device
├── .env                           ← configurações reais
└── .env.example                   ← template de configuração
```

> **📌 Como funciona**: `~/.config/opencode/` → symlink → `opencode_termux/.config/opencode/`
> Skills e agents vivem no repositório e são referenciados globalmente pelo symlink.
> Clone em qualquer device, rode `bash scripts/setup.sh`, e tudo funciona.

---

## ⚠️ Antes de começar — leia

- **Use o Termux da F-Droid**, não o da Play Store (a versão Play é abandonada e quebra).
- O ambiente Ubuntu via **proot** é obrigatório — o OpenCode CLI exige glibc, e o Termux nativo usa bionic.
- `pkg` **não funciona como root** dentro do proot. Você instalará pacotes manualmente via `dpkg -i` com `.deb` baixados.
- `termux-notification` **não funciona em MIUI/Xiaomi** (o app Termux:API não pode ser instalado). Este projeto usa **[ntfy.sh](https://ntfy.sh)** para notificações push, que funciona em qualquer Android.
- O Cloudflare Tunnel é **efêmero** (Quick Tunnel). A URL muda a cada execução.
- O Ctrl+C do `opencode serve` tem um bug conhecido (#21505) que impede o processo de terminar. Este projeto contorna isso com uma arquitetura **Fire-and-Forget** — o manager inicia e sai, deixando o serviço em background. Use `opencode_web_stop` para parar.

---

## Tutorial passo a passo

### 1. Termux — setup inicial

Instale o Termux pela [F-Droid](https://f-droid.org/packages/com.termux/).

Ao abrir pela primeira vez, atualize os pacotes:

```bash
pkg upgrade -y
pkg install proot-distro curl -y
```

### 2. Ubuntu via proot

```bash
proot-distro install ubuntu
proot-distro login ubuntu
```

Dentro do proot (usuário root), teste a rede:

```bash
curl -s https://ifconfig.me
```

### 3. Node.js 20 LTS inside proot

> `pkg` não existe no proot como root. Faça download manual do `.deb`.

```bash
# URLs atualizadas (junho/2026)
curl -LO https://github.com/nodesource/distributions/raw/master/deb/setup_24.x
bash setup_24.x
apt-get install -y nodejs
node -v  # v24.x
npm -v
```

> Se o `setup_24.x` falhar, baixe o binário estático direto:
> ```bash
> curl -LO https://nodejs.org/dist/v24.8.0/node-v24.8.0-linux-arm64.tar.xz
> tar -xf node-v24.8.0-linux-arm64.tar.xz -C /usr/local --strip-components=1
> node -v
> ```

### 4. OpenCode CLI

```bash
npm install -g opencode-ai
opencode --version
```

### 5. cloudflared

```bash
curl -LO https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
dpkg -i cloudflared-linux-arm64.deb
cloudflared version
```

### 6. Sair do proot e clonar o repositório

```bash
exit  # sai do proot
```

De volta ao Termux nativo:

```bash
git clone <url-do-repositorio> opencode_termux
cd opencode_termux
```

### 7. Rodar o setup

```bash
bash scripts/setup.sh
```

O que `setup.sh` faz:
1. Faz backup de `~/.config/opencode/` existente (se não for symlink)
2. Cria symlink: `~/.config/opencode/` → `opencode_termux/.config/opencode/`
3. Instala dependências npm do `.config/opencode/`
4. Instrui sobre aliases

Isso torna skills e agentes disponíveis globalmente para **todos os projetos**.

### 8. Configurar aliases

Adicione ao `~/.bashrc` do **Termux nativo** (não dentro do proot):

```bash
echo 'source /root/Projetos/opencode_termux/shell/aliases.sh' >> ~/.bashrc
source ~/.bashrc
```

### 9. Copiar .env e ajustar

```bash
cp .env.example .env
# edite NTFY_TOPIC, PROJECT_DIR se necessário
```

### 10. Primeira execução

```bash
opencode_web
```

O que acontece:
1. O script manager adquire wake lock (impede o Android de dormir)
2. Inicia `proot-distro login ubuntu --shared-tmp` rodando `run-cloudflare-tunnel.sh`
3. Dentro do proot: `opencode web` → `cloudflared tunnel` → ntfy.sh push
4. A URL pública aparece no terminal e chega como notificação no Android
5. O manager **sai** — o serviço fica rodando em background (PID salvo)

Para parar:

```bash
opencode_web_stop
```

Para ver o status (manual):

```bash
cat $PREFIX/tmp/opencode_web.pid   # PID
cat $PREFIX/tmp/opencode_url.txt   # URL ativa
```

---

## Arquitetura

### Camada de config — symlink global

```
~/.config/opencode/  ──symlink──►  opencode_termux/.config/opencode/
                                         │
                                    skills/ (27 skills)
                                    agents/ (git-commit.md, code-review.md)
                                    opencode.jsonc

Todos os projetos enxergam skills e agentes via ~/.config/opencode/
```

### Camada de execução — Termux → proot

```
Termux (nativo)                     proot (Ubuntu)
────────────────────────────────────────────────────
opencode-web.sh  ──proot──►  run-cloudflare-tunnel.sh
(fire-and-forget)                   ├── opencode web (porta 4096)
                                    ├── cloudflared tunnel
                                    └── curl ntfy.sh (notificação)
                                    │
                              notify_file (/tmp/opencode_url.txt)
                                    │
                              ┌─────┘
                              ▼
                     termux-notification (fallback local)
                     ntfy push (notificação remota)
```

### Fluxo

| Passo | Quem | O que faz |
|---|---|---|
| 1 | `opencode-web.sh` | Adquire wake lock, inicia proot com `--shared-tmp` |
| 2 | proot + `run-cloudflare-tunnel.sh` | Sobe `opencode web` em `127.0.0.1:4096` |
| 3 | proot | Sobe `cloudflared tunnel --url http://127.0.0.1:4096` |
| 4 | proot | Extrai URL do log do cloudflared, escreve em `/tmp/opencode_url.txt` |
| 5 | proot | Envia notificação ntfy.sh com a URL |
| 6 | `opencode-web.sh` | Lê o notify file (via `--shared-tmp`), mostra no terminal, tenta `termux-notification` |
| 7 | `opencode-web.sh` | **Sai** — serviço continua em background |

### Por que Fire-and-Forget?

O `opencode serve` (e o `opencode web`) têm um bug conhecido onde Ctrl+C não termina o processo (#21505), e o processo deixa órfãos (#20899). Com Fire-and-Forget:

- O manager **não** aguarda o proot — usa `nohup` + `disown` + PID file
- O stop é feito por um **script dedicado** (`opencode-web-stop.sh`) que manda kill graceful → force
- Sem traps, sem raw mode, sem travamentos de terminal

---

## Referência

### `bin/opencode-web.sh`

Manager fire-and-forget. Inicia, notifica e sai.

Variáveis (via `.env` ou env var):

| Variável | Default | Descrição |
|---|---|---|
| `OPENCODE_PORT` | `4096` | Porta local do OpenCode Web |
| `OPENCODE_HOSTNAME` | `127.0.0.1` | Hostname do opencode web (usar `127.0.0.1` dentro do proot — `0.0.0.0` crasha com `getifaddrs`)|
| `NTFY_TOPIC` | `opencode-tunnel` | Tópico ntfy.sh para notificação |
| `PROJECT_DIR` | diretório do script | Onde está `run-cloudflare-tunnel.sh` |
| `NOTIFY_FILE` | `$PREFIX/tmp/opencode_url.txt` | Arquivo de handoff da URL |
| `PID_FILE` | `$PREFIX/tmp/opencode_web.pid` | Arquivo do PID |
| `LOG_FILE` | `$PREFIX/tmp/opencode_web.log` | Log da execução no proot |

### `bin/opencode-web-stop.sh`

Para o serviço: kill graceful → kill -9 → cleanup (PID file, notify file, wake lock, notification).

### `run-cloudflare-tunnel.sh`

Executado **dentro do proot**. Sobe `opencode web` + `cloudflared tunnel` + ntfy.sh push.

### `shell/aliases.sh`

Define os aliases `opencode_web` e `opencode_web_stop`.

---

## FAQ

| Pergunta | Resposta |
|---|---|
| O opencode não abre o navegador sozinho? | Sim, o CLI tenta abrir o navegador. No Termux isso falha silenciosamente. Use a URL do tunnel. |
| Como saber a URL atual? | No momento da inicialização ela aparece no terminal e chega por ntfy.sh. Depois, `cat $PREFIX/tmp/opencode_url.txt`. |
| O que é `--shared-tmp`? | Faz o `/tmp` do proot compartilhar o mesmo diretório do Termux nativo (`$PREFIX/tmp`), permitindo que o manager leia o notify file. |
| `termux-wake-lock` falha? | Instale `termux-api` (F-Droid) ou ignore — o wake lock não é estritamente necessário. |
| O tunnel caiu e não sobe de novo? | `opencode_web_stop` primeiro, depois `opencode_web` novamente. |
| `opencode web` vs `opencode serve`? | Ambos funcionam. `web` é a interface web (recomendado). `serve` expõe via SSE. |
| Como mudar a porta? | Edite `.env`: `OPENCODE_PORT=8080`. |
| Posso rodar sem cloudflared? | Sim, mas o acesso será apenas local (`http://127.0.0.1:4096`). Edite `run-cloudflare-tunnel.sh` e remova o cloudflared. |
| Preciso de API key da Anthropic? | Sim — configure `ANTHROPIC_API_KEY` (ou `OPENAI_API_KEY`) dentro do proot no `.env` do projeto de trabalho. |
