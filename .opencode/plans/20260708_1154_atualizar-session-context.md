# Plano: Atualizar SESSION_CONTEXT_20260618.md

## Objetivo
Atualizar o arquivo de contexto da sessão para refletir o estado atual do repositório com 49 skills, incluindo as unificações recentes e as 10 novas skills upstream.

## Escopo

### Dentro
- Atualizar contagens de skills (27 → 49)
- Atualizar referências a "27 skills" em toda a tabela de skills
- Reescrever tabela de skills instaladas com 49 itens em ordem alfabética
- Atualizar status das pendências (3 itens)
- Adicionar seção "Sessão de Unificação" nas Mudanças Recentes

### Fora
- NÃO modificar outros arquivos além de `docs/SESSION_CONTEXT_20260618.md`
- NÃO alterar a estrutura do documento (apenas conteúdo)
- NÃO reordenar seções existentes

## Assumptions

1. O arquivo atual contém 210 linhas
2. As 49 skills estão listadas no diretório `.config/opencode/skills/`
3. A numeração de linhas será mantida para facilitar revisão
4. As mudanças são puramente documentais (sem impacto funcional)

## Dependências

- **Pré-requisitos**: Nenhum — o arquivo já existe e pode ser editado diretamente
- **Ordem**: Sequencial (cada seção pode ser editada independentemente)

## Tasks

### Task 1: Atualizar contagens de skills (linhas 34-35)
- **Acceptance**: Linha 34 mostra "49 skills (27 globais + 14 obra/superpowers + 10 novas upstream)"; Linha 35 mostra "(49 skills allow)"
- **Verify**: `grep -n "49 skills" docs/SESSION_CONTEXT_20260618.md`
- **Files**: `docs/SESSION_CONTEXT_20260618.md`
- **Complexidade**: Baixa

### Task 2: Atualizar referência a skills modificadas (linha 45)
- **Acceptance**: Linha 45 mostra "lista de 49 skills" em vez de "lista de 27 skills"
- **Verify**: `grep -n "49 skills" docs/SESSION_CONTEXT_20260618.md | grep "lista"`
- **Files**: `docs/SESSION_CONTEXT_20260618.md`
- **Complexidade**: Baixa

### Task 3: Reescrever tabela de skills instaladas (linhas 77-108)
- **Acceptance**: Tabela contém 49 linhas (uma por skill), em ordem alfabética, com coluna "Origem" correta
- **Verify**: `grep -c "^\| \`" docs/SESSION_CONTEXT_20260618.md` retorna ≥49
- **Files**: `docs/SESSION_CONTEXT_20260618.md`
- **Complexidade**: Média

### Task 4: Atualizar pendências (linhas 122-140)
- **Acceptance**: "Rodar setup.sh" mostra ⏳; "Remover script obsoleto" mostra ✅; "Verificar funcionamento" mostra ✅
- **Verify**: `grep -n "⏳\|✅" docs/SESSION_CONTEXT_20260618.md`
- **Files**: `docs/SESSION_CONTEXT_20260618.md`
- **Complexidade**: Baixa

### Task 5: Adicionar seção "Sessão de Unificação" (após linha 210)
- **Acceptance**: Nova seção contém data 08/07/2026, lista de commits, ADR-008, e detalhes das unificações
- **Verify**: `grep -n "Sessão de Unificação" docs/SESSION_CONTEXT_20260618.md`
- **Files**: `docs/SESSION_CONTEXT_20260618.md`
- **Complexidade**: Baixa

## Riscos

| Risco | Mitigação |
|---|---|
| Numeração de linhas pode ficar incorreta após edições | Usar `sed` ou editar por blocos, verificando numeração |
| Ordem alfabética pode ficar incorreta | Ordenar lista completa antes de inserir |
| Referências cruzadas podem quebrar | Verificar links internos após edição |

## Ordem de Implementação

1. Task 1 (contagens) — isolated, sem dependências
2. Task 2 (referência modificada) — isolated, sem dependências
3. Task 3 (tabela de skills) — isolated, sem dependências
4. Task 4 (pendências) — isolated, sem dependências
5. Task 5 (seção nova) — isolated, sem dependências

Todas as tasks são independentes e podem ser executadas em qualquer ordem.

## Verificação Final

```bash
# 1. Verificar que todas as 49 skills estão listadas
grep -c "^\| \`" docs/SESSION_CONTEXT_20260618.md

# 2. Verificar contagens atualizadas
grep -n "49 skills" docs/SESSION_CONTEXT_20260618.md

# 3. Verificar pendências
grep -n "⏳\|✅" docs/SESSION_CONTEXT_20260618.md

# 4. Verificar nova seção
grep -n "Sessão de Unificação" docs/SESSION_CONTEXT_20260618.md

# 5. Verificar que não há referências antigas a "27 skills"
grep -n "27 skills" docs/SESSION_CONTEXT_20260618.md
```

## Checklist de Implementação

- [ ] Criar feature branch `feature/atualizar-session-context-49-skills`
- [x] Task 1: Atualizar linhas 34-35 – Concluído em [08/07/2026:13:36]
- [x] Task 2: Atualizar linha 45 – Concluído em [08/07/2026:13:36]
- [x] Task 3: Reescrever linhas 77-108 com 49 skills – Concluído em [08/07/2026:13:40]
- [ ] Task 4: Atualizar linhas 122-140 com status
- [x] Task 5: Adicionar seção após linha 210 – Concluído em [08/07/2026:13:47]
- [ ] Code review: verificar integridade do documento
- [ ] Commit com mensagem descritiva
- [ ] Merge na branch main
