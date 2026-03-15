# Client Localhost Patch Guide

Atualizado em: 2026-03-15

Este guia explica o ajuste que tivemos que fazer no `game.dll` para o client local conseguir logar no server rodando na sua maquina.

## O problema

Mesmo com o source apontando para localhost, o client binario que veio dentro de `Files/Game/` ainda podia estar compilado para um IP antigo de producao.

Sintoma tipico:

- o login server esta online
- o game server esta online
- voce abre `Files/Game/Game.exe`
- digita login e senha corretos
- aparece `connection failed`

## Por que isso acontece

O que manda no runtime pronto e o binario que o jogo esta usando naquele momento.

Ou seja:

- o source pode estar certo
- os `.ini` podem estar certos
- mas, se `Files/Game/game.dll` ainda estiver apontando para IP publico, o `Game.exe` vai tentar conectar no lugar errado

## O que foi feito neste repo

No ambiente local que montamos, o `game.dll` do runtime pack tinha uma referencia ao IP:

```text
15.204.184.155
```

E o ambiente local precisava falar com:

```text
127.0.0.1
```

Por isso foi criado o script:

- `scripts/patch-pt-client-localhost.ps1`

## O que o script faz

Ele:

- abre `Files/Game/game.dll`
- procura a string ASCII do IP antigo
- troca pelo IP local
- cria um backup automatico `game.dll.bak`
- valida se a troca realmente aconteceu

## Como rodar

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

Se o script encontrar varias ocorrencias e voce quiser trocar todas:

```powershell
.\scripts\patch-pt-client-localhost.ps1 -Force
```

## Como saber se precisa rodar

Normalmente voce precisa rodar quando:

- copiou um runtime pack novo para `Files/`
- o repo original veio preparado para um servidor remoto
- o jogo abre, mas a conexao falha mesmo com os servers locais online

Se o script disser que o client ja aponta para `127.0.0.1`, nao precisa fazer mais nada.

## O que o script nao faz

Ele nao:

- compila o client
- muda o source C++
- altera o `server.ini`
- cria conta
- restaura banco

Ele so corrige o alvo de conexao do `game.dll` binario.

## Ordem recomendada no primeiro setup

1. `.\scripts\start-pt-docker-sql.ps1`
2. `.\scripts\restore-pt-docker-dbs.ps1`
3. `.\scripts\patch-pt-client-localhost.ps1`
4. `.\scripts\fix-pt-local-runtime.ps1`
5. `.\scripts\start-pt-server.ps1`
6. abrir `Files/Game/Game.exe`

## Como voltar atras

O script salva um backup:

```text
Files/Game/game.dll.bak
```

Se voce precisar desfazer:

1. feche o jogo
2. substitua `game.dll` pelo `game.dll.bak`

## Dica importante para quem usar o repo original

Sempre trate `Files/` como runtime separado do source.

Na pratica:

- o repo pode dizer uma coisa
- o binario do runtime pode estar apontando para outra

Entao, quando copiar um runtime pack externo, faca estes checks:

1. `server.ini` do login server
2. `server.ini` do game server
3. `game.dll` do client
4. banco restaurado
5. contas de teste

## Quando suspeitar que o problema e o `game.dll`

Suspeite do `game.dll` quando:

- o login server recebe conexoes, mas o client falha antes de entrar
- o source esta configurado para localhost
- o runtime pack veio de outro ambiente

Se isso acontecer, rode o patch antes de sair mexendo no source.
