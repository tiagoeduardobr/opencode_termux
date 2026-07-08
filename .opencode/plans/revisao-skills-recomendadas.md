# TASK-07: Avaliação de Novas Skills para o Repositório

## Contexto

Repositório `opencode_termux` focado em:
- **Ambiente**: Termux (Android) com Ubuntu via proot
- **Stack principal**: Python/FastAPI (já usado)
- **Infra**: Cloudflare Quick Tunnel, scripts bash, ntfy.sh
- **Objetivo**: Config OpenCode global compartilhável entre projetos

## Skills Atuais (41)

Conforme `SESSION_CONTEXT_20260618.md` e contagem atual:
- Linguagens: `python-pro`, `javascript-typescript`
- Frameworks: `fastapi-expert`
- Qualidade: `code-reviewer`, `staff-engineer-review`, `requesting-code-review`, `receiving-code-review`, `test-master`, `test-driven-development`, `verification-before-completion`
- Debugging: `systematic-debugging`
- Segurança: `secure-code-guardian`, `api-security-best-practices`
- Design: `frontend-design`, `designing-frontend-interfaces`, `web-design-guidelines`, `design-system-patterns`, `design-tokens`, `alpine-js`
- Docs: `documentation-and-adrs`, `code-documenter`, `coauthoring-docs`, `content-research-writer`, `pandoc-docs`
- Workflow: `executing-plans`, `writing-plans`, `spec-driven-development`, `brainstorming`, `dispatching-parallel-agents`, `subagent-driven-development`, `using-superpowers`, `using-git-worktrees`, `finishing-a-development-branch`
- Outros: `backlog-curator`, `changelog-generator`, `data-science-expert`, `jupyter-notebook`, `postgres-pro`

## Skills Upstream Disponíveis (lista preliminar)

### Linguagens
- `go-expert`, `rust-expert`, `cpp-expert`, `csharp-expert`, `java-expert`, `php-expert`, `swift-expert`, `kotlin-expert`, `sql-expert`

### Frameworks
- `react-expert`, `nextjs-expert`, `vue-expert`, `angular-expert`, `nestjs-expert`, `django-expert`, `spring-boot-expert`, `laravel-expert`, `rails-expert`, `dotnet-expert`, `react-native-expert`, `flutter-expert`, `wordpress-expert`

### Infra
- `kubernetes-expert`, `terraform-engineer`, `devops-engineer`, `cloud-architect`, `sre-engineer`, `monitoring-expert`, `chaos-engineering`, `embedded-systems`

### Qualidade
- `api-design`, `graphql-expert`, `microservices-expert`, `security-reviewer`, `debugging-wizard`

### Especializado
- `salesforce-developer`, `shopify-expert`, `mcp-development`, `prompt-engineer`, `rag-architect`, `fine-tuning-expert`

### Workflow
- `feature-forge`, `architecture-designer`, `fullstack-guardian`

## Filtros de Prioridade Aplicados

1. ✅ **Relevante para Python/FastAPI** — Django pode ser usado em projetos futuros, SQL é essencial
2. ✅ **Relevante para revisão de código e qualidade** — Complementar skills existentes
3. ✅ **Relevante para DevOps/infra** — Docker, Cloud, SRE, Monitoring são críticos
4. ❌ **NÃO relevante**: React, Vue, Angular, Next.js, NestJS, Laravel, Rails, .NET, React Native, Flutter, WordPress

## Skills Recomendadas (Máx. 10)

### 1. `devops-engineer` — **PRIORIDADE ALTA**
- **Caso de uso**: Gerenciar containerização do proot Ubuntu, criar Dockerfiles para ambientes de desenvolvimento, otimizar imagens
- **Justificativa**: O repositório já usa proot (similar a containers). Docker seria natural para:
  - Criar ambientes de desenvolvimento replicáveis
  - Testar scripts em diferentes distros Linux
  - Documentar dependências do sistema
- **Relevância**: Infra/DevOps — alinhado com arquitetura atual

### 2. `cloud-architect` — **PRIORIDADE ALTA**
- **Caso de uso**: Otimizar uso do Cloudflare, planejar migração de Quick Tunnel para Named Tunnel, configurar cache e segurança
- **Justificativa**: O repositório depende fortemente do Cloudflare para exposição do OpenCode Web. Esta skill ajudaria a:
  - Configurar regras de cache e segurança
  - Planejar Named Tunnels (mais estáveis que Quick Tunnels)
  - Implementar rate limiting e WAF
- **Relevância**: DevOps/infra — melhoria direta da infra atual

### 3. `sql-expert` — **PRIORIDADE ALTA**
- **Caso de uso**: Otimizar queries PostgreSQL, criar migrations, configurar replicas, performance tuning
- **Justificativa**: Já temos `postgres-pro`, mas `sql-expert` pode oferecer:
  - Visão mais ampla de SQL (não só PostgreSQL)
  - Padrões de modelagem de dados
  - Otimização de queries complexas
- **Relevância**: Python/FastAPI — bancos de dados são essenciais

### 4. `sre-engineer` — **PRIORIDADE MÉDIA**
- **Caso de uso**: Implementar monitoramento do tunnel, alertas, SLOs, incident response
- **Justificativa**: O repositório expõe serviços web (OpenCode) — SRE ajudaria a:
  - Definir SLIs/SLOs para disponibilidade
  - Configurar alertas via ntfy.sh quando tunnel cair
  - Criar runbooks de incident response
- **Relevância**: DevOps/infra — confiabilidade do serviço

### 5. `monitoring-expert` — **PRIORIDADE MÉDIA**
- **Caso de uso**: Implementar métricas de uso, logs estruturados, dashboards
- **Justificativa**: Complementar SRE com:
  - Métricas de latência do tunnel
  - Logs de uso do OpenCode Web
  - Dashboards de saúde do sistema
- **Relevância**: DevOps/infra — observabilidade

### 6. `security-reviewer` — **PRIORIDADE MÉDIA**
- **Caso de uso**: Revisar scripts bash para vulnerabilidades, validar inputs, auditoria de segurança
- **Justificativa**: Já temos `secure-code-guardian` e `api-security-best-practices`, mas `security-reviewer` pode oferecer:
  - Foco em scripts bash (injection, privilege escalation)
  - Auditoria de configs (Cloudflare, SSH)
  - Checklist de segurança para ambientes Android/Termux
- **Relevância**: Qualidade — segurança é crítica

### 7. `debugging-wizard` — **PRIORIDADE MÉDIA**
- **Caso de uso**: Debug avançado de scripts bash, diagnóstico de problemas de rede, tracing de erros
- **Justificativa**: Complementar `systematic-debugging` com:
  - Técnicas específicas para bash
  - Debug de problemas de proot (getifaddrs, etc.)
  - Ferramentas de tracing (strace, ltrace)
- **Relevância**: Qualidade — debugging é constante

### 8. `microservices-expert` — **PRIORIDADE BAIXA**
- **Caso de uso**: Se o repositório evoluir para múltiplos serviços (API + workers + frontend)
- **Justificativa**: Pode ser útil se:
  - OpenCode Web virar microservices
  - Adicionar workers assíncronos
  - Implementar message queues
- **Relevância**: Arquitetura — preparação para escalabilidade

### 9. `terraform-engineer` — **PRIORIDADE BAIXA**
- **Caso de uso**: Infra as code para provisionar recursos Cloudflare, configurar DNS, gerenciar secrets
- **Justificativa**: Pode ser útil para:
  - Automatizar configuração do Cloudflare via Terraform
  - Versionar infraestrutura
  - Gerenciar múltiplos ambientes
- **Relevância**: DevOps/infra — automação avançada

### 10. `architecture-designer` — **PRIORIDADE BAIXA**
- **Caso de uso**: Revisar arquitetura do repositório, sugerir melhorias estruturais
- **Justificativa**: Pode ajudar a:
  - Revisar organização de scripts
  - Sugerir padrões de projeto
  - Planejar evolução arquitetural
- **Relevância**: Workflow — melhoria contínua

## Skills NÃO Recomendadas (com justificativa)

### Frameworks não utilizados
- `react-expert`, `nextjs-expert`, `vue-expert`, `angular-expert`, `nestjs-expert`, `laravel-expert`, `rails-expert`, `dotnet-expert`, `react-native-expert`, `flutter-expert`, `wordpress-expert`
- **Motivo**: O repositório não usa nenhum desses frameworks. Python/FastAPI é o stack principal.

### Linguagens não utilizadas
- `go-expert`, `rust-expert`, `cpp-expert`, `csharp-expert`, `java-expert`, `php-expert`, `swift-expert`, `kotlin-expert`
- **Motivo**: O repositório é focado em Python e bash. Não há código nessas linguagens.

### Especializados demais
- `salesforce-developer`, `shopify-expert`, `mcp-development`, `prompt-engineer`, `rag-architect`, `fine-tuning-expert`
- **Motivo**: Fora do escopo do repositório (scripts Termux + config OpenCode).

### Outros não prioritários
- `chaos-engineering` — Muito avançado para o estágio atual
- `embedded-systems` — Foco em Android/Termux, não hardware embarcado
- `graphql-expert` — Não há uso de GraphQL no repositório
- `django-expert` — FastAPI já é o framework escolhido

## Priorização Final

| Prioridade | Skill | Justificativa Resumida |
|------------|-------|------------------------|
| **ALTA** | `devops-engineer` | Containerização natural do proot |
| **ALTA** | `cloud-architect` | Melhoria do uso do Cloudflare |
| **ALTA** | `sql-expert` | Complementar postgres-pro |
| **MÉDIA** | `sre-engineer` | Confiabilidade do serviço |
| **MÉDIA** | `monitoring-expert` | Observabilidade |
| **MÉDIA** | `security-reviewer` | Segurança de scripts bash |
| **MÉDIA** | `debugging-wizard` | Debug avançado |
| **BAIXA** | `microservices-expert` | Preparação para escalabilidade |
| **BAIXA** | `terraform-engineer` | Automação avançada |
| **BAIXA** | `architecture-designer` | Melhoria arquitetural |

## Reconciliação com TASK-06

Comparação das skills de alta prioridade identificadas na TASK-06 (revisão upstream) com as recomendações desta TASK-07.

### Skills de Alta Prioridade da TASK-06 não incluídas como ALTA na TASK-07

| Skill TASK-06 | Prioridade TASK-06 | Status na TASK-07 | Justificativa da Exclusão/Reclassificação |
|---|---|---|---|
| `kubernetes-specialist` | ALTA | **Não incluída** | O repositório não usa containers orquestrados. O proot não é Kubernetes. Relevante apenas se houver migração para containers em produção — cenário futuro não confirmado. |
| `database-optimizer` | ALTA | **Não incluída** | Já temos `postgres-pro` que cobre otimização de queries PostgreSQL. `database-optimizer` seria redundante para o estágio atual. Reavaliar se surgirem necessidades de performance além do PostgreSQL. |
| `pandas-pro` | ALTA | **Não incluída** | Foco do repositório é infra/scripts, não análise de dados. `data-science-expert` e `jupyter-notebook` já cobrem cenários de dados. Relevante apenas para projetos futuros com dados tabulares. |
| `rag-architect` | ALTA | **Não incluída** | Fora do escopo atual. O repositório não implementa sistemas RAG. Relevante se houver projetos de IA com busca semântica no futuro. |
| `ml-pipeline` | ALTA | **Não incluída** | Fora do escopo atual. Não há projetos de ML no repositório. Relevante apenas se surgirem necessidades de pipelines de ML. |
| `terraform-engineer` | ALTA | **BAIXA** | Relevante, mas não prioritária. A configuração atual é manual via Cloudflare. Automatizar com Terraform é avançado demais para o estágio atual. Mantida como BAIXA para consideração futura. |
| `sre-engineer` | ALTA | **MÉDIA** | Relevante, mas o repositório ainda não tem serviços em produção que justifiquem SRE completo. Mantida como MÉDIA para implementação gradual. |
| `monitoring-expert` | ALTA | **MÉDIA** | Relevante, mas complementa SRE. Monitoramento detalhado é importante, mas não urgente no estágio atual. Mantida como MÉDIA. |

### Skills da TASK-06 incluídas na TASK-07 (consistência)

| Skill | Prioridade TASK-06 | Prioridade TASK-07 | Status |
|---|---|---|---|
| `devops-engineer` | ALTA | ALTA | ✅ Consistente |
| `cloud-architect` | ALTA | ALTA | ✅ Consistente |

### Skills da TASK-07 não presentes na TASK-06 (adições)

| Skill | Prioridade TASK-07 | Justificativa da Adição |
|---|---|---|
| `sql-expert` | ALTA | Complementar `postgres-pro` com visão mais ampla de SQL. Identificada como relevante na TASK-07. |
| `security-reviewer` | MÉDIA | Foco em scripts bash e configs. Não listada explicitamente na TASK-06, mas relevante para o repositório. |
| `debugging-wizard` | MÉDIA | Complementar `systematic-debugging`. Não listada na TASK-06, mas útil para debug avançado. |
| `microservices-expert` | BAIXA | Preparação para escalabilidade. Não listada na TASK-06. |
| `architecture-designer` | BAIXA | Melhoria arquitetural. Listada como `architecture-designer` na TASK-06 (MÉDIA). |

### Conclusão da Reconciliação

**Decisão:** Manter as recomendações da TASK-07 conforme reclassificadas, com as seguintes justificativas:

1. **Excluídas por escopo**: `kubernetes-specialist`, `pandas-pro`, `rag-architect`, `ml-pipeline` — fora do foco atual do repositório
2. **Reclassificadas por redundância**: `database-optimizer` — coberta por `postgres-pro`
3. **Reclassificadas por maturidade**: `terraform-engineer`, `sre-engineer`, `monitoring-expert` — relevantes, mas não prioritárias no estágio atual

**Recomendação:** Reavaliar estas exclusões na TASK-08 quando houver versões atualizadas das skills upstream.

## Próximos Passos

1. **TASK-08**: Verificar versões atualizadas das skills upstream
2. **TASK-09**: Decidir quais instalar (após aprovação do usuário)
3. **TASK-10**: Instalar skills aprovadas

## Notas

- Recomendação: Instalar primeiro as 3 skills de PRIORIDADE ALTA, validar uso, depois considerar as de MÉDIA.
- Priorizar estabilidade: não instalar skills sem necessidade concreta.

---

**Data da análise:** 07/07/2026:00:43
**Analisador:** Agente Dev (TASK-07)