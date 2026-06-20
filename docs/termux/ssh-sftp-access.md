> **Fonte**: Termux wiki + OpenCode termux project
> **Snapshot**: 20/06/2026
> **Formato**: Referência SSH/SFTP para acesso remoto ao Termux

# SSH/SFTP — Acesso Remoto ao Termux

Como acessar os arquivos do Termux via SSH/SFTP usando Termius ou qualquer cliente SSH.

---

## Instalar openssh

```bash
pkg install openssh -y
```

## Configurar senha

```bash
passwd
```

Digite e confirme a senha. Essa senha será usada para autenticação via SSH.

## Iniciar sshd

```bash
termux_ssh
```

O script:
1. Verifica se `openssh` está instalado
2. Inicia `sshd` na porta configurada (default: 8022)
3. Detecta o IP do dispositivo
4. Envia notificação push ntfy.sh com o comando SSH formatado
5. Envia notificação local Termux com botão "Copiar"

## Parar sshd

```bash
termux_ssh_stop
```

## Porta padrão

O sshd do Termux roda na porta **8022** (não 22). Isso evita conflito com outros serviços e não requer root.

## Configuração no Termius

1. Abra o Termius → **New Host**
2. Preencha:
   - **Hostname**: `<IP do dispositivo>` (ex: `192.168.1.100`)
   - **Port**: `8022`
   - **Username**: `root`
   - **Password**: (a senha que você definiu com `passwd`)
3. Salve e conecte

## Acessar via SFTP

### Via Termius
Após conectar via SSH no Termius:
- Clique no ícone **SFTP** na barra lateral
- Navegue pelos diretórios do Termux

### Via cliente SFTP separado
Use FileZilla, WinSCP, Cyberduck ou similar:
- **Host**: `<IP do dispositivo>`
- **Port**: `8022`
- **Username**: `root`
- **Password**: (a senha definida)
- **Protocol**: SFTP

## Caminhos acessíveis

| Caminho | Descrição |
|---|---|
| `$HOME` (`~`) | Diretório home do Termux (`/data/data/com.termux/files/home`) |
| `$PREFIX/tmp` | Temp (limpo ao reiniciar o Termux) |
| `/sdcard` | Armazenamento interno do Android |
| `/storage/emulated/0` | Armazenamento compartilhado |

> **⚠️ Limitação**: `$PREFIX/tmp` é apagado ao reiniciar o Termux. Para arquivos persistentes, use `~/storage` após rodar `termux-setup-storage`.

## Gerar chaves SSH (opcional)

Para autenticação por chave (mais segura que senha):

```bash
# Gerar par de chaves
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Copiar chave pública para o servidor
# (no Termius ou outro cliente, copie o conteúdo de ~/.ssh/id_ed25519.pub)
```

## Troubleshooting

| Problema | Solução |
|---|---|
| `Permission denied` | Verifique se a senha está correta com `passwd` |
| `Connection refused` | Verifique se sshd está rodando: `pgrep sshd` |
| IP não detectado | Verifique com `ip addr show` ou `ifconfig` |
| Porta bloqueada | Alguns roteadores bloqueiam portas não padrão — teste na rede local primeiro |
| SSH funciona mas SFTP não | Verifique se o cliente SFTP usa a porta 8022 (não 22) |

## Segurança

- O sshd roda como **root** no Termux (não é root real do Android)
- Use senha forte — o Termux está exposto na rede local
- Para acesso externo, use VPN ou Cloudflare Tunnel (não exponha porta 8022 na internet)
- Considere usar chaves SSH em vez de senhas para maior segurança
