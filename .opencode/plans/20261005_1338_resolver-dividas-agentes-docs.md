# Plano: Resolver 3 dívidas do upgrade OpenCode 1.18.34 (agentes + docs)

> **Status final (revert + limpeza de planos)**:
>
> 1. **Tasks 1–2 revertidas.** As alterações em
>    `.config/opencode/agents/task-planner.md` e `.config/opencode/agents/git-commit.md`
>    foram **revertidas** por decisão do usuário — os agentes estavam funcionais e a
>    instabilidade observada era dos modelos de IA, não dos prompts. Ambos os arquivos
>    têm **zero diff** contra `main`.
> 2. **Tasks 3–5 mantidas**, com a Task 5 parcialmente superada pela limpeza de planos:
>    o índice `README.md` foi reescrito depois — os planos `20260827`, `20260904`,
>    `20260914` e `20260926` foram **deletados** (histórico no git), e `20260828` e
>    `20260916` foram **movidos para `archive/`**. O `README.md` final tem 3 linhas em
>    `Ativos` no diff contra `main` (`3 3`), não `3 0`.
> 3. **`Expected` da Task 5 e da Verificação Final são históricos.** Contagens de
>    arquivos `.md` de plano, o numstat do `README.md` e o `git status` esperados nas
>    seções da Task 5 **não valem mais** — use o estado real do disco. Os demais
>    `Expected` do plano (Tasks 1–4, lint, frontmatters, Dívidas 1–3) referem-se ao
>    estado planejado; os das Tasks 1–2 correspondem ao que foi revertido.
>
> As seções abaixo são **escopo planejado**, não aplicado na íntegra.

## Objetivo

Resolver as 3 dívidas deixadas pelo upgrade do OpenCode para 1.18.34 neste
repositório, tocando apenas os 5 arquivos em escopo:

1. **Dívida 1 (BUG REAL)** — `task-planner` usa a tool `question` quando
   invocado via Task tool pelo `task-build` e a invocação retorna **vazio**.
   Eliminar o uso de `question` no prompt **e** bloquear mecanicamente via
   `question: deny` no frontmatter.
2. **Dívida 2** — `git-commit` fabrica output de comando (reutiliza hashes e
   contextos do prompt como se fossem saída real; reporta sucesso quando houve
   falha/negação). Adicionar regras de evidência ao prompt.
3. **Dívida 3 (documental)** — 20 issues MD060 em
   `docs/SESSION_CONTEXT_20260618.md`; `AI_HANDOVER.md` com bloco de estado
   desatualizado/ambíguo; `.opencode/plans/README.md` com índice defasado
   (3 planos existentes no disco e commitados ausentes).

Estado base verificado nesta sessão: `main` = `origin/main` = `fbce83d`,
working tree limpa, OpenCode CLI `1.18.34` (`/usr/bin/opencode`),
plugin `^1.18.34`, lint baseline `Summary: 20 issues in 1 file`.

## Escopo

**Dentro** (exatamente 5 arquivos):

- `.config/opencode/agents/task-planner.md` — frontmatter L35
  (`question: allow` → `question: deny`), step 3 (L109–113) e step 8 (L391–393).
- `.config/opencode/agents/git-commit.md` — nova seção de regras de evidência
  + 1 linha na tabela de Anti-padrões + 1 bullet no Contrato de Output
  (frontmatter L1–22 intocado).
- `docs/SESSION_CONTEXT_20260618.md` — somente os 3 separadores de tabela
  das linhas 469, 480 e 509 (**whitespace de pipes apenas**, zero mudança de
  conteúdo).
- `AI_HANDOVER.md` — apenas inserção de nota de snapshot histórico em
  `## Estado do Repositório` (L18 `OpenCode versão: 1.18.25` permanece
  intocada; nenhum hash novo).
- `.opencode/plans/README.md` — 3 linhas novas na tabela `## Ativos`.

**Fora** (não tocar):

- `AGENTS.md`, `docs/MULTI_AGENT_ORCHESTRATION.md`, `scripts/`, `bin/`,
  `shell/`, `.config/opencode/skills/`, `opencode.json`,
  `.config/opencode/package.json`, `package.json`, backups, `.git/`.
- NÃO deletar branch/arquivo/commit. NÃO push. NÃO amend. NÃO reescrever
  histórico.
- Nenhuma mudança em código shell — apenas Markdown/YAML de config de agentes.
- Não alterar `question`/fluxo interativo de `git-commit`, `dev`,
  `code-review`, `task-build` (bug confirmado só no `task-planner`).

## Assumptions

1. **Causa da Dívida 1 é a tool `question`** (confirmado no briefing; não é
   billing nem permissão de escrita — `73dc449` já corrigiu `edit` para
   `.opencode/plans/*` separadamente).
2. **Decisão Dívida 1 — aplicar as DUAS camadas (prompt + `question: deny`)**.
   Justificativa:
   - **Schema-validado**: `https://opencode.ai/config.json` →
     `AgentConfig.permission` → `PermissionConfig.properties.question` →
     `PermissionActionConfig` = enum `["ask","allow","deny"]` — a chave aceita
     valor por agente. Corroborado por
     `docs/MULTI_AGENT_ORCHESTRATION.md:830` (`permission.question | ✅ Sim`).
   - **Evidência empírica de conflito**: `opencode debug agent task-planner`
     retorna HOJE **duas** entradas para `question` — uma `deny` (default do
     runtime, posição ~741 do JSON) e um `allow` (frontmatter, posição ~1151).
     A resolução é ambígua; `question: deny` no frontmatter elimina a
     ambiguidade (ambas passam a ser `deny`).
   - **Prompt-only não é garantia**: fix só de texto depende de compliance do
     modelo (mesmo com `temperature: 0.2`); `deny` converte qualquer tentativa
     perdida em erro de permissão explícito (recuperável pelo agente) em vez
     do retorno **vazio silencioso** que o `task-build` trata como falha
     (step 4 do task-build: "Se task-planner falhar ou retornar vazio").
   - `task-planner` não tem caso legítimo de interação: é invocado via Task
     tool, o step 8 tem mensagem de retorno fixa, e assumptions são
     reportadas no plano + resposta final. `task-build` continua
     `question: allow` para interagir com o usuário.
3. **Decisão Dívida 3b — Opção A (nota de snapshot), não Opção B (seção
   nova)**. Justificativa:
   - Os upgrades 1.18.27→1.18.34 **já estão documentados** em
     `docs/SESSION_CONTEXT_20260618.md` (seções "Atualização OpenCode
     1.18.27/1.18.30/1.18.34", L464–498) e em `AGENTS.md` ("Melhorias
     Recentes"). A Opção B criaria uma **3ª cópia** desses dados com risco de
     drift — exatamente a classe de inconsistência que esta dívida corrige.
   - A Opção A não faz **nenhuma afirmação factual nova** (zero hashes, zero
     números de versão atuais — só *pointers* para docs que vivem o estado
     corrente), risco zero do achado `High` de review anterior (registro
     internamente falso: commit antigo + versão nova).
     Consistente com a Assumption 11 do plano `20260926_0017_...` ("AI_HANDOVER
     permanece snapshot, fora de escopo por convenção") — agora o status de
     snapshot é explicitado em vez de deixado implícito.
   - A L18 (`OpenCode versão: 1.18.25`) permanece como valor histórico **por
     decisão**; a nota deixa claro que aquele bloco não é estado corrente.
     (Contexto verificado: L18 foi atualizado por `694678d` em 28/08, enquanto
     L15 cita `3497e95` de 16/07 — por isso o bloco só pode ser tratado como
     histórico, não como estado de um único momento.)
4. **Hashes do índice (Dívida 3c) são reais** (verificados com
   `git cat-file -e` nesta sessão): upgrade 1.18.27 = `d241abf`, upgrade
   1.18.30 = `447e4c6`, bump plugin 1.18.34 = `cdb2b56`. O plano
   `20260926_0017_upgrade-opencode-1-18-32.md` **nunca foi executado**
   (plugin saltou `^1.18.30` → `^1.18.34` direto em `cdb2b56`; não existe
   seção "Atualização OpenCode 1.18.32" no SESSION_CONTEXT; a Task 8/MD060
   daquele plano nunca rodou — baseline ainda tem 20 erros) → status "Não
   executado (superseded...)" no índice.
5. **Ordem das tasks**: seguida a sequência explícita do briefing
   (Dívida 1 → 2 → 3a → 3b → 3c). A observação "a 3a vai por último entre as
   documentais" conflita com a sequência listada; como as tasks são
   independentes (arquivos disjuntos), a ordem não afeta o resultado — registrado
   aqui em vez de perguntado (restrição: subagente NÃO usa tool `question`).
6. **Localizador de linhas do MD060**: `grep -n '^|---' docs/SESSION_CONTEXT_20260618.md`
   retorna **exatamente** as 3 linhas-alvo (469, 480, 509) — usar conteúdo,
   não número de linha, caso o arquivo mude.
7. **Validação de frontmatter** será por `opencode debug agent <nome>` (lê o
   arquivo do disco a cada invocação, NÃO depende de restart; exit 0 =
   YAML/parsing válido). `pyyaml` não está instalado no ambiente.
8. **O plano em si** (`.opencode/plans/20261005_1338_*.md`) é versionado por
   convenção (ver `fbce83d`); incluí-lo no commit é decisão do `task-build` —
   fora do escopo dos 5 arquivos acima.
9. **Verificação comportamental exige restart**: que os fixes de
   `.config/opencode/agents/*.md` valham em sessão nova (ver Checkpoint Final);
   durante a implementação só é possível validação estática.

## Tasks

### Task 1: Dívida 1 — `task-planner` nunca mais usa `question`

- **Acceptance**:
  - Given `.config/opencode/agents/task-planner.md` com `question: allow`
    (frontmatter L35) e step 3 instruindo "perguntar ao usuário" /
    "confirmar com o usuário" (L111–112)
  - When o arquivo é alterado em 3 pontos: (a) L35 → `question: deny`;
    (b) step 3 reescrito para proibir `question` e rotear assumptions para a
    seção `## Assumptions` do plano + resposta final ao task-build; (c) step 8
    extendido para reportar assumptions/questões em aberto após a frase
    obrigatória de retorno
  - Then `grep` não encontra mais nenhuma instrução de perguntar/confirmar
    com o usuário no step 3; `opencode debug agent task-planner` sai com
    exit 0 e NÃO contém `"action": "allow"` associado a
    `"permission": "question"`; a mensagem fixa do step 8
    (`'Plano salvo em .opencode/plans/{arquivo}. Pronto para revisão.'`)
    permanece intacta
- **Conteúdo de referência para os 3 pontos** (dev pode polir a redação;
  o conteúdo semântico é obrigatório):

  (a) frontmatter:
  ```yaml
  question: deny
  ```

  (b) substituir as L109–113 por:
  ```markdown
  ### 3. Entender a tarefa

  - **NUNCA usar a tool `question`** — o task-planner é subagente e não
    interage com o usuário: uma chamada de `question` retorna vazia e derruba
    a invocação inteira (bug real desta dívida). A chave `question: deny` no
    frontmatter é a garantia mecânica; esta regra é a garantia comportamental.
  - Se a descrição da tarefa for vaga, prosseguir com a melhor hipótese
    verificável e registrar tudo na seção `## Assumptions` do plano (itens
    extras sob o subtítulo "Questões em aberto" para o que o usuário precisa
    decidir)
  - Listar **assumptions** (pressupostos) no plano — NÃO pedir confirmação
    durante a execução; a confirmação acontece depois, com o task-build, a
    partir da sua resposta final
  - Definir success criteria concretos e testáveis
  ```
  (mantém o step 3a de Critérios de Aceitação e todo o restante do arquivo)

  (c) após a linha do step 8
  (`- Retornar mensagem: 'Plano salvo em .opencode/plans/{arquivo}. Pronto para revisão.'`),
  acrescentar:
  ```markdown
  - Se houver assumptions ou questões em aberto, anotá-las logo após essa
    frase (ex.: `Assumptions relevantes: ...`) para o task-build repassar
    ao usuário
  ```
- **Verify**:
  - `Run: grep -n "question\|perguntar ao usuário\|confirmar com o usuário" .config/opencode/agents/task-planner.md`
  - `Expected:` apenas a linha `question: deny` do frontmatter + as novas
    instruções "NUNCA usar a tool `question`"; zero ocorrências de
    "perguntar ao usuário" / "confirmar com o usuário"
  - `Run: opencode debug agent task-planner | grep -A2 '"permission": "question"' | grep -c '"action": "allow"'`
  - `Expected: 0`  (e comando pai: `opencode debug agent task-planner >/dev/null; echo $?` → `0`)
  - `Run: grep -c '^---$' .config/opencode/agents/task-planner.md`
  - `Expected: 2` (frontmatter íntegro: L1 e L37)
  - `Run: grep -n "Plano salvo em .opencode/plans" .config/opencode/agents/task-planner.md`
  - `Expected:` pelo menos 1 match (mensagem fixa de retorno preservada)
- **Files**: `.config/opencode/agents/task-planner.md`
- **Complexidade**: média

### Task 2: Dívida 2 — `git-commit` ganha regras de evidência de output

- **Acceptance**:
  - Given `.config/opencode/agents/git-commit.md` sem NENHUMA regra sobre
    reportar saída literal ou não inventar comandos (baseline: grep por
    `literal|fabric|invent|saída` = 0 matches) e com histórico de 3
    delegações fabricando output (hash errado `cdb2b56` vindo do próprio
    prompt; branch com tracking inexistente; sucesso reportado para deleção
    que não ocorreu)
  - When uma nova seção `## Regras de Evidência (anti-alucinação de output)`
    é inserida logo **após** `## Convenções de commit` (L28–44) e **antes**
    de `## Skills Dinâmicas` (L46), mais 1 linha nova na tabela
    `### Anti-padrões de Commit` e 1 bullet no `### Contrato de Output`
  - Then a seção proíbe: (1) afirmar que um comando rodou sem colar
    stdout/stderr literal; (2) reutilizar hashes/nomes/mensagens do PROMPT
    como se fossem saída de execução; (3) reportar sucesso quando houve
    falha/negação; exige (4) verificação cruzada antes de reportar
    (`git log -1 --format=%h %s` para hash; `git branch --list <nome>` com
    saída vazia = branch deletada); e trata exemplos de "output esperado" do
    prompt como ilustração, nunca como fato — **e** o frontmatter (L1–22,
    incl. `question: allow`) e os steps 0–4 permanecem inalterados
- **Conteúdo de referência da seção nova** (inserir após a L44):
  ```markdown
  ## Regras de Evidência (anti-alucinação de output)

  O prompt de delegação pode conter exemplos de "output esperado" — exemplos
  são ILUSTRAÇÃO, nunca fato. Obrigatório ao reportar qualquer comando:

  1. **Saída literal**: NUNCA afirmar que um comando rodou sem colar o
     stdout/stderr real (em bloco de código), inclusive quando falha.
  2. **Nada do prompt vira saída**: NUNCA reutilizar hashes, nomes de branch,
     mensagens ou outputs citados no prompt como se fossem resultado de
     execução. Valores só contam se obtidos por execução real NESTE turno
     (hash → `git log -1 --format=%h`; branch atual → `git branch --show-current`).
  3. **Falha é falha**: permissão negada, comando rejeitado, branch que não
     foi deletada → reportar explicitamente como falha. Proibido sucesso
     parcial ou silencioso.
  4. **Verificação cruzada obrigatória** antes de reportar:
     - commit → confirmar com `git log -1 --format=%h %s`
     - deleção de branch → confirmar com `git branch --list <nome>`
       (saída vazia = deletada; se a branch aparece, reportar que NÃO foi
       deletada)
  5. Se o output real divergir do "esperado" descrito no prompt, reportar o
     output REAL e sinalizar a divergência.
  ```
  - Linha a acrescentar ao final da tabela `### Anti-padrões de Commit`:
    `| Fabricar output de comando (hash/branch que não existem) | task-build opera sobre realidade falsa (ex.: branch reportada como deletada ainda existe) | Regras de Evidência: saída literal + verificação cruzada |`
  - Bullet a acrescentar no `### Contrato de Output` (antes do último):
    `- Hashes e outputs DEVEM vir de execução real colada — nunca do prompt (ver Regras de Evidência)`
- **Verify**:
  - `Run: grep -n "^## Regras de Evidência (anti-alucinação de output)" .config/opencode/agents/git-commit.md`
  - `Expected:` 1 match, com número de linha entre a seção
    `## Convenções de commit` e `## Skills Dinâmicas`
  - `Run: grep -c "Regras de Evidência" .config/opencode/agents/git-commit.md`
  - `Expected: 3` (seção nova + linha da tabela Anti-padrões + bullet do
    Contrato de Output)
  - `Run: grep -c "stdout/stderr\|Falha é falha\|git branch --list" .config/opencode/agents/git-commit.md`
  - `Expected: 3` (as 3 regras-chave presentes em linhas distintas da seção)
  - `Run: grep -c '^---$' .config/opencode/agents/git-commit.md`
  - `Expected: 2` (frontmatter L1 e L22 intactos)
  - `Run: opencode debug agent git-commit >/dev/null; echo $?`
  - `Expected: 0` (frontmatter continua parseável; `question: allow` mantido)
  - `Run: grep -n "question: allow" .config/opencode/agents/git-commit.md`
  - `Expected:` 2 matches — frontmatter L21 + a nota da regra 6 (fluxo
    interativo do git-commit não alterado)
- **Files**: `.config/opencode/agents/git-commit.md`
- **Complexidade**: média

### Task 3: Dívida 3a — corrigir 20 issues MD060 (3 separadores de tabela)

- **Acceptance**:
  - Given `npm run lint:docs` falha com `Summary: 20 issues in 1 file`, todos
    `MD060/table-column-style` em `docs/SESSION_CONTEXT_20260618.md`
    (linhas 469, 480, 509 — separadores sem espaços nos pipes)
  - When os 3 separadores são convertidos para o estilo com espaços (mesmo
    padrão da L492, que já é MD060-clean e serve de referência):
    - L469: `|--------|------|-----------|` → `| -------- | ------ | ----------- |`
    - L480: `|--------|------|-----------|` → `| -------- | ------ | ----------- |`
    - L509: `|---------|------|--------|--------------|` → `| --------- | ------ | -------- | -------------- |`
      ⚠️ **9** dashes na coluna 1, não 8: a contagem de dashes de cada coluna
      deve ser preservada. O `MD060` (estilo `compact`) só valida o espaçamento
      dos pipes — as duas variantes passam nele —, mas o gate `OK_SO_ESPACOS`
      (Verify desta task) reprova a de 8 dashes, que altera um caractere
      não-espaço (`|---------|` → `|--------|`).
  - Then `npm run lint:docs` → **0 issues**; `git diff main --numstat` do
    arquivo = `3 3` (3 linhas mudadas); e a comparação removendo TODOS os
    espaços entre a versão em `main` e a working tree sai **idêntica** —
    prova de que nenhum caractere além de espaço foi alterado (restrição de
    bloqueio do briefing: seções históricas verificadas byte-a-byte)
  - ⚠️ Localizar as linhas por conteúdo (`grep -n '^|---'`), não confiar
    cegamente no número — a verificação de lint é a autoridade final
- **Verify**:
  - `Run: npm run lint:docs`
  - `Expected: Summary: 0 issues` e exit 0
  - `Run: git diff main --numstat -- docs/SESSION_CONTEXT_20260618.md`
  - `Expected: 3	3	docs/SESSION_CONTEXT_20260618.md`
  - `Run: diff <(git show main:docs/SESSION_CONTEXT_20260618.md | tr -d ' ') <(tr -d ' ' < docs/SESSION_CONTEXT_20260618.md) && echo OK_SO_ESPACOS`
  - `Expected: OK_SO_ESPACOS` (sem output de diff — nenhum caractere
    não-espaço alterado)
  - `Run: git diff main -- docs/SESSION_CONTEXT_20260618.md | grep '^[+-]' | grep -v '^[+-][+-]'`
  - `Expected:` exatamente 6 linhas (3 antigas + 3 novas), todas separadores
    de tabela
- **Files**: `docs/SESSION_CONTEXT_20260618.md` (somente 3 linhas)
- **Complexidade**: baixa

### Task 4: Dívida 3b — nota de snapshot histórico em `AI_HANDOVER.md`

- **Acceptance**:
  - Given `AI_HANDOVER.md` é um snapshot datado (`# AI_HANDOVER — 2026-08-17`)
    com bloco `## Estado do Repositório` internamente misto (L15 cita commit
    antigo `3497e95`; L18 diz `OpenCode versão: 1.18.25`, atualizado por
    `694678d` em 28/08) — atualizar L18 isoladamente criaria registro
    falso (bloqueado pelo briefing)
  - When uma nota de blockquote é **inserida** logo após o heading
    `## Estado do Repositório` (L13), deixando claro que o bloco é estado
    pontual (agosto/2026), não mantido continuamente, e que o estado corrente
    vive em `AGENTS.md` (seção "Melhorias Recentes"),
    `docs/MULTI_AGENT_ORCHESTRATION.md` (cabeçalho "Versão do sistema") e
    `docs/SESSION_CONTEXT_20260618.md` (seções de upgrade)
  - Then L18 permanece **byte-idêntica**; o diff do arquivo é **pura
    inserção** (0 remoções); as linhas adicionadas não contêm nenhum hash de
    commit nem número de versão atual; lint continua 0 issues
- **Conteúdo de referência da nota** (inserir após L13, antes de L15):
  ```markdown
  > **⚠️ Snapshot histórico — não é o estado corrente.** Os dados abaixo
  > registram o estado no momento da criação deste documento e de suas
  > atualizações pontuais (agosto/2026) e **não são mantidos continuamente**.
  > A versão do OpenCode, a branch e o commit vigentes estão em `AGENTS.md`
  > (seção "Melhorias Recentes"), `docs/MULTI_AGENT_ORCHESTRATION.md`
  > (cabeçalho "Versão do sistema") e `docs/SESSION_CONTEXT_20260618.md`
  > (seções de upgrade).
  ```
  (sem inventar hash — a nota usa apenas *pointers*; ver Assumption 3)
- **Verify**:
  - `Run: git diff main --numstat -- AI_HANDOVER.md`
  - `Expected:` primeira coluna > 0 e **segunda coluna = 0** (só inserções;
    ex.: `7	0	AI_HANDOVER.md`)
  - `Run: grep -n "OpenCode versão: 1.18.25" AI_HANDOVER.md`
  - `Expected: 25:- OpenCode versão: 1.18.25` — era L18, deslocada +7 pela
    nota (6 linhas de blockquote + 1 em branco, após a remoção da clause da
    FIX-2); conteúdo byte-idêntico (intocada)
  - `Run: git diff main -- AI_HANDOVER.md | grep '^+' | grep -v '^+++' | grep -E '\b[0-9a-f]{7}\b'`
  - `Expected:` sem output (nenhum hash de commit fabricado nas linhas novas)
  - `Run: grep -n "Snapshot histórico" AI_HANDOVER.md`
  - `Expected:` 1 match logo após o heading `## Estado do Repositório`
  - `Run: npm run lint:docs`
  - `Expected: Summary: 0 issues`
- **Files**: `AI_HANDOVER.md`
- **Complexidade**: baixa

### Task 5: Dívida 3c — índice de planos com os 3 planos faltantes

- **Acceptance**:
  - Given `.opencode/plans/README.md` lista 3 planos em `## Ativos` (L12–14)
    mas existem **7** arquivos `.md` de plano no disco (6 históricos + este
    plano `20261005_1338_resolver-dividas-agentes-docs.md`, que é
    **excluído de propósito** do índice e do verify — incluí-lo exigiria uma
    4ª linha nova e quebraria o `Expected: 3	0` do `git diff --numstat`
    abaixo), sendo que
    `20260904_1118_upgrade-opencode-1-18-27.md`,
    `20260914_0959_upgrade-opencode-1-18-30.md` e
    `20260926_0017_upgrade-opencode-1-18-32.md` estão commitados (`fbce83d`)
    e ausentes do índice
  - When 3 linhas são **inseridas** na tabela `## Ativos` em ordem
    cronológica, com o formato exato das linhas existentes
    (colunas: Plano | Status | Commit de referência; nomes de arquivo e
    hashes entre crase). As 3 linhas a acrescentar:
    | Plano | Status | Commit de referência |
    |---|---|---|
    | `20260904_1118_upgrade-opencode-1-18-27.md` | Executado (upgrade 1.18.27) | `d241abf` |
    | `20260914_0959_upgrade-opencode-1-18-30.md` | Executado (upgrade 1.18.30) | `447e4c6` |
    | `20260926_0017_upgrade-opencode-1-18-32.md` | Não executado (superseded pelo upgrade 1.18.34) | `cdb2b56` (upgrade 1.18.34 efetivo) |

    Resultado da ordem final: 0827, 0828, **0904, 0914**, 0916, **0926**
    (cronológica). Status e hashes conforme Assumption 4 (verificados com
    `git cat-file -e`; nenhum hash inventado).
  - Then todos os 6 planos **históricos** do disco aparecem no índice (o
    plano atual `20261005_1338_*` é isento de propósito, junto com o
    `README.md`); diff é pura inserção (`3 0`); nenhuma linha existente foi
    modificada/removida
- **Verify**:
  - `Run: git diff main --numstat -- .opencode/plans/README.md`
  - `Expected: 3	0	.opencode/plans/README.md`
  - `Run: for f in .opencode/plans/*.md; do case "$f" in .opencode/plans/README.md|*/20261005_1338_*) continue;; esac; grep -q "$(basename $f)" .opencode/plans/README.md || echo "FALTANDO: $f"; done`
  - `Expected:` sem output — README.md e o próprio plano atual
    (`*/20261005_1338_*`) são isentos de propósito pelo `case`; nenhum dos
    6 planos indexáveis está faltando
  - `Run: git cat-file -e d241abf^{commit} && git cat-file -e 447e4c6^{commit} && git cat-file -e cdb2b56^{commit} && echo HASHES_OK`
  - `Expected: HASHES_OK`
  - `Run: git diff main -- .opencode/plans/README.md | grep -c '^-[^-]'`
  - `Expected: 0` (nenhuma linha removida/alterada)
- **Files**: `.opencode/plans/README.md`
- **Complexidade**: baixa

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Fix da Dívida 1 não eliminar o retorno vazio (bug persiste após restart — ex.: causa real mais profunda, como canal interativo de subagente) | Média | Alto | Duas camadas independentes (reescrita de prompt + `question: deny`); validação estática com `opencode debug agent` durante a implementação + validação end-to-end pós-restart (Checkpoint Final) invocando task-planner real via task-build; se persistir, abrir plano novo para investigar com `opencode run` (fora do escopo atual) |
| Alteração acidental de **conteúdo** em `docs/SESSION_CONTEXT_20260618.md` (bloqueio explícito do briefing — seções históricas verificadas byte-a-byte em review anterior) | Baixa | Alto | Verify em 3 camadas obrigatórias antes de aceitar a task: numstat `3 3`, diff com `tr -d ' '` idêntico (`OK_SO_ESPACOS`), e lint `0 issues`; qualquer número fora do esperado → reverter o arquivo (`git checkout main -- docs/...` apenas deste arquivo) e refazer somente as 3 linhas-alvo localizadas por `grep -n '^|---'` |
| Frontmatter YAML quebrado em `task-planner.md` ou `git-commit.md` durante a edição → agente deixa de carregar no restart e quebra o pipeline multiagente inteiro | Baixa | Alto | Após CADA edição de agente: `opencode debug agent <nome>` (exit 0) + `grep -c '^---$'` = 2; diff completo revisado pelo `code-review` antes de qualquer commit (regra obrigatória do projeto) |
| Nota no `AI_HANDOVER.md` introduzir nova afirmação falsa/desatualizada (mesma classe do achado `High` em review anterior) | Baixa | Médio | Opção A escolhida justamente por não afirmar valores atuais: só *pointers* para docs vivos; proibição explícita de hash/versão na nota; verify com grep anti-hash nas linhas `+` do diff + lint 0 |
| Regras de evidência novas do `git-commit` conflituarem com o `### Contrato de Output` ou com o fluxo interativo existente (steps 0–4, `question: allow`) → comportamento inesperado do agente | Baixa | Médio | Inserção **aditiva** (nenhum step existente reescrito; `question: allow` e frontmatter intactos verificados por grep/debug); linha da tabela Anti-padrões aponta para a seção; `code-review` verifica coerência interna do prompt antes do commit |

## Verificação Final

```bash
# 1. Lint documental (baseline era 20 issues → agora 0)
npm run lint:docs; echo "exit=$?"          # esperado: Summary: 0 issues, exit=0

# 2. Frontmatters íntegros e agents parseáveis
opencode debug agent task-planner >/dev/null; echo $?   # esperado: 0
opencode debug agent git-commit   >/dev/null; echo $?   # esperado: 0
grep -c '^---$' .config/opencode/agents/task-planner.md  # esperado: 2
grep -c '^---$' .config/opencode/agents/git-commit.md    # esperado: 2

# 3. Dívida 1: question bloqueado para o task-planner
opencode debug agent task-planner | grep -A2 '"permission": "question"' | grep -c '"action": "allow"'   # esperado: 0

# 4. Dívida 2: seção de evidência presente, fluxo interativo preservado
grep -c "^## Regras de Evidência" .config/opencode/agents/git-commit.md  # esperado: 1
grep -c "question: allow" .config/opencode/agents/git-commit.md          # esperado: 2 (frontmatter L21 + nota da regra 6)

# 5. Dívida 3a: apenas whitespace nas 3 linhas
git diff main --numstat -- docs/SESSION_CONTEXT_20260618.md               # esperado: 3	3	...
diff <(git show main:docs/SESSION_CONTEXT_20260618.md | tr -d ' ') <(tr -d ' ' < docs/SESSION_CONTEXT_20260618.md) && echo OK_SO_ESPACOS

# 6. Dívida 3b: só inserições, L18 intocada, sem hash inventado
git diff main --numstat -- AI_HANDOVER.md                                 # esperado: N	0	AI_HANDOVER.md
grep -n "OpenCode versão: 1.18.25" AI_HANDOVER.md                         # Expected: 25:- OpenCode versão: 1.18.25 — era L18, deslocada +7 pela nota (6 linhas + 1 em branco); conteúdo byte-idêntico (intocada)
git diff main -- AI_HANDOVER.md | grep '^+' | grep -v '^+++' | grep -E '\b[0-9a-f]{7}\b'   # esperado: sem output

# 7. Dívida 3c: índice completo, só inserções, hashes reais
git diff main --numstat -- .opencode/plans/README.md                      # esperado: 3	0	...
for f in .opencode/plans/*.md; do case "$f" in .opencode/plans/README.md|*/20261005_1338_*) continue;; esac; grep -q "$(basename $f)" .opencode/plans/README.md || echo "FALTANDO: $f"; done   # esperado: sem output (README e este plano isentos de propósito)
git cat-file -e d241abf^{commit} && git cat-file -e 447e4c6^{commit} && git cat-file -e cdb2b56^{commit} && echo HASHES_OK

# 8. Escopo: nada fora dos 5 arquivos
git status --short    # esperado: apenas os 5 arquivos do escopo alterados
                      # (+ este plano .opencode/plans/20261005_1338_*.md, versionado por convenção — decisão do task-build)
```

### Checkpoint Final: restart obrigatório do OpenCode

- **Verificar**: os fixes em `.config/opencode/agents/task-planner.md` e
  `.config/opencode/agents/git-commit.md` **só passam a valer após RESTART do
  OpenCode** — agentes (e config) são carregados no startup e não são
  hot-reload (confirmado na skill `customize-opencode`: "Config is loaded once
  when opencode starts and is not hot-reloaded"; mesma lição registrada como
  Assumption 13 do plano `20260926_0017_upgrade-opencode-1-18-32.md`).
  Sem restart, a sessão corrente continua com os prompts antigos e o bug da
  Dívida 1 persiste mesmo com o arquivo corrigido em disco.
- **Validação**:
  1. Encerrar e relançar o OpenCode (nova sessão) após o merge.
  2. Na sessão nova: `opencode debug agent task-planner` → sem
     `"action": "allow"` para `question`.
  3. Invocação real: pedir ao `task-build` para planejar uma tarefa vaga e
     confirmar que o `task-planner` retorna **não-vazio**, com a mensagem
     `Plano salvo em .opencode/plans/{arquivo}. Pronto para revisão.` seguida
     das assumptions — sem nenhuma tentativa de `question`.
   4. Observação (Dívida 2): o fix do `git-commit` é preventivo — a prova
      definitiva deixa de ser grep e passa a ser comportamental em delegações
      futuras (colar stdout real em vez de reproduzir o "output esperado" do
      prompt).

## Dívidas abertas (fora do escopo desta sessão)

Registradas pelo code-review consolidado; não corrigidas aqui por decisão do
usuário.

1. **FIND-001 funcional — `question` no `git-commit`**
   (`.config/opencode/agents/git-commit.md`).
   O agente é `mode: subagent` com `question: allow` (frontmatter) e usa a tool
   `question` em ≥5 pontos obrigatórios (ex.: L88, L261, L271, L280). A Dívida 1
   documentou que `question` em subagente retorna vazia e derruba a invocação —
   mas isso foi **medido só no `task-planner`**; no `git-commit` é hipótese.
   Fix real (se confirmado): migrar esses usos para escalonamento ao `task-build`.
   Exige plano próprio — mudança de comportamento no agente que roda em toda
   task.

2. **FIND-002 — contrato sem receptor para assumptions**
   (`.config/opencode/agents/task-build.md`).
   O `task-planner` passou a emitir `Assumptions relevantes:` e a instruir que
   "a confirmação acontece depois, com o task-build", mas
   `grep -i assumption task-build.md` → 0 hits. O step 4 do `task-build` só
   valida a frase canônica e não repassa as assumptions. O mecanismo existe
   (`question: allow` em L43 do `task-build.md`), falta o lado receptor: 1
   bullet no step 4 repassando-as ao usuário **antes** do pedido de aprovação
   do plano.
   Exige plano próprio — toca `task-build.md`, fora do escopo desta sessão.
