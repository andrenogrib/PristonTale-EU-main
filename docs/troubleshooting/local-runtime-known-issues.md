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

## Personagens seguros para teste na conta `admin`

Hoje os personagens recomendados para teste local sao:

- `Administrador`
- `aglob`
- `test_fs_100`
- `test_ms_100`
- `test_ps_100`
- `test_prs_100`
