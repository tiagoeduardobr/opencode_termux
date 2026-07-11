> **Fonte**: Documentação interna do projeto opencode_termux
> **Snapshot**: 11/07/2026

# Tailscale

> Tailscale é uma solução de mesh VPN baseada em WireGuard que permite acesso direto entre dispositivos sem configuração de portas ou encaminhamento. Diferente do Cloudflare Quick Tunnel, o Tailscale preserva SSE e WebSocket sem interferência do proxy.

## Visão Geral

### O que é Tailscale

Tailscale cria uma rede privada entre seus dispositivos usando WireGuard como protocolo de transporte. Cada dispositivo recebe um IP estável na rede Tailscale (faixa `100.x.x.x`), acessível diretamente sem exposição de portas na internet.

### Por que Tailscale para este projeto

- **SSE e WebSocket funcionam nativamente** — o Cloudflare Quick Tunnel limita SSE a 200 requisições e não suporta WebSocket. O Tailscale não impõe essas restrições.
- **Acesso direto** — conexão ponto a ponto via WireGuard, sem proxy intermediário.
- **Estabilidade** — IP fixo por dispositivo, sem subdomínios efêmeros.
- **Segurança** — tráfego criptografado ponta a ponta, sem exposição à internet pública.

### Diferença do Cloudflare Quick Tunnel

| Aspecto | Cloudflare Quick Tunnel | Tailscale |
|---|---|---|
| Acesso | Via URL `*.trycloudflare.com` | Via IP `100.x.x.x` |
| SSE | Limitado (200 req) | Sem limitação |
| WebSocket | Não suportado | Suportado |
| Autenticação | Nenhuma | Conta Tailscale |
| Portas expostas | Nenhuma (via proxy) | Nenhuma (via WireGuard) |
| Configuração mínima | Instalar cloudflared | Instalar tailscale, login |

> **NOTA**: Tailscale e Cloudflare Quick Tunnel coexistem pacificamente. Ambos estão disponíveis e são mutuamente exclusivos para uso — use um ou outro conforme a necessidade.

## Pré-requisitos

- Android 12 ou superior
- Termux instalado
- F-Droid com Tailscale instalado ([link](https://f-droid.org/en/packages/com.tailscale.ipn/))
- proot-distro configurado com Ubuntu
- opencode instalado dentro do proot

## Instalação

### No Termux

```bash
pkg install tailscale
```

### Configurar e autenticar

```bash
tailscale up
```

O comando exibirá uma URL de login. Abra no navegador e autentique com sua conta Tailscale.

### Verificar instalação

```bash
tailscale status
```

A saída deve listar seus dispositivos conectados.

## Configuração

### Iniciar o daemon

```bash
tailscaled &
```

> O daemon `tailscaled` deve estar rodando antes de usar qualquer comando Tailscale. Ele pode ser iniciado manualmente ou junto com o boot do Termux.

### Verificar status

```bash
tailscale status
tailscale ip
```

O comando `tailscale ip` retorna o IP atribuído ao dispositivo (formato `100.x.x.x`).

### Configurar acesso ao IP Tailscale

Após autenticar, o dispositivo recebe um IP na rede Tailscale. Este IP é acessível por qualquer outro dispositivo na mesma rede Tailscale.

Para acessar o opencode de outro dispositivo (ex: Chromebook):

1. Instale o Tailscale no Chromebook
2. Autentique com a mesma conta
3. Acesse `http://<IP_TAILSCALE_TERMUX>:4096`

## Uso

### Iniciar opencode web com Tailscale

```bash
opencode_tailscale
```

Este comando:
1. Verifica se `tailscaled` está rodando
2. Obtém o IP Tailscale do dispositivo
3. Inicia o opencode web no proot (`127.0.0.1:4096`)
4. Configura `tailscale serve` na porta 4096
5. Envia notificação com a URL de acesso

### Parar todos os serviços

```bash
opencode_tailscale_stop
```

Este comando:
1. Para o `tailscale serve`
2. Para o opencode web
3. Limpa processos órfãos
4. Reseta o terminal (`stty sane`)

### Arquivos de referência

| Arquivo | Conteúdo |
|---|---|
| `$PREFIX/tmp/opencode_tailscale.pid` | PID do processo principal |
| `$PREFIX/tmp/opencode_tailscale_url.txt` | URL ativa (handoff) |
| `$PREFIX/tmp/opencode_tailscale.log` | Log de diagnóstico |

## Arquitetura

```
┌─────────────┐     tailscale serve     ┌──────────────┐
│  Termux     │◄───────────────────────►│  Chromebook  │
│  (Android)  │   http://100.x.x.x:4096 │  (peer)      │
│             │                          │              │
│  ┌───────┐  │                          │  Browser     │
│  │ proot │──┤ 127.0.0.1:4096           │              │
│  │opencode│  │                          └──────────────┘
│  └───────┘  │
└─────────────┘
```

**Fluxo:**

1. o `opencode web` escuta em `127.0.0.1:4096` dentro do proot
2. `tailscale serve` expõe a porta 4096 na rede Tailscale
3. O peer (Chromebook) acessa via `http://100.x.x.x:4096`

## Troubleshooting

### tailscaled não está rodando

**Sintoma:** Comando `tailscale status` retorna erro ou timeout.

**Solução:**
```bash
tailscaled &
sleep 2
tailscale status
```

### IP Tailscale não detectado

**Sintoma:** `tailscale ip` retorna erro ou vazio.

**Solução:**
```bash
tailscale up
tailscale ip
```

Verifique se o login foi concluído no navegador.

### Porta 4096 já em uso

**Sintoma:** Erro ao iniciar opencode web — `Address already in use`.

**Solução:**
```bash
ss -tlnp | grep 4096 || fuser 4096/tcp 2>/dev/null || echo "Use: pkg install lsof && lsof -i :4096"
kill <PID>
```

Ou use porta alternativa alterando `OPENCODE_PORT` no `.env`.

### proot morre rapidamente

**Sintoma:** O processo do proot encerra imediatamente após iniciar.

**Solução:** Verifique o log de diagnóstico:
```bash
cat $PREFIX/tmp/opencode_tailscale.log
```

Causas comuns:
- `tailscaled` não está rodando
- Porta já em uso
- Permissões insuficientes

### opencode não inicia

**Sintoma:** Serviço inicia mas opencode web não responde.

**Solução:**
```bash
cat $PREFIX/tmp/opencode_tailscale.log
# Verificar se opencode está instalado dentro do proot
proot-distro login ubuntu -- opencode --version
```

### Erro "getifaddrs returned an error"

**Sintoma:** opencode web crasha com erro `getifaddrs returned an error` ao tentar usar `--hostname 0.0.0.0`.

**Solução:** Use `127.0.0.1` (default) dentro do proot. O `0.0.0.0` não funciona porque o proot não expõe interfaces de rede reais. O tailscale serve conecta via `127.0.0.1`.

→ Detalhes: `docs/proot-distro/README.md` (seção: networking limitations)

### Botão "Abrir" não funciona na notificação

**Sintoma:** Ao clicar no botão "Abrir" da notificação Termux, nada acontece.

**Solução:** Verifique se a URL está correta:
```bash
cat $PREFIX/tmp/opencode_tailscale_url.txt
```

Se a URL estiver correta, copie e cole manualmente no navegador. O botão de notificação pode não funcionar em todos os dispositivos Android.

## Referências

- `docs/proot-distro/README.md` — Login, `--shared-tmp`, troubleshooting do proot
- `docs/termux/filesystem-layout.md` — Paths do Termux, `$PREFIX`, handoff de arquivos
- `docs/cloudflare/quick-tunnel.md` — Alternativa via Cloudflare (mutuamente exclusivo)
