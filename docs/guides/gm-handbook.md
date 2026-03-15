# GM Handbook

Atualizado em: 2026-03-15

Este guia e o manual pratico para quem vai administrar o servidor dentro do jogo.
Ele foi escrito pensando em alguem que nao conhece o source nem o banco.

Use esta doc junto com:

- `docs/reference/server-commands-reference.md`: lista completa dos comandos encontrados no source
- `docs/reference/map-id-reference.md`: IDs de mapa com nome
- `docs/reference/item-id-reference.md`: item codes com nome
- `docs/reference/monster-id-reference.md`: IDs de monstro com nome
- `docs/guides/events-and-rates-guide.md`: eventos, bonus, rates e manutencao

## O que e GM e o que e Admin

No banco existem dois controles principais:

- `GameMasterType`: liga ou desliga a permissao de GM na conta
- `GameMasterLevel`: define o nivel do GM, de `1` ate `4`

No personagem tambem existe:

- `CharacterInfo.GMLevel`: nivel de GM salvo no personagem

Na pratica, no ambiente local deste repo:

- `GameMasterType = 1` significa que a conta pode usar GM
- `GameMasterLevel = 4` significa Admin / GM4
- GM4 herda comandos de GM1, GM2, GM3 e Admin

## Antes de usar qualquer comando

Sempre siga esta ordem:

1. ligue o server
2. entre no jogo
3. escolha o personagem
4. ative o modo GM com `/activategm`

Se der certo, o chat deve avisar algo como `GM level X activated`.

Para sair do modo GM:

```text
/deactivategm
```

## Como ler a sintaxe dos comandos

Quando a documentacao mostrar algo assim:

```text
/getitem <itemCode> [classShort] [specAtk] [age]
```

Leia assim:

- tudo que esta entre `< >` e obrigatorio
- tudo que esta entre `[ ]` e opcional
- voce precisa digitar a barra `/`
- o comando e digitado no chat do jogo

## Fluxos prontos do dia a dia

### 1. Teleportar para um mapa

Voce precisa de:

- `mapId`
- coordenadas `x` e `z`

Comando:

```text
/wrap <mapId> <x> <z>
```

Exemplo:

```text
/wrap 3 0 0
```

Observacao importante:

- o ID do mapa voce acha em `docs/reference/map-id-reference.md`
- as coordenadas dependem do mapa
- se voce nao souber uma coordenada segura, prefira usar `/near <char>` para ir ate um personagem online

### 2. Ir ate um personagem ou puxar ele ate voce

Ir ate a pessoa:

```text
/near NomeDoPersonagem
```

Puxar a pessoa ate voce:

```text
/call NomeDoPersonagem
```

### 3. Criar item para voce

Passo 1:

- ache o item code em `docs/reference/item-id-reference.md`
- ou use `.\scripts\find-pt-item.ps1 -Search "nome do item"`

Passo 2:

- rode o comando no jogo

Exemplo simples:

```text
/getitem wa131
```

Esse exemplo usa o item code da `Abyss Axe`.

Exemplo para enviar item ao distribuidor da conta:

```text
/giveitem dedezin wa131
```

Exemplo de item perfeito:

```text
/getitemperf wa131 1
```

### 4. Dar gold

```text
/GetGold 1000000
```

Isso adiciona gold ao personagem atual.

## 5. Dar EXP ou subir level

Adicionar EXP bruta:

```text
/!giveexp 100000000
```

Subir para o level informado:

```text
/!levelup 100
```

Observacao:

- o comando de level sobe o personagem atual para a EXP daquele level
- para o level aparecer corretamente, entre no mapa, troque de mapa ou relogue se necessario

### 6. Aumentar EXP do servidor e quantidade de drop

Bonus de EXP global:

```text
/expevent 100
```

Leitura:

- `100` significa `+100%`
- `0` desliga o bonus

Quantidade extra de drops:

```text
/extradrop 2
```

Leitura:

- isso aumenta a quantidade extra de itens gerados por monstro
- isso nao significa, necessariamente, mudar a chance base da tabela

### 7. Aplicar bonus premium em todo mundo

```text
/BONUSALL
```

Esse comando aplica buffs premium para todos os jogadores online naquele momento, incluindo bonus de EXP e drop.

### 8. Abrir manutencao

Contagem de 5 minutos:

```text
/StartMaintenance 300
```

Cancelar:

```text
/StopMaintenance
```

## Eventos mais usados

Os eventos mais comuns aceitam `true` ou `false`.

Exemplos:

```text
/event_agingfree true
/event_agingnobreak true
/event_Halloween true
/event_Christmas false
/event_Easter true
/event_Valentine true
/event_Bee true
/event_StarWars false
/event_reducemondmg true
```

Para detalhes de cada um, use `docs/guides/events-and-rates-guide.md`.

## Moderacao

Mutar jogador:

```text
/!mute NomeDoChar "motivo"
```

Desmutar:

```text
/!unmute NomeDoChar
```

Kick:

```text
/kickch NomeDoChar
```

Banir conta:

```text
/banacc NomeDoChar motivo
```

Desbanir conta:

```text
/unbanacc LoginDaConta
```

## Como descobrir IDs e nomes sem decorar nada

### Itens

Arquivos e utilitarios:

- `docs/reference/item-id-reference.md`
- `docs/reference/item-code-and-data-reference.md`
- `.\scripts\find-pt-item.ps1 -Search "Abyss Axe"`

### Mapas

Arquivos e utilitarios:

- `docs/reference/map-id-reference.md`
- `.\scripts\find-pt-map.ps1 -Search "Ricarten"`
- `.\scripts\find-pt-map.ps1 -Search "3"`

### Monstros

Arquivos e utilitarios:

- `docs/reference/monster-id-reference.md`
- `.\scripts\find-pt-monster.ps1 -Search "Kelvezu"`
- `.\scripts\find-pt-monster.ps1 -Search "1188"`

## Regras de seguranca para GM

- sempre confirme se o comando vai afetar so voce, um player, o mapa atual ou o servidor inteiro
- teste primeiro com uma conta de desenvolvimento
- evite mexer em rates globais no meio de teste de banco
- antes de mudar evento global, anote o valor antigo
- antes de apagar ou transferir personagem, confirme o nome da conta no banco

## Se algo der errado

Os problemas mais comuns estao em:

- `docs/troubleshooting/local-runtime-known-issues.md`

Os sintomas mais comuns sao:

- `connection failed`
- `incorrect password`
- personagem sem pertencer a conta
- evento ligado mas sem efeito por causa de banco ou schema

## Referencia completa

Esta doc e um handbook pratico.
Para a lista completa dos comandos encontrados em `Server/server/servercommand.cpp`, use:

- `docs/reference/server-commands-reference.md`
