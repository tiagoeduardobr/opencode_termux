# Plano: Corrigir passos de instalação do README.md

## Objetivo

Corrigir os comandos de instalação no README.md que falham no Termux + proot-distro Ubuntu, e adicionar orientações ausentes sobre symlink e primeira execução.

## Escopo

- **Dentro**: Reescrever Step 3 (Node.js), Step 4 (OpenCode CLI), adicionar Step 4.1 (symlink fix), adicionar Step 4.2 (first boot guidance), renumerar passos subsequentes.
- **Fora**: Não alterar seções fora das linhas 95-198 (SSH, Architecture, FAQ, NVIDIA NIM).

## Assumptions

1. O usuário está dentro do proot Ubuntu (`proot-distro login ubuntu`) quando executa Steps 3 e 4.
2. O comando `npm install -g opencode-linux-arm64 --force` é o correto para Termux arm64 (confirmado pelo usuário).
3. O symlink `ln -sf ... opencode-linux-arm64/bin/opencode .../usr/bin/opencode` é necessário porque o npm global não adiciona ao PATH automaticamente no proot.
4. `hash -r` limpa o cache de PATH do bash.
5. A primeira execução do OpenCode cria databases SQLite e é lenta (5-10 min).

## Tasks

### Task 1: Reescrever Step 3 — Node.js
- **Acceptance**: Step 3 usa `apt update && apt install nodejs npm -y` (simples, direto)
- **Verify**: Comando é válido dentro de proot Ubuntu
- **Files**: `README.md` (linhas 95-113)
- **Complexidade**: baixa

**Mudança具体**:
- Substituir linhas 95-113 inteiras
- Novo conteúdo:
  ```markdown
  ### 3. Node.js inside proot

  ```bash
  apt update && apt install nodejs npm -y
  node -v
  npm -v
  ```
  ```

### Task 2: Reescrever Step 4 — OpenCode CLI + adicionar symlink fix
- **Acceptance**: Step 4 instala `opencode-linux-arm64` com `--force`, cria symlink, e roda `hash -r`
- **Verify**: Comandos são válidos e encadeados corretamente
- **Files**: `README.md` (linhas 115-120)
- **Complexidade**: baixa

**Mudança具体**:
- Substituir linhas 115-120 inteiras
- Novo conteúdo:
  ```markdown
  ### 4. OpenCode CLI

  ```bash
  npm install -g opencode-linux-arm64 --force
  ln -sf /data/data/com.termux/files/usr/lib/node_modules/opencode-linux-arm64/bin/opencode /data/data/com.termux/files/usr/bin/opencode
  hash -r
  opencode --version
  ```

  > **Por que `--force`?** O npm detecta o OS como "android" e bloqueia a instalação. `--force` contorna isso.
  > **Por que o symlink?** O npm global no proot não adiciona o binário ao PATH. O symlink garante que `opencode` seja encontrado.
  ```

### Task 3: Adicionar Step 4.1 — Orientação de primeira execução
- **Acceptance**: Novo sub-step explica wake lock, databases SQLite, e mensagem de espera
- **Verify**: Instruções são claras e acionáveis
- **Files**: `README.md` (após Step 4)
- **Complexidade**: baixa

**Mudança具体**:
- Inserir novo bloco após Step 4 (antes do Step 5 atual)
- Novo conteúdo:
  ```markdown
  ### 4.1. Antes da primeira execução

  1. **Wake lock** — Para evitar que o Android suspenda o Termux:
     ```bash
     termux-wake-lock
     ```

  2. **Primeira execução é lenta** — O OpenCode cria databases SQLite na primeira vez. Pode levar **5 a 10 minutos**. Aguarde a mensagem:
     ```
     Database migration complete
     ```

  3. **Não interrompa** — Não feche o terminal nem pressione Ctrl+C durante a migração.
  ```

### Task 4: Renumerar passos subsequentes
- **Acceptance**: Todos os passos após o Step 4.1 são renumerados corretamente (5→6, 6→7, etc.)
- **Verify**: Sequência numérica contínua e sem saltos
- **Files**: `README.md` (linhas 122-198)
- **Complexidade**: baixa

**Mudança具体**:
| Antes | Depois |
|---|---|
| 5. cloudflared | 5. cloudflared (inalterado) |
| 6. Sair do proot e clonar | 6. Sair do proot e clonar |
| 7. Rodar o setup | 7. Rodar o setup |
| 8. Configurar aliases | 8. Configurar aliases |
| 9. Copiar .env | 9. Copiar .env |
| 10. Primeira execução | 10. Primeira execução |

> Nota: Steps 5-10 já estão numerados corretamente — a inserção do Step 4.1 não requer renumerização porque é um sub-step (4.1), não um step principal.

## Riscos

- **Risco**:黏贴 de blocos markdown pode introduzir erros de formatação → **Mitigação**: Verificar rendering após edição
- **Risco**: Caminho do symlink pode mudar entre versões do npm → **Mitigação**: Usar caminho fixo baseado na estrutura padrão do npm

## Ordem de Implementação

1. Task 1 (Step 3) → 2. Task 2 (Step 4) → 3. Task 3 (Step 4.1) → 4. Task 4 (renumerar se necessário)

## Verificação Final

1. Ler README.md linhas 95-198 e confirmar:
   - Step 3 usa `apt install nodejs npm -y`
   - Step 4 usa `opencode-linux-arm64 --force` + symlink + `hash -r`
   - Step 4.1 existe com wake lock, SQLite warning, e "Database migration complete"
   - Todos os passos subsequentes estão numerados corretamente
2. Verificar que nenhum outro conteúdo do README foi alterado acidentalmente
