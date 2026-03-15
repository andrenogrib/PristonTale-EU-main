# Priston Tale Docs

Atualizado em: 2026-03-15

Esta pasta guarda a documentacao local do projeto e do pacote `Files` que foi copiado para dentro do repo.

## O que tem aqui

- `project-analysis.md`: resumo tecnico do que existe no pacote `Files`, como o client/server estao configurados e quais dependencias faltam para subir o ambiente.
- `setup-run-test-guide.md`: guia pratico para restaurar banco, alinhar configuracoes, subir os servidores, abrir o client e testar login.
- `server-commands-reference.md`: referencia dos comandos de player, GM1, GM2, GM3 e GM4/Admin definidos em `Server/server/servercommand.cpp`.
- `item-code-and-data-reference.md`: guia de onde achar `itemCode`, `ItemID`, nome de item, tabelas de drop, spawn e monster stats.
- `scripts/patch-pt-client-localhost.ps1`: patch utilitario para alinhar o `Files/Game/game.dll` com localhost quando o runtime pack vier compilado para IP publico.
- `scripts/assign-pt-character-to-account.ps1`: utilitario para vincular um personagem ja existente do banco a uma conta de teste quando a criacao de personagem estiver falhando por driver/schema.
- `scripts/find-pt-item.ps1`: busca em `GameDB.dbo.ItemList` ou `ItemListOld` por nome, `itemCode` ou `ItemID`.

## Convencao de revisao

Sim, vale a pena colocar data nas docs.

- Use sempre `Atualizado em: AAAA-MM-DD` no topo.
- Quando mudar runtime, banco, senha, IP, driver SQL ou fluxo de start, atualize a data.
- Se a mudanca for grande, acrescente um pequeno resumo no topo dizendo o que foi revisado.

## Regra pratica para este repo

- O source e os scripts valem a pena ficar no Git.
- A pasta `Files` tem cerca de `10.9 GB`, entao o ideal e tratar isso como runtime pack local, release asset, storage externo ou Git LFS.
- Para manter historico confiavel, documente sempre o estado real do runtime pack que esta sendo usado junto do source.
- Se houver diferenca entre source e binario de `Files/`, documente a divergencia explicitamente e registre como corrigi-la.

## Navegacao rapida

Quando a duvida for "onde eu acho isso?", use este atalho:

- comando de GM ou player: `docs/server-commands-reference.md`
- item code, ItemID, drop ou monstro: `docs/item-code-and-data-reference.md`
- setup local e ordem de boot: `docs/setup-run-test-guide.md`
- analise do runtime pack e riscos conhecidos: `docs/project-analysis.md`
