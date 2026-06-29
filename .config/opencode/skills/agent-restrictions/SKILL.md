---
name: agent-restrictions
description: Use when reviewing agent permissions, debugging permission violations, or verifying compliance with editing restrictions
---

# Agent Restrictions

## Overview

Documenta restrições de permissão dos agentes para garantir conformidade.
Útil para revisão de código, debug de violações de permissão, e manutenção do sistema.

## Agentes e Restrições

### task-build (Orquestrador)

**Permissões**: 
- `edit: "deny"`, `write: "deny"`
- `bash: "*": "allow"` com padrões de negação

**Proibições**:
- NUNCA modificar código ou arquivos — delegar para `dev`
- NUNCA executar git de escrita — delegar para `git-commit`
- Métodos bloqueados: sed, python -c, node -e, tee, echo redirect, cp, mv, install, patch

**Exceção**: Leitura git (status, log, diff) é permitida.

### task-planner (Planejador)

**Permissões**:
- `edit: "deny"`, `write: "allow"` (apenas para planos)
- `bash: "*": "allow"` com padrões de negação

**Proibições**:
- NUNCA chamar subagentes de implementação (dev, code-review, git-commit)
- NUNCA executar comandos de escrita no shell
- Workflow estritamente: Ler → Analisar → Planejar → Salvar → Apresentar → PARAR

**Exceção**: Salvar planos em `.opencode/plans/`.

### dev (Implementador)

**Permissões**:
- `edit: "allow"`, `write: "allow"`
- `bash: "*": "allow"` com `git *` deny

**Proibições**:
- NUNCA executar comandos git de escrita

### code-review (Revisor)

**Permissões**:
- `edit: "deny"`, `write: "deny"`
- `bash: "*": "allow"`

**Proibições**:
- NUNCA modificar código
- NUNCA fazer commit

### git-commit (Gestor Git)

**Permissões**:
- `edit: "deny"`, `write: "deny"`
- `bash: "*": "allow"` com merge/push ask

**Proibições**:
- NUNCA modificar código fonte ou testes

## Padrões de Negação no opencode.json

### Edição Indireta (task-build, task-planner)

```json
"bash": {
  "*": "allow",
  "sed *": "deny",
  "sed -i *": "deny",
  "awk *": "deny",
  "python -c *": "deny",
  "python3 -c *": "deny",
  "node -e *": "deny",
  "tee *": "deny",
  "ruby -e *": "deny",
  "perl -e *": "deny",
  "cp *": "deny",
  "mv *": "deny",
  "install *": "deny",
  "patch *": "deny",
  "git checkout -b*": "deny"
}
```

### Git (dev)

```json
"bash": {
  "*": "allow",
  "git *": "deny"
}
```

## Verificação de Conformidade

1. **Para verificar permissões de um agente**:
   ```bash
   opencode debug agent <nome-do-agente>
   ```

2. **Para testar se um comando está bloqueado**:
   - Tentar executar o comando via bash tool
   - Se bloqueado, retornará erro de permissão

3. **Para auditar todas as permissões**:
   - Ler `opencode.json` e verificar seções `bash` de cada agente
   - Confirmar que padrões de negação estão presentes

## Manutenção

### Adicionar Novo Padrão de Negação

1. Identificar comando que pode ser usado para edição indireta
2. Adicionar padrão na seção `bash` do agente em `opencode.json`
3. Adicionar documentação neste skill
4. Atualizar `docs/MULTI_AGENT_ORCHESTRATION.md` seção 9.5

### Remover Padrão de Negação

1. Verificar se o comando é realmente necessário para o agente
2. Se sim, remover padrão e documentar exceção
3. Se não, manter negação

## Referências

- `opencode.json` — configuração de permissões
- `docs/MULTI_AGENT_ORCHESTRATION.md` seção 9.5 — proibições documentadas
- Prompts dos agentes — `.config/opencode/agents/*.md`