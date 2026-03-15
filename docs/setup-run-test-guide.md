# Guia de setup, start e teste

Atualizado em: 2026-03-15

Este guia assume:

- source em `PristonTale-EU-main`
- runtime pack em `PristonTale-EU-main/Files`
- teste local na mesma maquina

## Objetivo

Ao final deste guia voce deve conseguir:

- restaurar os bancos minimos
- alinhar os arquivos de configuracao
- subir login server e game server
- abrir o client
- testar login com uma conta existente ou com `admin` / `admin`

## 1. O que instalar

Obrigatorio para subir server:

- abra o PowerShell como Administrador
- SQL Server Express com instancia `SQLEXPRESS`
- SSMS para restaurar os backups
- autenticacao mista habilitada no SQL Server
- usuario `sa` ativo

Muito recomendado:

- driver ODBC `SQL Server Native Client 11.0`

Alternativa se nao quiser instalar o Native Client 11:

- trocar o `Driver` dos dois `server.ini` para `{SQL Server}`

Opcional, mas necessario para clan/painel web:

- IIS
- Classic ASP
- CGI/FastCGI
- PHP 7.4

Para o client, pode ser necessario:

- DirectX 9 runtime, caso faltem DLLs como `d3dx9` ou `dsound`

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

Se nao houver uma conta funcional, a conta padrao recomendada para teste e:

- login: `admin`
- senha: `admin`

Script base para criar `admin` / `admin`:

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
            Flag,
            Active,
            Coins,
            GameMasterType,
            GameMasterLevel,
            GameMasterMacAddress,
            BanStatus,
            UnbanDate,
            IsMuted,
            MuteCount,
            UnmuteDate
        )
    VALUES
        (
            'admin',
            'admin',
            98,
            1,
            0,
            0,
            0,
            '',
            0,
            NULL,
            0,
            0,
            NULL
        );
END;
```

Notas importantes:

- `Flag = 98` representa `Activated + AcceptedLatestTOA + Approved`.
- Se sua tabela `UserInfo` tiver outras colunas obrigatorias sem valor default, complete o `INSERT` antes de executar.
- A senha e comparada em texto puro pelo server.

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

Fluxo recomendado:

```powershell
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

## 7. Ordem correta de start

1. Suba o login server.
2. Suba o game server.
3. Espere aparecer nos logs:
   - `Login Server Started!`
   - `Game Server Started!`
4. Abra `Files/Game/Game.exe`.
5. Faça login com uma conta existente ou com `admin` / `admin`.

## 8. Como testar

Checklist minimo:

1. O login server inicia sem erro fatal de conexao SQL.
2. O game server inicia sem erro fatal de conexao SQL.
3. O client abre e conecta em localhost.
4. O login aceita usuario e senha.
5. A tela de selecao de personagem abre.
6. O personagem entra no mundo.

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
6. Rode `.\scripts\start-pt-server.ps1`.
7. Abra o client.
8. Tente logar.

Se os logs mostrarem erro de schema, o proximo passo nao e recompilar o source; o proximo passo e acertar os bancos primeiro.
