# Guia para Ligar o Server

Atualizado em: 2026-03-15

Esta doc e focada so em subir o ambiente local e explicar o que cada script faz.

Use este guia se voce quer:

- ligar o SQL do projeto
- restaurar os bancos
- corrigir o client para localhost
- subir login server e game server
- abrir o jogo para testar

## Antes de comecar

Este fluxo assume:

- repo aberto na raiz `PristonTale-EU-main`
- pasta `Files/` presente dentro do repo
- Docker Desktop instalado, se voce for usar o fluxo com container

Conta padrao de teste:

- login: `admin`
- senha: `admin`

Conta adicional de teste preparada neste ambiente:

- login: `dedezin`
- senha: `dedezin123`
- privilegio de conta: `GameMasterType=1` e `GameMasterLevel=4`
- personagem vinculado: `test_ps_100`
- classe do personagem: pike
- level do personagem: 100

Importante:

- se voce rodar `.\scripts\restore-pt-docker-dbs.ps1` de novo, o `UserDB` sera restaurado do backup
- isso pode apagar contas customizadas e reverter a posse de personagens
- depois do restore, rode `.\scripts\provision-pt-test-account.ps1` para recriar `dedezin`

## Caminho mais curto

Na raiz do repo, rode nesta ordem:

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\restore-pt-docker-dbs.ps1
.\scripts\patch-pt-client-localhost.ps1
.\scripts\fix-pt-local-runtime.ps1
.\scripts\start-pt-server.ps1
```

Depois abra:

```powershell
.\Files\Game\Game.exe
```

Se quiser que o script tente abrir o client junto:

```powershell
.\scripts\start-pt-server.ps1 -OpenClient
```

## Ordem correta de uso

### 1. Subir o SQL

```powershell
.\scripts\start-pt-docker-sql.ps1
```

Esse passo sobe o SQL Server em Docker na `127.0.0.1,1433`.

### 2. Restaurar os bancos

```powershell
.\scripts\restore-pt-docker-dbs.ps1
```

Esse passo restaura os `.bak`, cria `ChatDB` e `SkillDB` se estiverem faltando, e garante a conta `admin/admin`.

### 3. Corrigir o client para localhost

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

Esse passo e importante quando o `game.dll` do runtime pack ainda aponta para IP publico.

### 4. Corrigir o runtime local

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

Esse passo aplica o workaround local para evitar alguns problemas ja conhecidos do runtime atual.

### 5. Subir os dois servers

```powershell
.\scripts\start-pt-server.ps1
```

Esse passo abre duas janelas de monitor:

- uma para o login server
- uma para o game server

### 6. Abrir o jogo

```powershell
.\Files\Game\Game.exe
```

Ou:

```powershell
.\scripts\start-pt-server.ps1 -OpenClient
```

## O que cada script faz

### `start-pt-docker-sql.ps1`

Arquivo: `scripts/start-pt-docker-sql.ps1`

Funcao:

- verifica se o Docker Desktop esta pronto
- inicia o Docker Desktop se for necessario
- cria ou inicia o container `priston-sql`
- expoe o SQL em `127.0.0.1,1433`
- monta `Files/DBS/extracted` dentro do container como pasta de backup
- espera o SQL aceitar conexao antes de terminar

Use quando:

- voce quer usar SQL Server em Docker
- ainda nao existe container rodando
- voce reiniciou a maquina ou o Docker

Comando padrao:

```powershell
.\scripts\start-pt-docker-sql.ps1
```

### `restore-pt-docker-dbs.ps1`

Arquivo: `scripts/restore-pt-docker-dbs.ps1`

Funcao:

- conecta no SQL em `127.0.0.1,1433`
- restaura `ClanDB`, `EventDB`, `GameDB`, `ItemDB`, `LogDB`, `ServerDB`, `SkillDBNew` e `UserDB`
- cria `ChatDB` e `SkillDB` como placeholder, se faltarem
- cria ou atualiza a conta `admin/admin`
- configura essa conta como GM/Admin para teste local
- sobrescreve o `UserDB` restaurado com o estado do backup

Use quando:

- voce acabou de subir o SQL em Docker
- quer restaurar tudo do zero
- quer garantir que a conta `admin/admin` exista

Comando padrao:

```powershell
.\scripts\restore-pt-docker-dbs.ps1
```

### `patch-pt-client-localhost.ps1`

Arquivo: `scripts/patch-pt-client-localhost.ps1`

Funcao:

- procura no `Files/Game/game.dll` o IP antigo do runtime pack
- troca esse IP por `127.0.0.1`
- cria backup do binario antes de alterar

Use quando:

- o client abre, mas mostra `connection failed`
- o runtime pack veio configurado para um IP publico e nao para localhost
- voce acabou de substituir a pasta `Files/Game`

Comando padrao:

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

### `fix-pt-local-runtime.ps1`

Arquivo: `scripts/fix-pt-local-runtime.ps1`

Funcao:

- reduz o gold do `Administrador` para evitar o cheat `99007`
- remove timers invalidos de premium em `CharacterItemTimer`
- copia alguns `.chr` de teste para a pasta principal de personagens, se necessario
- vincula personagens conhecidos a conta `admin`
- mostra no final quais personagens ficaram disponiveis na conta

Use quando:

- o `Administrador` acusa cheat
- a criacao de personagem esta falhando
- voce quer garantir chars jogaveis na conta `admin`

Comando padrao:

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

Personagens que ele tenta deixar usaveis em `admin`:

- `Administrador`
- `aglob`
- `test_fs_100`
- `test_ms_100`
- `test_ps_100`
- `test_prs_100`

### `provision-pt-test-account.ps1`

Arquivo: `scripts/provision-pt-test-account.ps1`

Funcao:

- cria ou atualiza uma conta customizada no `UserDB`
- grava a senha no mesmo formato de hash usado pelo client
- configura `GameMasterType` e `GameMasterLevel`
- vincula um personagem existente a essa conta
- ajusta o `GMLevel` do personagem

Use quando:

- voce restaurou os bancos e perdeu contas customizadas
- quer recriar rapidamente uma conta de teste
- quer transferir um personagem de teste existente para outra conta

Exemplo usado neste ambiente:

```powershell
.\scripts\provision-pt-test-account.ps1 -Login 'dedezin' -Password 'dedezin123' -CharacterName 'test_ps_100' -GameMasterType 1 -GameMasterLevel 4
```

### `start-pt-server.ps1`

Arquivo: `scripts/start-pt-server.ps1`

Funcao:

- valida se `Files/Server/login-server/Server.exe` existe
- valida se `Files/Server/game-server/Server.exe` existe
- impede start duplicado se os servers ja estiverem rodando
- abre janelas PowerShell separadas para monitorar cada server
- pode abrir o client junto
- pode usar `AutoRestart.bat` em vez de abrir o `Server.exe` diretamente

Use quando:

- o SQL ja esta pronto
- os bancos ja foram restaurados
- o client ja foi ajustado para localhost
- voce quer subir os dois servers

Comando padrao:

```powershell
.\scripts\start-pt-server.ps1
```

Abrindo tambem o jogo:

```powershell
.\scripts\start-pt-server.ps1 -OpenClient
```

Usando `AutoRestart.bat`:

```powershell
.\scripts\start-pt-server.ps1 -UseAutoRestart
```

### `watch-pt-server.ps1`

Arquivo: `scripts/watch-pt-server.ps1`

Funcao:

- e o monitor interno chamado pelo `start-pt-server.ps1`
- abre o `Server.exe` ou o `AutoRestart.bat`
- mostra informacoes da pasta e do log
- acompanha o `Log.txt` em tempo real com `Get-Content -Wait`

Use quando:

- normalmente voce nao precisa rodar ele manualmente
- ele existe para abrir a janela de log de cada server

Observacao:

- se voce fechar so a janela de monitor, o server pode continuar rodando
- para encerrar direito, use `.\scripts\stop-pt-server.ps1`

### `stop-pt-server.ps1`

Arquivo: `scripts/stop-pt-server.ps1`

Funcao:

- encerra os `Server.exe` do login e do game
- encerra as janelas de monitor abertas por `watch-pt-server.ps1`
- encerra processos `AutoRestart.bat`, se existirem

Use quando:

- voce quer parar tudo antes de iniciar de novo
- terminou o teste
- vai trocar config ou banco e quer reiniciar limpo

Comando padrao:

```powershell
.\scripts\stop-pt-server.ps1
```

### `stop-pt-docker-sql.ps1`

Arquivo: `scripts/stop-pt-docker-sql.ps1`

Funcao:

- para o container `priston-sql`

Use quando:

- terminou os testes
- quer liberar recursos
- vai reiniciar o ambiente do zero depois

Comando padrao:

```powershell
.\scripts\stop-pt-docker-sql.ps1
```

## Fluxo recomendado para teste

### Subir tudo do zero

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\restore-pt-docker-dbs.ps1
.\scripts\patch-pt-client-localhost.ps1
.\scripts\fix-pt-local-runtime.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

### Parar tudo

```powershell
.\scripts\stop-pt-server.ps1
.\scripts\stop-pt-docker-sql.ps1
```

### Subir de novo sem restaurar os bancos

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\fix-pt-local-runtime.ps1
.\scripts\start-pt-server.ps1
```

## Como saber se deu certo

Sinais bons:

- o SQL responde em `127.0.0.1,1433`
- o `start-pt-server.ps1` abre duas janelas de monitor
- os logs do login server e do game server ficam atualizando
- o client abre sem `connection failed`
- o login `admin/admin` funciona
- a conta `admin` mostra personagens na tela de selecao

Voce tambem pode testar com a conta extra:

- login: `dedezin`
- senha: `dedezin123`
- personagem: `test_ps_100`
- para ativar GM no jogo: `/activategm`

Se voce acabou de rodar o restore e a conta sumiu:

```powershell
.\scripts\provision-pt-test-account.ps1 -Login 'dedezin' -Password 'dedezin123' -CharacterName 'test_ps_100' -GameMasterType 1 -GameMasterLevel 4
```

## Se der erro

### `connection failed`

Rode:

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

### `Cheat detected: 99007`

Rode:

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

### Falha ao criar personagem

No runtime atual, isso ainda pode acontecer por causa do driver ODBC do server.

Entao, por enquanto:

- use os personagens ja vinculados em `admin`
- nao dependa da tela de criacao de personagem novo

## Docs relacionadas

- `docs/guides/setup-run-test-guide.md`
- `docs/analysis/project-analysis.md`
- `docs/reference/server-commands-reference.md`
