# ADR-002: Usar formato "agente": "deny" para RBAC de subagentes

## Status
Accepted

## Date
2026-07-05

## Context
O OpenCode requer um formato específico para configurar permissões RBAC (Role-Based Access Control) de subagentes. O formato correto é `"agente": "perm"`, não `"perm": ["agente"]`. O formato array é inválido e silenciosamente ignorado pelo OpenCode, causando falhas de isolamento entre subagentes.

## Decision
Usar formato `"agente": "deny"` para isolar subagentes no `opencode.json`. Cada subagente deve negar todos os outros subagentes explicitamente.

**Exemplo correto**:
```json
"rbac": {
  "task-build": "deny",
  "git-commit": "deny",
  "code-review": "deny",
  "dev": "deny"
}
```

**Exemplo incorreto** (IGNORADO pelo OpenCode):
```json
"rbac": {
  "deny": ["task-build"]
}
```

## Alternatives Considered

### Formato array (inválido)
- Pros: Sintaxe mais concisa
- Cons: Silenciosamente ignorado pelo OpenCode; subagentes ficam sem isolamento
- Rejected: Causa falhas de segurança — subagentes podem acessar recursos não autorizados

### Não configurar RBAC
- Pros: Zero configuração
- Cons: Subagentes ficam sem isolamento; qualquer subagente pode invocar outros
- Rejected: Viola princípio de menor privilégio

## Consequences
- **Positivo**: Subagentes ficam isolados; cada um só acessa seus próprios recursos
- **Positivo**: Previne acesso não autorizado entre subagentes
- **Positivo**: Formato validado e documentado no AGENTS.md
- **Negativo**: Requer manutenção manual ao adicionar novos subagentes
- **Negativo**: Configuração verbosa (cada subagente lista todos os outros)

**Referência**: Ver `AGENTS.md` (seção "RBAC syntax no opencode.json") para documentação completa.
