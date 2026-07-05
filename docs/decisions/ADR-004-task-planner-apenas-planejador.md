# ADR-004: task-planner é exclusivamente planejador

## Status
Accepted

## Date
2026-07-05

## Context
No pipeline de orquestração, é essencial que cada agente tenha uma responsabilidade bem definida. O `task-planner` foi criado para gerar planos adaptativos, mas se também implementasse código, causaria confusão sobre quem é responsável por quê. Esta decisão complementa ADR-003 (task-build não edita) ao estabelecer que o planejador também não implementa.

## Decision
`task-planner` é exclusivamente um planejador. Ele:
- Analisa a codebase
- Gera planos adaptativos salvos em `.opencode/plans/{timestamp}_{slug}.md`
- Nunca modifica código
- Nunca faz commit/push/merge

## Alternatives Considered

### Implementação direta pelo task-planner
- Pros: Menos delegação; pipeline mais rápido
- Cons: Confunde responsabilidades; planos menos focados; dificulta review independente
- Rejected: Planos ficam melhor quando o planejador não está envolvido na implementação

### Combinar planejamento e implementação em um agente
- Pros: Menos agentes para gerenciar
- Cons: Viola princípio de responsabilidade única; dificulta teste e manutenção
- Rejected: Separação permite evolução independente de cada etapa

## Consequences
- **Positivo**: Responsabilidades claras e não sobrepostas
- **Positivo**: Planos mais objetivos (foco em "o quê" e "porquê", não "como" implementar)
- **Positivo**: Review independente — quem planeja não implementa, reduzindo viés
- **Positivo**: Complementa ADR-003 para criar cadeia clara: task-planner → task-build → dev
- **Negativo**: Requer handoff explícito entre planejador e orquestrador
- **Negativo**: Planejador pode não ter contexto completo de implementação (compensado pelo dev)

**Referência**: Complementa ADR-003 (task-build não edita). Ver `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 2.2).
