# Plano: Integração Tailscale no opencode_termux

## Objetivo

Adicionar Tailscale como alternativa ao Cloudflare Quick Tunnel para acesso remoto ao OpenCode Web. O usuário pode escolher entre Cloudflare (já existente) ou Tailscale (novo), ambos coexistindo no mesmo repositório.

## Escopo

- **Dentro**: Criar scripts dedicados (`opencode-tailscale.sh`, `run-opencode-tailscale.sh`, `opencode-tailscale-stop.sh`), alias, setup automatizado, documentação
- **Fora**: Modificar `opencode-web.sh` ou `run-cloudflare-tunnel.sh` existentes; suporte a múltiplos tailscale interfaces; Named Tailscale Tunnels (funnel)

## Assumptions

1. Tailscale já está instalado ou será instalado via `pkg install tailscale` no Termux
2. O proot-distro Ubuntu compartilha a rede do host (network namespace compartilhado) — `--shared-tmp` apenas compartilha `/tmp`
3. `tailscale serve` é o mecanismo correto para expor porta local na rede Tailscale (não `tailscale funnel` que é para internet pública)
4. O tailscaled roda no Termux (host), não dentro do proot
5. O socket do tailscaled fica em `/data/data/com.termux/files/usr/var/run/tailscale/tailscaled.sock` (= `$PREFIX/var/run/tailscale/tailscaled.sock`)
6. O Tailscale IP (100.x.x.x) pode ser detectado via `tailscale ip -4` no Termux
7. `tailscale serve --bg <port>` torna o serviço acessível em `https://<machine-name>.<tailnet>.ts.net`
8. Para acesso via IP Tailscale direto (`http://100.x.x.x:4096`), é necessário usar `tailscale serve --bg --http=<porta> <porta>` para criar um proxy HTTP na porta especificada
9. O script interno proot (`run-opencode-tailscale.sh`) NÃO executa comandos Tailscale — apenas inicia opencode web e sinaliza prontidão
10. O stop script precisa parar tanto o proot quanto o `tailscale serve` associado
11. Não é necessário `tailscale up` dentro do proot — o Tailscale do host é acessível via rede compartilhada

## Dependências

- **Pré-requisitos**: proot-distro instalado, Ubuntu configurado, opencode instalado no proot

## Tasks

### Task 1: Criar `run-opencode-tailscale.sh` (script interno proot)

- **Arquivo**: `/root/Projetos/opencode_termux/run-opencode-tailscale.sh` (novo)
- **Descrição**: Script executado dentro do proot (análogo ao `run-cloudflare-tunnel.sh`). Inicia `opencode web` em `127.0.0.1:4096` e sinaliza prontidão写入 arquivo compartilhado.
- **Dependências**: Nenhuma (primeira task)
- **Acceptance**:
  - Script tem shebang `#!/usr/bin/env bash` (convencão proot)
  - Carrega `.env` via `set -a; source .env; set +a`
  - Mata processos anteriores na porta (usa `lsof` se disponível, senão `fuser`)
  - Verifica se `opencode` está disponível no PATH
  - Inicia `opencode web --hostname 127.0.0.1 --port $PORT` em background
  - Aguarda 3s e verifica se o processo está vivo (`kill -0`)
  - Escreve `http://127.0.0.1:$PORT` em `$NOTIFY_FILE` (via `/tmp` compartilhado)
  - Limpa NOTIFY_FILE antigo antes de escrever
  - trap cleanup em EXIT/SIGINT/SIGTERM
  - `wait` no PID do opencode web (mantém proot vivo)
- **Verify**:
  - Run: `bash -n run-opencode-tailscale.sh`
  - Expected: exit code 0 (no syntax errors)
  - Run: `head -1 run-opencode-tailscale.sh`
  - Expected: `#!/usr/bin/env bash`
  - Run: `grep -q "opencode web" run-opencode-tailscale.sh`
  - Expected: exit code 0

### Task 2: Criar `bin/opencode-tailscale.sh` (wrapper Termux)

- **Arquivo**: `/root/Projetos/opencode_termux/bin/opencode-tailscale.sh` (novo)
- **Descrição**: Wrapper no Termux (análogo ao `opencode-web.sh`). Gerencia wake lock, inicia proot, detecta Tailscale IP, executa `tailscale serve`, envia notificações.
- **Dependências**: Task 1 (run-opencode-tailscale.sh deve existir)
- **Acceptance**:
  - Shebang `#!/data/data/com.termux/files/usr/bin/bash` (convencão Termux)
  - Carrega `.env` de `$SCRIPT_DIR`
  - PID_FILE: `$PREFIX/tmp/opencode_tailscale.pid`
  - NOTIFY_FILE: `$PREFIX/tmp/opencode_tailscale_url.txt`
  - LOG_FILE: `$PREFIX/tmp/opencode_tailscale.log`
  - Verifica se já está rodando (PID check, como opencode-web.sh)
  - Verifica `proot-distro` disponível
  - Verifica `tailscale` disponível (`command -v tailscale`)
  - Verifica se tailscaled está rodando (`tailscale status`); se não, tenta iniciar com `sudo tailscale daemon` ou informa erro
  - Detecta Tailscale IP: `TAILSCALE_IP=$(tailscale ip -4 2>/dev/null)`
  - Inicia proot com `--shared-tmp` executando `run-opencode-tailscale.sh`
  - Acquire wake lock
  - Aguarda URL do NOTIFY_FILE (loop 60s, como opencode-web.sh)
  - Executa `tailscale serve --bg --http=$PORT $PORT` no Termux para expor a porta
  - Envia notificação ntfy.sh com Tailscale IP
  - Envia termux-notification com:
    - `--id opencode-tailscale`
    - `--title "OpenCode Web (Tailscale)"`
    - `--content "Tailscale: http://${TAILSCALE_IP}:${PORT}"`
    - `--button1 "Abrir"` com `--button1-action "termux-open-url http://${TAILSCALE_IP}:${PORT}"`
    - `--button2 "Copiar"` com `--button2-action "termux-clipboard-set http://${TAILSCALE_IP}:${PORT}"`
    - `--priority high --ongoing`
  - PID do proot salvo no PID_FILE
  - `disown` do proot PID
  - `chmod +x bin/opencode-tailscale.sh` (torna executável após criação)
- **Verify**:
  - Run: `bash -n bin/opencode-tailscale.sh`
  - Expected: exit code 0 (no syntax errors)
  - Run: `head -1 bin/opencode-tailscale.sh`
  - Expected: `#!/data/data/com.termux/files/usr/bin/bash`
  - Run: `grep -q "tailscale" bin/opencode-tailscale.sh`
  - Expected: exit code 0
  - Run: `grep -q "tailscale serve" bin/opencode-tailscale.sh`
  - Expected: exit code 0
  - Run: `ls -la bin/opencode-tailscale.sh`
  - Expected: permission contains `x` (executable)

### Task 3: Criar `bin/opencode-tailscale-stop.sh` (stop script)

- **Arquivo**: `/root/Projetos/opencode_termux/bin/opencode-tailscale-stop.sh` (novo)
- **Descrição**: Para o serviço Tailscale (análogo ao `opencode-web-stop.sh`). Mata proot, para `tailscale serve`, limpa arquivos.
- **Dependências**: Task 2 (PID_FILE paths definidos)
- **Acceptance**:
  - Shebang `#!/data/data/com.termux/files/usr/bin/bash`
  - Usa os mesmos PID_FILE/NOTIFY_FILE/LOG_FILE do opencode-tailscale.sh
  - Verifica se PID_FILE existe
  - Mata processo proot (graceful SIGTERM → espera 3s → SIGKILL)
  - Para `tailscale serve`: executa `tailscale serve --https=off` ou `tailscale serve --remove /` para limpar todas as regras serve
  - Remove PID_FILE, NOTIFY_FILE, LOG_FILE
  - `stty sane` e `termux-wake-unlock`
  - Mensagem informativa
- **Verify**:
  - Run: `bash -n bin/opencode-tailscale-stop.sh`
  - Expected: exit code 0 (no syntax errors)
  - Run: `head -1 bin/opencode-tailscale-stop.sh`
  - Expected: `#!/data/data/com.termux/files/usr/bin/bash`
  - Run: `grep -q "tailscale serve" bin/opencode-tailscale-stop.sh`
  - Expected: exit code 0

### Task 4: Atualizar `shell/aliases.sh`

- **Arquivo**: `/root/Projetos/opencode_termux/shell/aliases.sh` (modificar)
- **Descrição**: Adicionar aliases para os novos scripts Tailscale.
- **Dependências**: Tasks 2, 3 (scripts devem existir)
- **Acceptance**:
  - `alias opencode_tailscale="..."` apontando para `bin/opencode-tailscale.sh`
  - `alias opencode_tailscale_stop="..."` apontando para `bin/opencode-tailscale-stop.sh`
  - Segue o padrão existente (usando `$OPENCODE_TERMUX_DIR`)
  - Não quebra aliases existentes
- **Verify**:
  - Run: `grep -c "opencode_tailscale" shell/aliases.sh`
  - Expected: exit code 0 with count 2
  - Run: `grep -q "opencode_tailscale_stop" shell/aliases.sh`
  - Expected: exit code 0

### Task 5: Atualizar `scripts/setup.sh`

- **Arquivo**: `/root/Projetos/opencode_termux/scripts/setup.sh` (modificar)
- **Descrição**: Adicionar instalação automatizada do Tailscale como seção opcional (step 4).
- **Dependências**: Nenhuma (pode ser feita em paralelo com tasks 1-3)
- **Acceptance**:
  - Nova seção `# ── 4. Tailscale (opcional) ──` após a seção de aliases
  - Verifica se `tailscale` já está instalado (`command -v tailscale`)
  - Se não estiver: tenta `pkg install tailscale -y` (com mensagem informativa)
  - Se tailscaled não estiver rodando: informa como iniciar (`tailscale up` ou `sudo tailscale daemon`)
  - Não falha o setup se Tailscale não estiver disponível (warn, não error)
  - Mensagem final inclui info sobre Tailscale como opção
- **Verify**:
  - Run: `bash -n scripts/setup.sh`
  - Expected: exit code 0 (no syntax errors)
  - Run: `grep -q "tailscale" scripts/setup.sh`
  - Expected: exit code 0
  - Run: `grep -q "opcional" scripts/setup.sh`
  - Expected: exit code 0 (clearly optional)

### Task 6: Atualizar `.env.example`

- **Arquivo**: `/root/Projetos/opencode_termux/.env.example` (modificar)
- **Descrição**: Adicionar variável de configuração Tailscale (PORT já é compartilhada).
- **Dependências**: Nenhuma
- **Acceptance**:
  - Comentário explicando que Tailscale usa a mesma OPENCODE_PORT
  - Variável `TAILSCALE_SERVE_HTTP=true` (ou similar) para habilitar/desabilitar `tailscale serve --http`
  - Não quebra variáveis existentes
- **Verify**:
  - Run: `grep -q "TAILSCALE" .env.example`
  - Expected: exit code 0

### Task 7: Criar `docs/tailscale/README.md`

- **Arquivo**: `/root/Projetos/opencode_termux/docs/tailscale/README.md` (novo)
- **Descrição**: Documentação completa cobrindo instalação, configuração, uso e troubleshooting do Tailscale no projeto.
- **Dependências**: Nenhuma (documentação pode ser escrita a partir das specs do plano)
- **Acceptance**:
  - Seções: Visão Geral, Pré-requisitos, Instalação, Configuração, Uso (comandos), Arquitetura (diagrama ASCII), Troubleshooting, Referências
  - Comandos de uso: `opencode_tailscale`, `opencode_tailscale_stop`
  - Explica diferença entre Tailscale e Cloudflare Quick Tunnel
  - Troubleshooting cobre: tailscaled não roda, IP não detectado, porta em uso, proot morre
  - Referencia `docs/proot-distro/README.md` para detalhes de networking
  - Usa formato Markdown consistente com outras docs do projeto (ver `docs/cloudflare/`)
- **Verify**:
  - Run: `test -f docs/tailscale/README.md`
  - Expected: exit code 0 (file exists)
  - Run: `grep -q "Instalação" docs/tailscale/README.md`
  - Expected: exit code 0
  - Run: `grep -q "Troubleshooting" docs/tailscale/README.md`
  - Expected: exit code 0
  - Run: `grep -q "opencode_tailscale" docs/tailscale/README.md`
  - Expected: exit code 0

## Riscos

| Risco | Mitigação |
|---|---|
| `tailscale serve --http` pode ter sintaxe diferente entre versões | Documentar versão mínima testada; fallback para `tailscale serve` sem `--http` (usa HTTPS) |
| Tailscaled pode não iniciar automaticamente no Termux | Script detecta e informa como iniciar manualmente; setup.sh documenta |
| `0.0.0.0` crasha dentro do proot (getifaddrs bug) | opencode web continua usando `127.0.0.1`; tailscale serve faz o proxy |
| Tailscale pode não estar disponível (sem F-Droid ou permissões) | Setup é opcional; script informa erro amigável |
| Conflito de porta se Cloudflare e Tailscale rodando simultaneamente | Ambos usam a mesma porta (4096), mas são modos mutuamente exclusivos; script verifica PID_FILE |

## Ordem de Implementação

1. **Task 7** (docs/tailscale/README.md) — especificação primeiro (SDD)
2. **Task 1** (run-opencode-tailscale.sh) — script proot base
3. **Task 2** (bin/opencode-tailscale.sh) — wrapper Termux
4. **Task 3** (bin/opencode-tailscale-stop.sh) — stop script
5. **Task 4** (shell/aliases.sh) — aliases
6. **Task 5** (scripts/setup.sh) — setup
7. **Task 6** (.env.example) — config

> **Nota**: Tasks 5 e 6 são independentes e podem ser feitas em paralelo com 1-4.

## Verificação Final

```bash
# 1. Syntax check em todos os scripts
bash -n run-opencode-tailscale.sh
bash -n bin/opencode-tailscale.sh
bash -n bin/opencode-tailscale-stop.sh
bash -n scripts/setup.sh
bash -n shell/aliases.sh

# 2. Permissões de execução
ls -la bin/opencode-tailscale.sh bin/opencode-tailscale-stop.sh run-opencode-tailscale.sh

# 3. Estrutura de aliases
grep "opencode_tailscale" shell/aliases.sh

# 4. Config no .env.example
grep "TAILSCALE" .env.example

# 5. Documentação existe
test -f docs/tailscale/README.md && echo "OK"

# 6. Coexistência: scripts Cloudflare intactos
bash -n run-cloudflare-tunnel.sh
bash -n bin/opencode-web.sh
bash -n bin/opencode-web-stop.sh

# 7. Arquivos criados/modificados (contagem)
# Esperado: 4 novos (run-opencode-tailscale.sh, bin/opencode-tailscale.sh, bin/opencode-tailscale-stop.sh, docs/tailscale/README.md)
#           + 3 modificados (aliases.sh, setup.sh, .env.example)
```
