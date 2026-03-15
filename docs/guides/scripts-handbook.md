# Scripts Handbook

Atualizado em: 2026-03-15

Este guia explica, em linguagem direta, o que cada script do repo faz, quando usar e qual comando copiar.

## Ordem mais comum de uso

Para subir o ambiente local do zero:

1. `.\scripts\start-pt-docker-sql.ps1`
2. `.\scripts\restore-pt-docker-dbs.ps1`
3. `.\scripts\patch-pt-client-localhost.ps1`
4. `.\scripts\fix-pt-local-runtime.ps1`
5. `.\scripts\start-pt-server.ps1`

Para desligar:

1. `.\scripts\stop-pt-server.ps1`
2. `.\scripts\stop-pt-docker-sql.ps1`

## Resumo rapido

| Script | O que faz | Quando usar |
| --- | --- | --- |
| `start-pt-docker-sql.ps1` | sobe o SQL Server em Docker | antes de restaurar ou usar o banco |
| `stop-pt-docker-sql.ps1` | para o SQL em Docker | quando terminar os testes |
| `restore-pt-docker-dbs.ps1` | restaura os bancos e garante a conta `admin` | no primeiro setup ou quando quiser voltar ao estado base |
| `patch-pt-client-localhost.ps1` | corrige o `game.dll` para localhost | quando o client aponta para IP errado |
| `fix-pt-local-runtime.ps1` | aplica workarounds do ambiente local | quando o runtime vier quebrado ou apos restore |
| `start-pt-server.ps1` | abre janelas para login server e game server | para rodar o servidor |
| `watch-pt-server.ps1` | acompanha o `Log.txt` em tempo real | e chamado pelo script de start |
| `stop-pt-server.ps1` | fecha `Server.exe`, janelas de monitor e `AutoRestart.bat` | para desligar tudo do projeto |
| `provision-pt-test-account.ps1` | cria ou atualiza uma conta com GM e vincula um char | quando quiser uma conta de teste propria |
| `assign-pt-character-to-account.ps1` | move um char existente para uma conta | quando o char existe mas esta em outra conta |
| `clone-pt-character-template.ps1` | cria char novo clonando um template pronto | quando o client nao consegue criar personagem |
| `find-pt-item.ps1` | procura item por nome, code ou ID | quando precisar usar `/getitem` |
| `find-pt-map.ps1` | procura mapa por nome, short name ou ID | quando precisar usar `/wrap` |
| `find-pt-monster.ps1` | procura monstro por nome ou ID | quando precisar ajustar spawn, exp ou drop |
| `export-pt-reference-docs.ps1` | gera markdowns de mapa, item e monstro | quando quiser atualizar as docs de referencia |

## Scripts de banco e infraestrutura

### `start-pt-docker-sql.ps1`

Comando:

```powershell
.\scripts\start-pt-docker-sql.ps1
```

O que ele faz:

- verifica se o Docker esta pronto
- abre o Docker Desktop se necessario
- cria ou sobe o container `priston-sql`
- expoe a porta `1433`
- monta `Files/DBS/extracted` dentro do container
- espera o SQL aceitar conexao

Quando usar:

- sempre antes de restaurar bancos
- sempre antes de scripts que dependem de SQL

### `stop-pt-docker-sql.ps1`

Comando:

```powershell
.\scripts\stop-pt-docker-sql.ps1
```

O que ele faz:

- para o container `priston-sql`

## Scripts de banco e contas

### `restore-pt-docker-dbs.ps1`

Comando:

```powershell
.\scripts\restore-pt-docker-dbs.ps1
```

O que ele faz:

- restaura `ClanDB`, `EventDB`, `GameDB`, `ItemDB`, `LogDB`, `ServerDB`, `SkillDBNew` e `UserDB`
- cria `ChatDB` e `SkillDB` se nao existirem
- recria ou atualiza a conta `admin`

Observacao importante:

- ele sobrescreve o `UserDB`
- isso significa que contas customizadas feitas depois podem sumir
- se isso acontecer, rode `provision-pt-test-account.ps1` de novo

### `provision-pt-test-account.ps1`

Exemplo:

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'dedezin' `
  -Password 'dedezin123' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 4
```

O que ele faz:

- cria ou atualiza a conta
- gera o hash correto da senha
- seta a conta como ativa
- aplica GM
- vincula o char informado

### `assign-pt-character-to-account.ps1`

Exemplo:

```powershell
.\scripts\assign-pt-character-to-account.ps1 `
  -AccountName 'dedezin' `
  -CharacterName 'test_ps_100'
```

O que ele faz:

- muda o dono do personagem existente

### `clone-pt-character-template.ps1`

Exemplo:

```powershell
.\scripts\clone-pt-character-template.ps1 `
  -AccountName 'dedezin' `
  -NewCharacterName 'MeuPike' `
  -TemplateCharacterName 'test_ps_100' `
  -GameMasterLevel 4
```

O que ele faz:

- copia uma linha de `CharacterInfo`
- copia o `.chr` do personagem template
- cria um char novo jogavel

## Scripts de correcao do runtime

### `patch-pt-client-localhost.ps1`

Comando:

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

O que ele faz:

- corrige `Files/Game/game.dll`
- troca o IP antigo pelo `127.0.0.1`
- cria `game.dll.bak`

Quando usar:

- quando vier um runtime pack novo
- quando acontecer `connection failed`

### `fix-pt-local-runtime.ps1`

Comando:

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

O que ele faz:

- corrige o gold do `Administrador` para evitar o cheat `99007`
- remove timers invalidos de premium
- vincula personagens de teste conhecidos a uma conta
- garante que os `.chr` de teste existam na pasta certa

Quando usar:

- logo apos restaurar o banco
- quando o runtime local vier com sujeira antiga

## Scripts para ligar e desligar o servidor

### `start-pt-server.ps1`

Comando:

```powershell
.\scripts\start-pt-server.ps1
```

Opcional, ja abrindo o client:

```powershell
.\scripts\start-pt-server.ps1 -OpenClient
```

Opcional, usando `AutoRestart.bat`:

```powershell
.\scripts\start-pt-server.ps1 -UseAutoRestart
```

O que ele faz:

- abre uma janela PowerShell para o login server
- abre outra janela PowerShell para o game server
- em cada janela, acompanha o `Log.txt`

### `watch-pt-server.ps1`

Esse script normalmente nao e rodado direto.
Ele e usado pelo `start-pt-server.ps1`.

O que ele faz:

- inicia o `Server.exe`
- ou inicia o `AutoRestart.bat`
- deixa a janela parada no `Log.txt`

### `stop-pt-server.ps1`

Comando:

```powershell
.\scripts\stop-pt-server.ps1
```

O que ele faz:

- fecha `Server.exe` do login server
- fecha `Server.exe` do game server
- fecha as janelas de monitor
- fecha o `AutoRestart.bat` se estiver em uso

## Scripts de consulta rapida

### `find-pt-item.ps1`

Exemplos:

```powershell
.\scripts\find-pt-item.ps1 -Search "Abyss Axe"
.\scripts\find-pt-item.ps1 -Search "wa131"
.\scripts\find-pt-item.ps1 -Search "16854272"
```

Quando usar:

- antes de `/getitem`
- antes de editar drop ou item distributor

### `find-pt-map.ps1`

Exemplos:

```powershell
.\scripts\find-pt-map.ps1 -Search "Ricarten"
.\scripts\find-pt-map.ps1 -Search "ric"
.\scripts\find-pt-map.ps1 -Search "3"
```

Quando usar:

- antes de `/wrap`
- para descobrir `mapId`

### `find-pt-monster.ps1`

Exemplos:

```powershell
.\scripts\find-pt-monster.ps1 -Search "Kelvezu"
.\scripts\find-pt-monster.ps1 -Search "1188"
```

Quando usar:

- antes de mexer em exp de monstro
- antes de mexer em drop
- antes de comandos SQL de monster

### `export-pt-reference-docs.ps1`

Comando:

```powershell
.\scripts\export-pt-reference-docs.ps1
```

O que ele faz:

- gera `docs/reference/map-id-reference.md`
- gera `docs/reference/item-id-reference.md`
- gera `docs/reference/monster-id-reference.md`

Quando usar:

- depois de atualizar o banco
- depois de trocar runtime pack
- quando quiser regenerar as listas para consulta

## Fluxos prontos

### Primeiro setup local

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\restore-pt-docker-dbs.ps1
.\scripts\patch-pt-client-localhost.ps1
.\scripts\fix-pt-local-runtime.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

### Restaurou tudo e perdeu sua conta customizada

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'dedezin' `
  -Password 'dedezin123' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 4
```

### Quer criar um novo char de teste

```powershell
.\scripts\clone-pt-character-template.ps1 `
  -AccountName 'dedezin' `
  -NewCharacterName 'MeuPike' `
  -TemplateCharacterName 'test_ps_100' `
  -GameMasterLevel 4
```

## Onde encontrar mais detalhes

- `docs/guides/server-start-guide.md`
- `docs/guides/setup-run-test-guide.md`
- `docs/guides/account-and-character-management.md`
- `docs/guides/client-localhost-patch-guide.md`
- `docs/troubleshooting/local-runtime-known-issues.md`
