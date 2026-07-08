# ADR-008: Adição de 10 skills upstream do synapse-ai-hub/opencode-skills

## Status
Accepted

## Date
2026-07-07

## Context
O repositório precisava de skills adicionais para cobrir áreas essenciais de DevOps, Cloud, SQL, SRE, Monitoramento, Segurança, Debug, Arquitetura, Terraform e Microservices. As skills existentes (49) não atendiam completamente a esses domínios, limitando a capacidade do agente em tarefas especializadas.

## Decision
Instalar 10 skills do repositório upstream `synapse-ai-hub/opencode-skills`, que mantém um catálogo atualizado e bem documentado de skills para o OpenCode.

### Skills instaladas:
1. **devops-engineer** — Práticas DevOps, CI/CD, automação
2. **cloud-architect** — Arquitetura cloud, AWS/Azure/GCP
3. **sql-pro** — Otimização e design de bancos SQL
4. **sre-engineer** — Site Reliability Engineering, SLIs/SLOs
5. **monitoring-expert** — Monitoramento, alertas, observabilidade
6. **security-reviewer** — Revisão de segurança, OWASP
7. **debugging-wizard** — Debug avançado, profiling
8. **architecture-designer** — Padrões arquiteturais, design de sistemas
9. **terraform-engineer** — Infraestrutura como código, Terraform
10. **microservices-architect** — Arquitetura de microsserviços

## Alternatives Considered
- **Desenvolver skills internamente** — Rejeitado: alto custo de manutenção e já existem soluções maduras upstream
- **Usar múltiplos repositórios** — Rejeitado: complexidade de sincronização e inconsistência de formato
- **Manter apenas as skills existentes** — Rejeitado: limitava capacidades em áreas críticas de infraestrutura

## Consequences
- **Positivo**: Total de skills: 41 → 51 (24% de aumento)
- **Positivo**: Melhoria significativa na cobertura de DevOps/infraestrutura
- **Positivo**: Skills seguem padrão upstream (SKILL.md + references/) com documentação consistente
- **Positivo**: Acesso a padrões e boas práticas de uma comunidade ativa
- **Negativo**: Necessidade de manter sincronização com upstream para atualizações futuras
- **Negativo**: Aumento do tamanho do repositório (mais arquivos e dependências)
- **Negativo**: Possível conflito de nomenclatura com skills existentes (mitigado: verificações de duplicata foram realizadas)

## Related
- [SESSION_CONTEXT_20260618.md](../SESSION_CONTEXT_20260618.md) — Contexto da sessão de criação
- [MULTI_AGENT_ORCHESTRATION.md](../MULTI_AGENT_ORCHESTRATION.md) — Orquestração de agentes que utilizam as skills
