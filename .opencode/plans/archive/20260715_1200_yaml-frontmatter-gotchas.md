# Plano: Documentar YAML Frontmatter Gotchas

## Objetivo

Adicionar seção **9.6 YAML Frontmatter Gotchas** ao `docs/MULTI_AGENT_ORCHESTRATION.md` documentando lições aprendidas sobre erros de formatação YAML nos frontmatters dos agentes que quebram a execução do OpenCode.

## Contexto (Lição Aprendida)

O usuário editou manualmente os 5 arquivos em `.config/opencode/agents/`:
1. Alterou `color: purple` → `color: "#9D00FF"` (named colors → hex codes)
2. Removeu `task: []` dos subagentes

**Problemas causados:**
- `color: #FFA500` (sem aspas) → YAML interpreta `#FFA500` como comentário, campo `color` fica vazio/null
- `task: []` removido → subagentes ganham acesso ilimitado a outros subagentes (quebra de isolamento)

**Estado atual verificado (15/07/2026):**
- Todos os 5 agentes já usam hex colors **com aspas** (`"#9D00FF"`, `"#FFA500"`, `"#00FF00"`, `"#0000FF"`) — correto
- Nenhum subagente tem `permission.task: []` — ISTO É UM BUG ATUAL, mas está fora do escopo deste plano (documentação apenas)

## Escopo

- Dentro: Adicionar seção 9.6 ao MULTI_AGENT_ORCHESTRATION.md com 5 subseções cobrindo cada gotcha
- Fora: NENHUMA modificação em arquivos de agentes, código, ou config. Apenas documentação.

## Assumptions

1. A seção 9.6 será inserida entre a seção 9.5 (atual última) e a seção 10
2. O formato seguirá o padrão das seções 9.1-9.5 (tabelas, listas, exemplos de código)
3. O conteúdo será em português (padrão do documento)
4. A documentação é retroativa — descreve o que aconteceu e como evitar, não corrige o bug de `task: []` ausente

## Tasks

### Task 1: Analisar estrutura da seção 9 existente

- **Acceptance**: Mapeamento completo das subseções 9.1-9.5, identificação do ponto de inserção (após linha ~683, antes da seção 10)
- **Verify**: Verificar que a seção 10 começa na linha 685 (`## 10. Melhorias Recentes`)
- **Files**: `docs/MULTI_AGENT_ORCHESTRATION.md` (leitura apenas)
- **Complexidade**: Baixa

### Task 2: Adicionar seção 9.6 YAML Frontmatter Gotchas

- **Acceptance**: Seção 9.6 inserida com 5 subseções (9.6.1-9.6.5), cada uma com:
  - Tabela "Problema → Solução" ou equivalente
  - Exemplo de código YAML correto e incorreto
  - Referência ao arquivo afetado
- **Verify**: `grep -c "9.6" docs/MULTI_AGENT_ORCHESTRATION.md` retorna >= 6 (título + 5 subseções)
- **Files**: `docs/MULTI_AGENT_ORCHESTRATION.md` (edição)
- **Complexidade**: Baixa

**Conteúdo das subseções:**

#### 9.6.1 Hex colors precisam de aspas
- **Problema**: `color: #FFA500` → YAML interpreta `#` como início de comentário, valor é null
- **Solução**: `color: "#FFA500"` (aspas duplas obrigatórias)
- **Exemplo correto**: `color: "#FFA500"`
- **Exemplo incorreto**: `color: #FFA500`
- **Arquivos afetados**: Todos os 5 em `.config/opencode/agents/`

#### 9.6.2 `*` é alias YAML
- **Problema**: `"*": allow` pode ser interpretado como alias YAML se mal formatado
- **Solução**: Chaves com `*` devem ter aspas: `"*": allow`
- **Exemplo correto**: `"*": allow` (já usa aspas na chave)
- **Exemplo incorreto**: `*: allow` (YAML tenta resolver alias)
- **Arquivos afetados**: Todos os agents com `permission.bash`

#### 9.6.3 `task: []` é obrigatório para isolamento
- **Problema**: Sem `permission.task: []`, subagentes podem chamar outros subagentes (quebra de segurança)
- **Solução**: Subagentes SEMPRE precisam de `permission.task: []` no frontmatter
- **Regra**: Apenas agents `mode: primary` (ex: task-build) ficam sem `permission.task`
- **Arquivos afetados**: `code-review.md`, `dev.md`, `task-planner.md`, `git-commit.md`
- **Nota**: Documentar que `permission.task` aceita formato array ou objeto

#### 9.6.4 Validação de YAML antes de aplicar
- **Problema**: Edição manual pode introduzir erros sutis de formatação
- **Solução**: Validar sempre com `python3 -c "import yaml; yaml.safe_load(open('file').read().split('---')[1])"` antes de commitar
- **Alternativa**: `opencode debug agent <name>` para verificar parsing
- **Checklist**: Validar TODOS os 5 arquivos após edição

#### 9.6.5 Delimitadores `---` no frontmatter
- **Problema**: Frontmatter começa e termina com `---`. Linhas `---` no body do markdown podem confundir parsers ingênuos
- **Solução**: Body do markdown não deve conter `---` isolados como separadores de seção (usar `###` ou `####` em vez disso)
- **Arquivos afetados**: Todos os agents `.md`
- **Nota**: O parser do OpenCode é robusto, mas parsers YAML genéricos podem falhar

### Task 3: Atualizar seção 9.1 Erros Comuns

- **Acceptance**: Adicionar entrada na tabela de erros comuns referenciando a seção 9.6
- **Verify**: `grep "YAML" docs/MULTI_AGENT_ORCHESTRATION.md` retorna resultado na seção 9.1
- **Files**: `docs/MULTI_AGENT_ORCHESTRATION.md` (edição)
- **Complexidade**: Baixa

**Entrada a adicionar na tabela 9.1:**

| Problema | Solução |
|----------|---------|
| YAML frontmatter quebra parsing | Ver seção 9.6 — hex colors, `*`, `task: []`, validação |

### Task 4: Atualizar AGENTS.md se necessário

- **Acceptance**: Se houver referência a `permission.task` no AGENTS.md que precise de nota sobre validação YAML, adicionar
- **Verify**: `grep "permission.task" AGENTS.md` mostra referências existentes são consistentes
- **Files**: `AGENTS.md` (leitura + possível edição menor)
- **Complexidade**: Baixa

### Task 5: Verificação final de consistência

- **Acceptance**:
  - Seção 9.6 existe e tem 5 subseções
  - Tabela 9.1 tem entrada referenciando 9.6
  - Nenhum `---` isolado no body dos agentes .md
  - Todos os hex colors nos agentes usam aspas (já verificado — OK)
- **Verify**: 
  - `grep -c "9.6" docs/MULTI_AGENT_ORCHESTRATION.md` retorna >= 6
  - `grep "YAML" docs/MULTI_AGENT_ORCHESTRATION.md` retorna resultado
  - `grep "color: #" .config/opencode/agents/*.md` NÃO retorna nada (sem aspas)
  - `grep 'color: "#' .config/opencode/agents/*.md` retorna 5 resultados (todos com aspas)
- **Files**: `docs/MULTI_AGENT_ORCHESTRATION.md`, `.config/opencode/agents/*.md` (leitura apenas)
- **Complexidade**: Baixa

## Riscos

| Risco | Mitigação |
|-------|-----------|
| Inserção em ponto errado do documento | Verificar linha da seção 10 antes de inserir |
| Formato incompatível com seções existentes | Seguir padrão das seções 9.1-9.5 |
| Documentação ficar desatualizada | Referenciar data da lição aprendida (15/07/2026) |

## Ordem de Implementação

1. Task 1 (análise) → Task 2 (inserir 9.6) → Task 3 (atualizar 9.1) → Task 4 (verificar AGENTS.md) → Task 5 (verificação final)

## Verificação Final

- [ ] Seção 9.6 YAML Frontmatter Gotchas existe com 5 subseções
- [ ] Tabela 9.1 tem entrada referenciando 9.6
- [ ] Conteúdo cobre: hex colors, aliases `*`, `task: []`, validação, delimitadores
- [ ] Exemplos de código correto e incorreto em cada subseção
- [ ] Nenhuma modificação em arquivos de agentes ou código
- [ ] Documento é auto-contido (quem ler entende o problema e a solução)
