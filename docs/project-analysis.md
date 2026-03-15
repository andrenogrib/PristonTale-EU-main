# Analise do pacote Files

Atualizado em: 2026-03-15

Escopo desta analise:

- source do client em `game/`
- source do server em `Server/`
- runtime pack em `Files/`
- bancos em `Files/DBS`
- clan web em `Files/ClanSystem`
- IIS/PHP empacotados em `Files/Inetpub`

## Visao geral

- O projeto tem source C++ do client e do server.
- Para teste local inicial, compilar nao e obrigatorio, porque ja existem binarios prontos dentro de `Files/`.
- Os binarios principais encontrados foram:
  - `Files/Server/login-server/Server.exe`
  - `Files/Server/game-server/Server.exe`
  - `Files/Game/Game.exe`

## Estrutura do runtime pack

- `Files/Game`: client jogavel, assets e `Game.exe`.
- `Files/Server/login-server`: login server, `server.ini`, `Server.exe`, `Log.txt`.
- `Files/Server/game-server`: game server, `server.ini`, `Server.exe`, `Log.txt`.
- `Files/DBS`: backups e arquivos ligados aos bancos.
- `Files/ClanSystem`: paginas ASP do sistema de clan.
- `Files/Inetpub`: pacote com estrutura de IIS/PHP esperada pelo clan web.

## Configuracao de rede

- O client esta preparado para `127.0.0.1`.
- O mundo principal encontrado no source e `Babel`.
- Porta do login server: `10009`.
- Porta do game server: `10007`.
- Os dois `server.ini` tambem apontam para localhost.

Conclusao pratica:

- O pacote esta montado para teste local na mesma maquina, desde que o SQL Server e os bancos estejam corretos.

## Configuracao de banco

Os dois arquivos abaixo usam a mesma configuracao de SQL:

- `Files/Server/login-server/server.ini`
- `Files/Server/game-server/server.ini`

Configuracao encontrada:

- Host: `(local)\SQLEXPRESS`
- User: `sa`
- Password: `632514Go`
- Driver: `{SQL Server Native Client 11.0}`

## Bancos esperados pelo server

Pelo source, o server tenta abrir estes bancos:

- `GameDB`
- `ServerDB`
- `LogDB`
- `SkillDB`
- `SkillDBNew`
- `EventDB`
- `ItemDB`
- `ClanDB`
- `ChatDB`
- `UserDB`

## Bancos encontrados no pacote

Backups ou pacotes relacionados encontrados em `Files/DBS`:

- `GameDB`
- `ServerDB`
- `LogDB`
- `SkillDBNew`
- `EventDB`
- `ItemDB`
- `ClanDB`
- `UserDB`

Bancos ausentes no pacote analisado:

- `ChatDB`
- `SkillDB`
- `SoD2DB`

Conclusao pratica:

- O server so tende a ficar limpo quando os nomes e schemas dos bancos baterem com o que o binario espera.
- O pacote atual parece incompleto para todas as features, principalmente chat extra e parte de SoD/clan web.

## ClanSystem e web

O sistema web de clan usa:

- `Files/ClanSystem/Clan/settings.asp`
- `Files/ClanSystem/Clan/SODsettings.asp`

Foi encontrada a mesma instancia `(local)\SQLEXPRESS`, mas com senha diferente:

- User: `sa`
- Password: `Dev@2681`

Conclusao pratica:

- Do jeito que esta, server e clan web nao usam a mesma senha.
- Se for subir o clan web, os arquivos ASP precisam ficar alinhados com o mesmo host, user e password dos `server.ini`.
- O pacote `Files/Inetpub` indica dependencia de IIS com Classic ASP, CGI/FastCGI e PHP 7.4.

## Contas e personagens vistos nos logs

Contas vistas em logs antigos:

- `test_fs_40`
- `test_fs_20`

Personagem visto nos logs:

- `Administrador`

Limite importante:

- Nenhuma senha foi encontrada de forma confiavel nos arquivos inspecionados.
- O log mostra tentativa falhada de `test_fs_20` e depois login bem-sucedido, mas nao revela a senha.

Conclusao pratica:

- Primeiro confira `UserDB.dbo.UserInfo`.
- Se nao existir uma conta funcional depois da restauracao, a conta padrao recomendada para teste sera `admin` / `admin`.

## Regras de login observadas no source

O login depende de:

- senha comparada com o valor gravado no banco, sem re-hash no server
- o client faz `SHA-256` antes de enviar a senha
- formula observada no client: `SHA256(UPPER(AccountName) + ":" + PlainPassword)`
- `Flag` com:
  - `Activated = 2`
  - `AcceptedLatestTOA = 32`
  - `Approved = 64`
- `MustConfirm` nao pode estar ligado

Valor pratico para um usuario de teste:

- `Flag = 114` nos usuarios de teste restaurados

Conclusao pratica:

- as senhas vistas em `UserInfo` na base restaurada estao em hash SHA-256
- por isso nao existe como ler a senha real de contas antigas so olhando a tabela
- para um usuario novo de teste, o hash precisa ser gravado no mesmo formato do client

## Erros reais encontrados nos logs

Os logs mostram que os binarios chegaram a subir, mas os bancos usados na epoca nao batiam com o schema esperado.

Erros encontrados:

- `MainQuestID` invalido em `GameDB`
- `LevelUpDate` invalido em `UserDB`
- `HasItem` e `Item` inconsistentes em `UserDB.dbo.ItemBox`

Conclusao pratica:

- Restaurar qualquer backup com nome correto nao basta.
- O schema precisa ser o schema compativel com este binario/source.

## Estado da maquina usada nesta analise

Na maquina em que a inspecao foi feita, o estado observado foi:

- sem servico `MSSQL$SQLEXPRESS` ativo
- sem IIS configurado
- driver ODBC encontrado: `SQL Server`

Impacto:

- se o `SQL Server Native Client 11.0` nao estiver instalado, pode ser necessario trocar os dois `server.ini` para `Driver={SQL Server}`
- IIS e PHP so sao obrigatorios se quiser subir o clan/painel web

## Versionamento do runtime pack

- `Files/` ocupa cerca de `10.9 GB`
- os maiores arquivos individuais vistos ficaram na faixa de `25 MB` a `70 MB`
- mesmo sem muitos arquivos acima de `100 MB`, o pacote completo e grande demais para um fluxo simples de GitHub

Recomendacao:

- manter no Git apenas source, docs, scripts e ajustes pequenos de configuracao
- tratar `Files/` como pacote local, release asset, storage externo ou Git LFS se realmente precisar versionar os binarios
