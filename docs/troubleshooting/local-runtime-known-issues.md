# Local Runtime Known Issues

Atualizado em: 2026-03-15

Esta doc concentra os erros reais ja observados no ambiente local atual.

## `connection failed`

Sintoma:

- o client abre
- o login falha antes mesmo de chegar no `login-server`

Causa raiz:

- o `Files/Game/game.dll` do runtime pack pode vir apontando para IP publico em vez de `127.0.0.1`

Correcao:

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

## Cheat `99007` no `Administrador`

Sintoma:

- o log acusa `WARN: Cheat detected: 99007 for user: Administrador`

Causa raiz:

- o personagem veio com gold acima do limite permitido pelo server

Correcao:

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

## Falha ao criar personagem

Sintoma:

- criar personagem gera `HY104` e `07002`
- o log mostra falha em `INSERT INTO CharacterInfo`
- o login server tambem pode falhar em `INSERT INTO CharacterLog`

Causa raiz:

- o runtime atual do server usa binds ODBC que nao casam bem com o driver generico `{SQL Server}`
- no ambiente atual, isso afeta principalmente criacao de personagem

Workaround atual:

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

Esse workaround:

- limpa sujeira de tentativas quebradas
- garante personagens jogaveis na conta `admin`

Correcao definitiva:

- instalar um driver ODBC compativel com esse binario, como `SQL Server Native Client 11.0` ou `ODBC Driver 17 for SQL Server`

Status atual do ambiente:

- o `ODBC Driver 17 for SQL Server` ja esta configurado nos `server.ini`
- isso removeu os erros antigos de bind ODBC como `HY104` e `07002`
- os erros restantes observados agora sao de schema e rotinas ausentes, nao do driver em si

## Login falha para conta customizada depois de restore

Sintoma:

- a conta customizada existia antes
- depois de rodar `.\scripts\restore-pt-docker-dbs.ps1`, o login passa a falhar
- o log pode mostrar `SELECT TOP(1) FROM UserInfo query failed for account '<login>'`

Causa raiz:

- o restore sobrescreve o `UserDB` com o backup base
- isso remove contas criadas manualmente depois
- a mesma restauracao tambem pode devolver personagens de teste para a conta antiga

Correcao:

```powershell
.\scripts\provision-pt-test-account.ps1 -Login 'dedezin' -Password 'dedezin123' -CharacterName 'test_ps_100' -GameMasterType 1 -GameMasterLevel 4
```

## Personagens seguros para teste na conta `admin`

Hoje os personagens recomendados para teste local sao:

- `Administrador`
- `aglob`
- `test_fs_100`
- `test_ms_100`
- `test_ps_100`
- `test_prs_100`
