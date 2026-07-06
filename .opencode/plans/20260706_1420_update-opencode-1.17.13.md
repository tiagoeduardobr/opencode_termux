# Plano: Atualizar opencode-linux-arm64 de 1.17.9 → 1.17.14

## Objetivo

Atualizar o pacote npm `opencode-linux-arm64` da versão `1.17.9` para a versão `1.17.14` (latest) no ambiente Termux, garantindo que skills, agentes e o serviço OpenCode Web continuem operacionais após a atualização.

## Escopo

### Dentro
- Atualizar o pacote npm global `opencode-linux-arm64` via Termux npm (`npm install -g opencode-linux-arm64@latest --force`)
- Verificar a versão pós-update (`opencode --version` e `npm list -g opencode-linux-arm64`)
- Reiniciar o serviço OpenCode Web (stop + start) para usar o novo binário
- Verificar funcionalidade básica: skills carregam, agentes operam
- Opcional: revisar changelog entre 1.17.9 e 1.17.14 para identificar breaking changes

### Fora
- NÃO alterar skills, agentes, ou configurações do opencode (`.config/opencode/`, `opencode.json`)
- NÃO modificar scripts de deploy/execução (`bin/`, `run-cloudflare-tunnel.sh`, `shell/`)
- NÃO mexer no setup do proot ou cloudflared
- NÃO fazer upgrade para versão major (apenas patch/minor dentro da linha 1.x)

## Assumptions

1. **npm do Termux é o correto**: O pacote `opencode-linux-arm64` está instalado via npm do Termux (`/data/data/com.termux/files/usr/bin/npm`), não dentro do proot Ubuntu. O comando `npm list -g` confirma isso.
2. **Symlink será preservado**: O symlink `/usr/bin/opencode → /data/data/com.termux/files/usr/lib/node_modules/opencode-linux-arm64/bin/opencode` aponta para dentro do `node_modules` do Termux. O npm update substitui o pacote mantendo o mesmo path, portanto o symlink continua válido.
3. **OpenCode Web precisa restart**: O serviço web (PID 7902) está rodando via proot e continuará usando o binário antigo até ser reiniciado.
4. **Skills/agentes não são afetados**: Skills e agentes estão em `~/.config/opencode/` (symlink para `.config/opencode/`), fora do `node_modules`. O update do pacote npm não toca nesses arquivos.
5. **Flag `--force` é necessária**: O npm detecta o OS como "android" e bloqueia a instalação sem `--force`.
6. **Changelog disponível**: As release notes do opencode no GitHub cobrem as mudanças entre 1.17.9 e 1.17.14.

## Tasks

- [x] **T1: Atualizar pacote npm** – Concluído em 06/07/2026:14:01 (última versão: 1.17.14)
  - **Acceptance**: Pacote atualizado para `1.17.14` sem erros
  - **Verify**: `npm list -g opencode-linux-arm64` → mostra `opencode-linux-arm64@1.17.14`
  - **Comando**: `npm install -g opencode-linux-arm64@latest --force`
  - **Complexidade**: baixa

- [x] **T2: Verificar versão e integridade do binário** – Concluído em 06/07/2026:14:48
  - **Acceptance**: `opencode --version` retorna `1.17.14` e o comando executa sem erro
  - **Verify**:
    1. `opencode --version` → `1.17.14`
    2. `ls -la /usr/bin/opencode` → symlink intacto
    3. `readlink -f /usr/bin/opencode` → aponta para o novo path (mesmo path, pacote novo)
  - **Complexidade**: baixa

- [x] **T3: Parar OpenCode Web e reiniciar** – Concluído em 06/07/2026:15:41
  - **Acceptance**: Serviço web é parado e reiniciado com sucesso, nova URL de tunnel gerada
  - **Verify**:
    1. `opencode_web_stop` → processo para, PID file removido
    2. `opencode_web` → serviço inicia, URL do tunnel aparece
    3. `opencode --version` dentro do proot (via health check) → 1.17.14
  - **Nota**: O `opencode_web_stop` faz kill graceful + `kill -9` + cleanup
  - **Risco**: Se `opencode_web` falhar, verificar logs: `cat $PREFIX/tmp/opencode_web.log`
  - **Complexidade**: baixa

- [x] **T4: Verificar skills e agentes** – Concluído em 06/07/2026:15:42
  - **Acceptance**: Skills reconhecidas, agentes operacionais
  - **Verify**:
    1. Verificar se skills listadas em `opencode.json` (seção `permission.skill`) são carregadas
    2. Verificar se agentes (`task-planner`, `dev`, `code-review`, `git-commit`, `task-build`) estão acessíveis
    3. Teste funcional: executar uma skill (ex: carregar `brainstorming`)
    4. Verificar se `~/.config/opencode/` → symlink ainda aponta para `.config/opencode/`
  - **Complexidade**: baixa

- [x] **T5 (Opcional): Revisar changelog** – Concluído em 06/07/2026:18:28
  - **Acceptance**: Identificar se há breaking changes que afetam nossa configuração
  - **Fonte**: https://github.com/anomalyco/opencode/releases
  - **Versões**: v1.17.10, v1.17.11, v1.17.12, v1.17.13, v1.17.14
  - **Pontos de atenção**:
    - v1.17.10: skill base dirs agora emitem paths do filesystem (não file:// URLs) — verificar se skills carregam corretamente
    - v1.17.11: session snapshots (não afeta nossa config)
    - v1.17.12: MCP reconnect, skill caching improvements
    - v1.17.13: bugfixes (não deve afetar)
  - **Complexidade**: baixa

## Riscos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| `npm install -g` falha por permissão | Baixa | Rodar como root (já estamos). Tentar `sudo npm install -g ...` se necessário. |
| Symlink quebra após update | Muito baixa | npm substitui o pacote no mesmo diretório. Verificar no T2. Se quebrar, recriar com `ln -sf ...`. |
| OpenCode Web não reinicia | Baixa | Ver logs (`cat $PREFIX/tmp/opencode_web.log`). Possível causa: primeira execução pós-upgrade pode rodar migration. |
| Skill loading quebra (v1.17.10 mudou paths) | Baixa | v1.17.10 fixou que skill base dirs são emitidos como filesystem paths. Nossas skills usam paths relativos em `opencode.json`, o que é compatível. |
| Banco de dados precisa migration | Média | O OpenCode roda migration automaticamente na primeira execução após upgrade. Aguardar 30-90s na primeira vez. |
| `opencode_web` já está rodando | Baixa | T3 faz stop primeiro, só depois start. O script manager (`opencode-web.sh`) já verifica PID file e aborta se já estiver rodando. |

## Ordem de Implementação

1. **T1** (npm update) → **T2** (verificação) → **T3** (restart web) → **T4** (verificar skills) → **T5** (changelog opcional)

Todas as tasks são sequenciais. T5 pode ser executada em paralelo com T1-T4 se desejado, mas é opcional.

## Histórico de versões

| Versão | Data | Mudanças |
|---|---|---|
| 1.17.9 → 1.17.10 | 24 Jun 2026 | MCP resources/instructions, --mini CLI, fix skill base dir paths |
| 1.17.10 → 1.17.11 | 25 Jun 2026 | Session snapshots, draggable tabs |
| 1.17.11 → 1.17.12 | 30 Jun 2026 | Adaptive thinking Sonnet 5, MCP reconnect, skill caching |
| 1.17.12 → 1.17.13 | 01 Jul 2026 | OpenAI reasoning mode fix, question UI fixes, model picker |
| 1.17.13 → 1.17.14 | 06 Jul 2026 | Bugfixes e melhorias de estabilidade |

Nenhuma breaking change identificada que afete nossa arquitetura de skills/agentes/symlink.

## Verificação Final

- [x] T1: Pacote npm atualizado para 1.17.14
- [x] T2: `opencode --version` retorna 1.17.14
- [x] T3: OpenCode Web reiniciado com sucesso, tunnel ativo
- [x] T4: Skills e agentes operacionais
- [x] T5: Changelog revisado (opcional)

## Comandos de referência

```bash
# Update
npm install -g opencode-linux-arm64@latest --force

# Verificação
npm list -g opencode-linux-arm64
opencode --version
readlink -f /usr/bin/opencode

# Restart
opencode_web_stop
opencode_web

# Logs
cat $PREFIX/tmp/opencode_web.log
cat $PREFIX/tmp/opencode_web.pid

# Verificar symlink
ls -la ~/.config/opencode/
```
