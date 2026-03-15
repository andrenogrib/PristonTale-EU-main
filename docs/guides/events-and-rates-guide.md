# Events And Rates Guide

Atualizado em: 2026-03-15

Este guia explica como mexer em bonus de EXP, drop, eventos sazonais e manutencao.

## Dois jeitos de mexer em rates

Neste projeto existem dois caminhos principais:

- configuracao fixa em `Files/Server/game-server/server.ini`
- comando de GM dentro do jogo

## Rates do `server.ini`

No `server.ini` do game server, os campos mais importantes hoje estao no bloco `[Event]`.

Exemplos do ambiente local:

- `RateExp=1`
- `EventExp=0`
- `WantedMoriph=Off`
- `WantedWolf=Off`
- `Easter=Off`
- `Xmas=off`
- `Halloween=Off`
- `ValentineDay=Off`

Leitura pratica:

- `RateExp=1` significa taxa base de EXP
- os flags `On` e `Off` sao o estado inicial do server ao subir
- comandos de GM podem mudar o estado em runtime

## Bonus de EXP global

Comando:

```text
/expevent <0-1000>
```

Exemplos:

```text
/expevent 0
/expevent 100
/expevent 300
```

Leitura:

- `0` = sem bonus extra
- `100` = `+100%`
- `300` = `+300%`

## Bonus de drop

Comando:

```text
/extradrop <qtd>
```

Exemplos:

```text
/extradrop 0
/extradrop 1
/extradrop 2
```

Leitura:

- isso muda a quantidade extra de drops gerados
- isso nao e a mesma coisa que editar a chance base no banco

## Bonus premium em todos os players

Comando:

```text
/BONUSALL
```

Esse comando aplica, para todos os jogadores online:

- regen HP
- regen MP
- regen SP
- damage bonus
- absorb bonus
- move speed
- EXP buff
- drop buff

## Eventos simples com `true` ou `false`

Os comandos abaixo seguem o padrao:

```text
/comando true
/comando false
```

### Aging

```text
/event_agingfree true
/event_agingnobreak true
/event_aginghalfprice true
```

Uso:

- `agingfree`: aging sem custo
- `agingnobreak`: aging sem quebrar
- `aginghalfprice`: aging com preco reduzido

### Eventos sazonais e tematicos

```text
/event_Halloween true
/event_Christmas true
/event_Easter true
/event_Valentine true
/event_StarWars true
/event_Bee true
/event_Mimic true
/event_girl true
```

Para desligar, troque `true` por `false`.

### Outros eventos simples

```text
/event_reducemondmg true
/event_crystal true
/event_treasurehunting true
```

## Eventos especiais Wanted

Estes dois aceitam formas mais avancadas:

- `/event_WantedMoriph`
- `/event_WantedWolf`

Usos aceitos pelo source:

```text
/event_WantedMoriph true
/event_WantedMoriph false
/event_WantedMoriph true <spawn count> <spawn delay>
/event_WantedMoriph reset
/event_WantedMoriph titles
```

```text
/event_WantedWolf true
/event_WantedWolf false
/event_WantedWolf true <spawn count> <spawn delay>
/event_WantedWolf reset
/event_WantedWolf titles
```

Leitura:

- `true`: liga
- `false`: desliga
- `true <spawn count> <spawn delay>`: liga com ajuste de spawn
- `reset`: reseta estatisticas de kill
- `titles`: distribui titulos por kills

## PVP em runtime

### Definir mapa de PVP

```text
/PVPMap <mapId>
```

Para desativar, o source aceita `-1`.

### Ajustar escalas de PVP

O comando base e:

```text
/pvp <chave> <valor>
```

Exemplos encontrados no source:

```text
/pvp dmg_scale_lvl 1.20
/pvp abs_scale_lvl 0.80
/pvp global_dmg_reduction 0.10
```

Observacao:

- esse bloco tem varias chaves
- para ajuste fino, confirme a lista completa em `docs/reference/server-commands-reference.md`

## Manutencao

Iniciar contagem:

```text
/StartMaintenance 300
```

Cancelar:

```text
/StopMaintenance
```

O que acontece:

- o game server avisa os jogadores
- a informacao e enviada para o login server
- a contagem e iniciada nos dois lados

## Quando usar ini e quando usar comando

Use `server.ini` quando:

- voce quer o valor padrao do server
- quer que o valor ja suba com o server

Use comando de GM quando:

- voce quer mudar em tempo real
- quer testar evento sem reiniciar
- quer fazer acao temporaria

## Fluxos prontos

### Ligar evento de EXP para teste

```text
/expevent 100
```

### Ligar drop extra e buff premium

```text
/extradrop 2
/BONUSALL
```

### Fazer fim de semana de aging

```text
/event_agingfree true
/event_agingnobreak true
/event_aginghalfprice true
```

### Fazer evento sazonal

```text
/event_Halloween true
```

ou

```text
/event_Christmas true
```

### Encerrar manutencao

```text
/StopMaintenance
```

## Boas praticas

- anote o valor antigo antes de mudar
- mude uma coisa por vez
- se o efeito for global, avise os jogadores
- use a conta de teste primeiro quando o evento mexer com drop ou exp
- se mudar o `server.ini`, reinicie o server para o valor fixo entrar

## Referencias uteis

- `docs/guides/gm-handbook.md`
- `docs/reference/server-commands-reference.md`
- `docs/reference/map-id-reference.md`
- `docs/reference/monster-id-reference.md`
