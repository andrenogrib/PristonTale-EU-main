# Priston Tale EU Source Code

Atualizado em: 2026-03-15

Este repositorio guarda o source do client e do server de uma base de Priston Tale usada em projetos como Fortress PT, Regnum PT, PristonTale EU e Epic Tale.

Hoje ele tambem ja tem documentacao local para:

- analisar o runtime pack `Files/`
- restaurar banco e subir o ambiente local
- localizar comandos de GM/Admin
- achar `itemCode`, `ItemID`, drop table, spawn e dados de monstro

## Estrutura do repo

- `game/`: source do client
- `Server/`: source do login server e game server
- `shared/`: estruturas e tipos compartilhados
- `docs/`: documentacao setorizada em guides, analysis, reference, studies e troubleshooting
- `scripts/`: utilitarios de SQL, start/stop e lookup rapido
- `Files/`: runtime pack local com client, server e bancos restauraveis

## Importante sobre `Files/`

A pasta `Files/` funciona como runtime pack local.

- ela e grande e normalmente nao deve entrar no Git
- use como base para teste local, binarios prontos e bancos
- se o source e o binario divergirem, registre isso nas docs

## Comeco rapido

Se voce quer subir o ambiente local, siga esta ordem:

1. leia [docs/guides/server-start-guide.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/server-start-guide.md)
2. suba o SQL local com `.\scripts\start-pt-docker-sql.ps1`
3. restaure/alinhe os bancos com `.\scripts\restore-pt-docker-dbs.ps1`
4. suba os servidores com `.\scripts\start-pt-server.ps1`
5. abra `Files/Game/Game.exe`

Conta local de teste documentada no setup:

- login: `admin`
- senha: `admin`

Se o runtime pack vier com problema de cheat no `Administrador` ou falha na criacao de personagem, rode antes:

- `.\scripts\fix-pt-local-runtime.ps1`

## Documentacao principal

- [docs/README.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/README.md): indice da documentacao
- [docs/guides/server-start-guide.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/server-start-guide.md): guia direto para ligar, monitorar e parar o server com os scripts
- [docs/guides/setup-run-test-guide.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/setup-run-test-guide.md): guia pratico de setup, start e teste
- [docs/analysis/project-analysis.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/analysis/project-analysis.md): analise tecnica do pacote `Files/`
- [docs/reference/server-commands-reference.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/reference/server-commands-reference.md): referencia de comandos de player, GM1, GM2, GM3 e GM4/Admin
- [docs/reference/item-code-and-data-reference.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/reference/item-code-and-data-reference.md): onde achar `itemCode`, `ItemID`, drop e spawn
- [docs/studies/README.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/studies/README.md): setor recomendado para estudos e investigacoes profundas
- [docs/troubleshooting/README.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/troubleshooting/README.md): setor recomendado para incidentes e correcoes operacionais
- [docs/troubleshooting/local-runtime-known-issues.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/troubleshooting/local-runtime-known-issues.md): problemas reais do runtime local e como contornar

## Scripts uteis

- [scripts/start-pt-docker-sql.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/start-pt-docker-sql.ps1): sobe o SQL Server em Docker
- [scripts/restore-pt-docker-dbs.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/restore-pt-docker-dbs.ps1): restaura bancos e garante a conta `admin`
- [scripts/start-pt-server.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/start-pt-server.ps1): sobe login server e game server
- [scripts/stop-pt-server.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/stop-pt-server.ps1): para os servers
- [scripts/find-pt-item.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/find-pt-item.ps1): busca item por nome, `itemCode` ou `ItemID`
- [scripts/patch-pt-client-localhost.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/patch-pt-client-localhost.ps1): alinha client binario para localhost
- [scripts/assign-pt-character-to-account.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/assign-pt-character-to-account.ps1): vincula personagem existente a uma conta
- [scripts/fix-pt-local-runtime.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/fix-pt-local-runtime.ps1): aplica o workaround local para cheat `99007`, timers invalidos e personagens de teste

## Exemplos rapidos

Buscar item:

```powershell
.\scripts\find-pt-item.ps1 -Search "WA101"
.\scripts\find-pt-item.ps1 -Search "stone axe"
.\scripts\find-pt-item.ps1 -Search "murky" -Old
```

Ativar GM no jogo:

```text
/activategm
```

Comandos de GM e lookup de item ficam documentados em:

- [docs/reference/server-commands-reference.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/reference/server-commands-reference.md)
- [docs/reference/item-code-and-data-reference.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/reference/item-code-and-data-reference.md)

## Solucao e build

Solucao principal:

- `PristonTale.sln`

Projetos principais:

- client em `game/`
- server em `Server/`

## Creditos

This source was based on the fPT / rPT Source Code.

Thanks:

- Joao "Prog" Vitor (HiddenUserHere)
- Igor Segalla (Slave)
- Adolpho Pizzolio (HaDDeR)
- Gabriel "Rovug" Romanzini
- Leonardo "Lee" Souza
