# Guia de setup, start e teste

Atualizado em: 2026-03-15

Este guia assume:

- source em `PristonTale-EU-main`
- runtime pack em `PristonTale-EU-main/Files`
- teste local na mesma maquina

Docs relacionadas:

- `docs/reference/server-commands-reference.md`
- `docs/reference/item-code-and-data-reference.md`

## Objetivo

Ao final deste guia voce deve conseguir:

- restaurar os bancos minimos
- alinhar os arquivos de configuracao
- alinhar o binario real do client com localhost
- subir login server e game server
- abrir o client
- testar login com uma conta existente ou com `admin` / `admin`
- ativar GM com `/activategm` e saber onde procurar os comandos

## 1. O que instalar

Obrigatorio para subir server:

- abra o PowerShell como Administrador
- SQL Server Express com instancia `SQLEXPRESS`
- SSMS para restaurar os backups
- autenticacao mista habilitada no SQL Server
- usuario `sa` ativo

Muito recomendado:

- driver ODBC `SQL Server Native Client 11.0`
- ou `ODBC Driver 17 for SQL Server`

Alternativa se nao quiser instalar o Native Client 11:

- trocar o `Driver` dos dois `server.ini` para `{SQL Server}`

Opcional, mas necessario para clan/painel web:

- IIS
- Classic ASP
- CGI/FastCGI
- PHP 7.4

Para o client, pode ser necessario:

- DirectX 9 runtime, caso faltem DLLs como `d3dx9` ou `dsound`

Alternativa pratica sem instalar `SQLEXPRESS` no Windows:

- Docker Desktop
- `.\scripts\start-pt-docker-sql.ps1`
- `.\scripts\restore-pt-docker-dbs.ps1`

Esse caminho sobe um SQL Server 2022 em container, restaura os bancos do pacote, cria `ChatDB` e `SkillDB` como placeholders e provisiona `admin` / `admin`.

Comandos uteis via `winget`:

```powershell
winget install -e --id Microsoft.SQLServer.2022.Express --accept-source-agreements --accept-package-agreements
winget install -e --id Microsoft.SQLServer.2012.NativeClient --accept-source-agreements --accept-package-agreements
winget install -e --id Microsoft.SQLServerManagementStudio.22 --accept-source-agreements --accept-package-agreements
winget install -e --id Microsoft.Sqlcmd --accept-source-agreements --accept-package-agreements
```

Observacao:

- o `winget` do SQL Express pode abrir o bootstrapper da Microsoft
- se isso acontecer, mantenha a instancia `SQLEXPRESS`
- se o driver Native Client 11 nao for instalado, lembre de trocar o `Driver` dos `server.ini` para `{SQL Server}`

## 2. Restaurar os bancos

1. Extraia os arquivos em `Files/DBS`.
2. Abra o SSMS e conecte na instancia `(local)\SQLEXPRESS`.
3. Restaure os bancos com estes nomes exatos:

- `GameDB`
- `ServerDB`
- `LogDB`
- `SkillDBNew`
- `EventDB`
- `ItemDB`
- `ClanDB`
- `UserDB`

Observacao:

- os arquivos `.bak` podem ficar centralizados em `Files/DBS/extracted`

Observacoes:

- O source tambem espera `ChatDB` e `SkillDB`.
- O pacote analisado nao trouxe esses dois bancos.
- Se essas bases forem realmente obrigatorias no seu binario atual, voce vai precisar consegui-las ou adaptar o runtime/source.

## 3. Conferir ou criar conta de login

Primeiro veja se ja existe uma conta usavel:

```sql
SELECT TOP (50)
    ID,
    AccountName,
    [Password],
    Flag,
    Active,
    GameMasterType,
    GameMasterLevel
FROM UserDB.dbo.UserInfo
ORDER BY ID DESC;
```

Contas vistas em logs antigos:

- `test_fs_40`
- `test_fs_20`

Senha conhecida:

- nenhuma senha foi descoberta nos arquivos inspecionados
- as senhas da `UserInfo` restaurada estao em hash SHA-256

Se nao houver uma conta funcional, a conta padrao recomendada para teste e:

- login: `admin`
- senha: `admin`

Conta adicional preparada manualmente no ambiente local desta analise:

- login: `dedezin`
- senha: `dedezin123`
- `GameMasterType = 1`
- `GameMasterLevel = 4`
- personagem de teste vinculado: `test_ps_100`
- classe: pike

Observacao importante:

- se voce rodar `.\scripts\restore-pt-docker-dbs.ps1` depois disso, o `UserDB` sera restaurado do backup
- isso pode remover a conta `dedezin` e devolver `test_ps_100` para outra conta
- para recriar a conta customizada, use `.\scripts\provision-pt-test-account.ps1`

Regra importante do login:

- o client envia `SHA-256(UPPER(login) + ":" + senhaEmTexto)`
- para `admin` / `admin`, o hash correto e:
  - `E0E72A977BC2C38BA687BAF40D17BFD68BA7830CB15DB4DA2C4897D5B20BC21D`

Script base para criar ou atualizar `admin` / `admin`:

```sql
IF NOT EXISTS (
    SELECT 1
    FROM UserDB.dbo.UserInfo
    WHERE AccountName = 'admin'
)
BEGIN
    INSERT INTO UserDB.dbo.UserInfo
        (
            AccountName,
            [Password],
            RegisDay,
            Flag,
            Active,
            ActiveCode,
            Coins,
            Email,
            GameMasterType,
            GameMasterLevel,
            GameMasterMacAddress,
            CoinsTraded,
            BanStatus,
            UnbanDate,
            IsMuted,
            MuteCount,
            UnmuteDate
        )
    VALUES
        (
            'admin',
            'E0E72A977BC2C38BA687BAF40D17BFD68BA7830CB15DB4DA2C4897D5B20BC21D',
            'Mar 15 2026  7:45PM',
            114,
            1,
            '0',
            1500,
            'admin@invalid.email.com',
            1,
            4,
            '0',
            0,
            0,
            NULL,
            0,
            0,
            NULL
        );
END;
```

Notas importantes:

- `Flag = 114` e o mesmo padrao encontrado nos usuarios de teste restaurados.
- Se sua tabela `UserInfo` tiver outras colunas obrigatorias sem valor default, complete o `INSERT` antes de executar.
- O server compara o hash recebido do client com o valor salvo no banco.

## 4. Alinhar configuracao dos servers

Arquivos que precisam bater:

- `Files/Server/login-server/server.ini`
- `Files/Server/game-server/server.ini`

Campos que devem ficar consistentes:

- `Driver`
- `Host`
- `User`
- `Password`

Configuracao atual encontrada:

```ini
[Database]
Driver={SQL Server Native Client 11.0}
Host=(local)\SQLEXPRESS
User=sa
Password=632514Go
```

Se o Native Client 11 nao estiver instalado, troque nos dois arquivos:

```ini
Driver={SQL Server}
```

## 4.1 Alinhar o binario do client com localhost

Diagnostico real encontrado no ambiente local:

- a source aponta para `127.0.0.1`
- mas o `Files/Game/game.dll` distribuido com o runtime pack ainda estava compilado com o IP `15.204.184.155`
- por isso o erro `connection failed` aparecia antes de qualquer tentativa de login chegar ao `login-server`

Correcao:

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

O script:

- cria backup de `Files/Game/game.dll`
- troca o IP antigo do runtime para `127.0.0.1`
- valida se o patch foi aplicado

Quando usar:

- sempre que voce copiar um novo runtime pack para `Files/`
- sempre que o `Game.exe` mostrar `connection failed` e o `login-server` nao registrar tentativa de login no `Log.txt`

## 5. Alinhar o ClanSystem, se for usar

Arquivos:

- `Files/ClanSystem/Clan/settings.asp`
- `Files/ClanSystem/Clan/SODsettings.asp`

Hoje eles usam a mesma instancia, mas outra senha:

- `Dev@2681`

Se for subir o clan web, alinhe estes arquivos com o mesmo host, user e password do SQL usado pelo server.

## 6. Subir os servers

Scripts incluidos neste repo:

- `scripts/start-pt-server.ps1`
- `scripts/stop-pt-server.ps1`
- `scripts/start-pt-docker-sql.ps1`
- `scripts/stop-pt-docker-sql.ps1`
- `scripts/restore-pt-docker-dbs.ps1`
- `scripts/patch-pt-client-localhost.ps1`
- `scripts/assign-pt-character-to-account.ps1`

Fluxo recomendado:

```powershell
.\scripts\patch-pt-client-localhost.ps1
.\scripts\start-pt-server.ps1
```

O script abre janelas separadas de PowerShell para:

- iniciar o login server
- iniciar o game server
- acompanhar o `Log.txt` de cada servidor em tempo real

Opcao util:

```powershell
.\scripts\start-pt-server.ps1 -OpenClient
```

Isso sobe os servidores e tambem tenta abrir `Files/Game/Game.exe`.

Se quiser usar o `AutoRestart.bat` existente de cada server:

```powershell
.\scripts\start-pt-server.ps1 -UseAutoRestart
```

Para parar tudo:

```powershell
.\scripts\stop-pt-server.ps1
```

Antes de rodar, confirme que o servico `MSSQL$SQLEXPRESS` esta instalado e iniciado.

## 6.1 Atalho com Docker

Se voce nao quiser instalar `SQLEXPRESS` no Windows:

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\restore-pt-docker-dbs.ps1
.\scripts\patch-pt-client-localhost.ps1
.\scripts\start-pt-server.ps1
```

Com esse fluxo, os `server.ini` precisam apontar para:

```ini
[Database]
Driver={SQL Server}
Host=127.0.0.1,1433
User=sa
Password=632514Go
```

Para desligar o SQL do Docker:

```powershell
.\scripts\stop-pt-docker-sql.ps1
```

## 7. Ordem correta de start

1. Suba o login server.
2. Suba o game server.
3. Espere aparecer nos logs:
   - `Login Server Started!`
   - `Game Server Started!`
4. Rode `.\scripts\patch-pt-client-localhost.ps1` se o runtime pack acabou de ser copiado.
5. Abra `Files/Game/Game.exe`.
6. Faca login com uma conta existente ou com `admin` / `admin`.

## 8. Como testar

Checklist minimo:

1. O login server inicia sem erro fatal de conexao SQL.
2. O game server inicia sem erro fatal de conexao SQL.
3. O client usa o `game.dll` alinhado com localhost.
4. O client abre e conecta em localhost.
5. O login aceita usuario e senha.
6. A tela de selecao de personagem abre.
7. O personagem entra no mundo.

Se existir o personagem `Administrador` no banco restaurado, ele pode aparecer na lista de personagens.

## 9. Start manual sem script

Se preferir testar na mao:

```powershell
Set-Location .\Files\Server\login-server
.\Server.exe
```

Em outra janela:

```powershell
Set-Location .\Files\Server\game-server
.\Server.exe
```

Depois:

```powershell
Set-Location .\Files\Game
.\Game.exe
```

## 10. Erros comuns e como interpretar

### Erro de driver ODBC

Sintoma:

- falha ao abrir conexao usando `SQL Server Native Client 11.0`

Correcao:

- instale o Native Client 11
- ou troque os dois `server.ini` para `Driver={SQL Server}`

### Erro de instancia SQL

Sintoma:

- nada conecta em `(local)\SQLEXPRESS`

Correcao:

- instale o SQL Server Express
- confirme o nome da instancia
- habilite `sa` e a autenticacao mista

### Erro `MainQuestID` invalido

Sintoma:

- aparece logo no start do server

Correcao:

- o `GameDB` restaurado nao bate com o schema esperado por este binario/source

### Erro `connection failed` no client

Sintoma:

- o `Game.exe` abre
- ao tentar `admin` / `admin`, aparece `connection failed`
- o `Files/Server/login-server/Log.txt` nao registra nenhuma tentativa de login

Correcao:

- rode `.\scripts\patch-pt-client-localhost.ps1`
- confirme que o runtime `Files/Game/game.dll` nao esta mais apontando para `15.204.184.155`
- depois suba os servers novamente e teste de novo

Diagnostico:

- neste projeto, a source ja estava em localhost
- o problema real era o `game.dll` do runtime pack, que ainda apontava para IP publico

### Erro ao criar personagem com driver ODBC generico

Sintoma:

- o login funciona
- mas criar personagem gera erros como `Invalid precision value` ou `COUNT field incorrect or syntax error`
- o `Log.txt` mostra falha em `INSERT INTO CharacterInfo`
- o `Log.txt` do login server tambem pode mostrar falha em `INSERT INTO CharacterLog`

Correcao recomendada:

- instalar um driver SQL mais compativel, como `SQL Server Native Client 11.0`
- ou `ODBC Driver 17 for SQL Server`
- depois ajustar os dois `server.ini` para o nome exato do driver instalado

Workaround pratico para teste local:

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

Esse script:

- reduz o gold do `Administrador` para evitar o cheat `99007`
- limpa timers invalidos criados por tentativas quebradas de criar personagem
- vincula personagens de teste conhecidos a `admin`
- permite testar entrada no jogo sem depender da tela de criacao de personagem

Personagens que o workaround tenta deixar disponiveis em `admin`:

- `Administrador`
- `aglob`
- `test_fs_100`
- `test_ms_100`
- `test_ps_100`
- `test_prs_100`

Detalhe tecnico da causa:

- o `server.dll` usa bind ODBC parametrizado que funciona melhor com Native Client 11 ou ODBC 17
- com `Driver={SQL Server}`, alguns `tinyint` enviados como `PARAMTYPE_Byte` falham no `SQLBindParameter`
- na pratica isso quebra a gravacao de `CharacterInfo` e `CharacterLog`

Regra pratica:

- com o runtime atual, use personagens ja existentes para validar login, selecao e entrada no mundo
- deixe a criacao de personagem novo para depois que o driver ODBC compativel estiver instalado

### Cheat `99007` no personagem `Administrador`

Sintoma:

- ao entrar ou sair do personagem `Administrador`, o log acusa `WARN: Cheat detected: 99007`

Diagnostico:

- `99007` e `CHEATLOGID_GoldLimitReached`
- esse alerta dispara quando o personagem passa do limite de gold permitido pelo server
- o `Administrador` do pacote veio com gold acima do limite

Correcao:

- rode `.\scripts\fix-pt-local-runtime.ps1`
- o script reduz o gold do `Administrador` para um valor seguro

Impacto:

- isso remove o falso positivo de cheat no personagem de teste
- nao corrige criacao de personagem; esse e um problema separado de driver ODBC

### Erro `LevelUpDate` invalido

Sintoma:

- aparece ao consultar ranking ou ao entrar com personagem

Correcao:

- o `UserDB` restaurado nao bate com o schema esperado

### Erro `HasItem` ou `Item` em `ItemBox`

Sintoma:

- falhas de `INSERT` ou `SELECT` na tabela `ItemBox`

Correcao:

- a tabela `UserDB.dbo.ItemBox` esta com schema divergente do esperado pelo server

### Clan web nao funciona

Sintoma:

- telas HTTP de clan falham

Correcao:

- alinhar `settings.asp` e `SODsettings.asp`
- instalar e configurar IIS + ASP + PHP
- revisar conteudo de `Files/Inetpub`

## 11. Resumo do caminho mais curto

Se voce quiser apenas subir e testar local:

1. Instale `SQLEXPRESS` e `SSMS`.
2. Restaure `GameDB`, `ServerDB`, `LogDB`, `SkillDBNew`, `EventDB`, `ItemDB`, `ClanDB` e `UserDB`.
3. Confira se existe conta em `UserDB.dbo.UserInfo`.
4. Se nao existir, crie `admin` / `admin`.
5. Ajuste `Driver`, `Host`, `User` e `Password` nos dois `server.ini`.
6. Rode `.\scripts\patch-pt-client-localhost.ps1`.
7. Rode `.\scripts\fix-pt-local-runtime.ps1`.
8. Rode `.\scripts\start-pt-server.ps1`.
9. Abra o client.
10. Tente logar com `admin` / `admin`.
11. Se a tela de criacao falhar, use um dos personagens ja vinculados a `admin`.

Se os logs mostrarem erro de schema, o proximo passo nao e recompilar o source; o proximo passo e acertar os bancos primeiro.
