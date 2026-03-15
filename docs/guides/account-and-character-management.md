# Account And Character Management

Atualizado em: 2026-03-15

Este guia explica como criar conta, dar GM/Admin, criar personagem por banco e editar personagem sem depender de conhecer o source.

## O que fica em cada lugar

### Conta

A conta fica em:

- `UserDB.dbo.UserInfo`

Campos mais importantes:

- `AccountName`: login
- `Password`: senha em hash
- `Flag`: status da conta
- `Active`: conta ativa
- `GameMasterType`: libera o modo GM
- `GameMasterLevel`: define o nivel do GM

### Personagem

O personagem fica em dois lugares:

- `UserDB.dbo.CharacterInfo`
- `Files/Server/login-server/Data/Character/<NomeDoChar>.chr`

Isso e importante:

- nao basta criar so a linha do banco
- tambem precisa existir o arquivo `.chr`

## Caminho mais facil: usar os scripts do repo

Para quem nao quer mexer manualmente no banco, estes scripts resolvem quase tudo:

- `scripts/provision-pt-test-account.ps1`: cria ou atualiza conta e ja aplica GM
- `scripts/assign-pt-character-to-account.ps1`: move um personagem existente para uma conta
- `scripts/clone-pt-character-template.ps1`: cria um personagem novo clonando um template pronto

## Como criar uma conta do zero

### Metodo recomendado: script

Exemplo:

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'novogm' `
  -Password '123456' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 4
```

O que isso faz:

- cria a conta se ela nao existir
- atualiza a senha
- seta `Flag = 114`
- seta `Active = 1`
- seta `GameMasterType` e `GameMasterLevel`
- vincula o personagem informado a essa conta
- seta `GMLevel` do personagem

## O que significa `Flag = 114`

O login do server exige a conta com:

- `Activated = 2`
- `AcceptedLatestTOA = 32`
- `Approved = 64`

Somando:

```text
2 + 32 + 64 = 114
```

Entao, para uma conta local funcionar, o valor esperado hoje e:

```text
Flag = 114
```

## Como mudar uma conta para GM ou Admin

### Metodo recomendado: rodar o script de novo

Exemplo para virar GM4/Admin:

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'novogm' `
  -Password '123456' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 4
```

Exemplo para deixar como GM2:

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'novogm' `
  -Password '123456' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 2
```

### Leitura dos niveis

- `0`: sem GM
- `1`: GM1
- `2`: GM2
- `3`: GM3
- `4`: GM4 / Admin

## Como criar um personagem quando o client nao consegue criar

No setup local deste repo, ja houve caso de criacao via client falhar por causa de banco e driver.
Nessa situacao, o jeito mais seguro e clonar um personagem template.

### Metodo recomendado: clonar template

Exemplo:

```powershell
.\scripts\clone-pt-character-template.ps1 `
  -AccountName 'novogm' `
  -NewCharacterName 'MeuPike' `
  -TemplateCharacterName 'test_ps_100' `
  -GameMasterLevel 4
```

O que esse script faz:

- verifica se a conta existe
- verifica se o personagem template existe no banco
- verifica se o arquivo `.chr` do template existe
- cria uma nova linha em `CharacterInfo`
- copia o arquivo `.chr`

Observacao:

- esse fluxo e melhor com o server desligado
- ele clona o estado base do template
- para um char de teste, isso costuma ser suficiente

## Como mover um personagem existente para outra conta

Exemplo:

```powershell
.\scripts\assign-pt-character-to-account.ps1 `
  -AccountName 'novogm' `
  -CharacterName 'test_ps_100'
```

Esse script:

- nao cria personagem novo
- apenas troca o dono de um personagem ja existente

## Como editar um personagem no banco

Tabela:

- `UserDB.dbo.CharacterInfo`

Campos mais usados:

- `AccountName`
- `Name`
- `Level`
- `Experience`
- `Gold`
- `JobCode`
- `GMLevel`
- `Banned`

### Exemplo: mudar level e gold

```sql
USE UserDB;
GO

UPDATE dbo.CharacterInfo
SET Level = 100,
    Experience = 0,
    Gold = 1000000
WHERE Name = 'MeuPike';
```

### Exemplo: mudar o dono do personagem

```sql
USE UserDB;
GO

UPDATE dbo.CharacterInfo
SET AccountName = 'novogm'
WHERE Name = 'MeuPike';
```

### Exemplo: dar GM no personagem

```sql
USE UserDB;
GO

UPDATE dbo.CharacterInfo
SET GMLevel = 4
WHERE Name = 'MeuPike';
```

## Como editar uma conta manualmente no banco

Tabela:

- `UserDB.dbo.UserInfo`

### Exemplo: criar conta manualmente com hash correto

```sql
USE UserDB;
GO

DECLARE @Login varchar(32) = 'manualgm';
DECLARE @Password varchar(32) = '123456';
DECLARE @PasswordHash varchar(64) =
    CONVERT(varchar(64), HASHBYTES('SHA2_256', UPPER(@Login) + ':' + @Password), 2);

INSERT INTO dbo.UserInfo
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
    @Login,
    @PasswordHash,
    'Mar 15 2026  5:00PM',
    114,
    1,
    '0',
    1500,
    'manualgm@local.test',
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
```

### Exemplo: mudar uma conta existente para Admin

```sql
USE UserDB;
GO

UPDATE dbo.UserInfo
SET GameMasterType = 1,
    GameMasterLevel = 4,
    Flag = 114,
    Active = 1
WHERE AccountName = 'manualgm';
```

## Quando eu devo usar script e quando devo usar SQL manual

Use script quando:

- voce quer o caminho mais seguro
- precisa criar conta com senha correta
- quer reaproveitar um personagem pronto
- nao quer lembrar o hash da senha

Use SQL manual quando:

- voce quer corrigir um campo especifico
- precisa inspecionar dados direto no banco
- vai fazer ajuste fino em conta ou personagem

## O que nao vale a pena fazer na mao

- criar personagem do zero sem `.chr`
- editar inventario direto sem entender o formato do `.chr`
- tentar trocar senha escrevendo texto puro na coluna `Password`

## Fluxo recomendado para testes locais

1. garanta que o SQL e o server estao ligados
2. crie ou atualize a conta com `provision-pt-test-account.ps1`
3. se precisar de outro char, clone com `clone-pt-character-template.ps1`
4. entre no jogo
5. ative GM com `/activategm`

## Se a conta parou de funcionar depois de restore

Isso normalmente acontece porque `restore-pt-docker-dbs.ps1` sobrescreve `UserDB`.

Solucao:

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'dedezin' `
  -Password 'dedezin123' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 4
```

Para detalhes do problema, veja:

- `docs/troubleshooting/local-runtime-known-issues.md`
