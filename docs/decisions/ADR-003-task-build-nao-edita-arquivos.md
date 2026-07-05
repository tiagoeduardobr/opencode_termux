# ADR-003: task-build delega toda edição de código para dev

## Status
Accepted

## Date
2026-07-05

## Context
O agente `task-build` é o orquestrador principal do pipeline. Se ele também editasse código, haveria confusão de responsabilidades e dificuldade de rastreabilidade de mudanças. A separação clara entre orquestração e implementação é fundamental para manter a qualidade e a auditabilidade do sistema.

## Decision
`task-build` NUNCA edita arquivos diretamente. Toda edição de código é delegada para o subagente `dev`. `task-build` apenas orquestra: recebe tarefa, delega planejamento, cria branch, delega implementação, delega revisão e delega commit.

## Alternatives Considered

### Edição direta pelo task-build
- Pros: Menos complexidade de orquestração
- Cons: Viola separação de responsabilidades; dificulta rastreabilidade; cria dependência circular
- Rejected: Torna o sistema mais frágil e difícil de manter

### Edição por múltiplos agentes
- Pros: Flexibilidade
- Cons: Condições de corrida; dificuldade de resolver conflitos de merge
- Rejected: Complica demais o pipeline sem benefício claro

## Consequences
- **Positivo**: Separação clara de responsabilidades (orquestração vs. implementação)
- **Positivo**: Melhor rastreabilidade — cada mudança rastreável ao `dev`
- **Positivo**: `task-build` fica mais leve e focado em coordenação
- **Positivo**: Previne erros de edição acidental pelo orquestrador
- **Negativo**: Requer comunicação adicional entre `task-build` e `dev`
- **Negativo**: Mais um passo no pipeline (delegação)

**Referência**: Ver `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 2.1) para detalhes do workflow.
