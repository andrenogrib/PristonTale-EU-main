# Priston Tale Docs

Atualizado em: 2026-03-15

Esta pasta guarda a documentacao local do projeto e do pacote `Files` que foi copiado para dentro do repo.

## Setores recomendados

Para este projeto, eu recomendo estes setores:

- `docs/guides/`: guias operacionais, setup, start, teste e runbooks
- `docs/analysis/`: analises tecnicas do runtime pack, source, banco e divergencias
- `docs/reference/`: lookup rapido de comandos, item codes, tabelas e pontos de source
- `docs/studies/`: estudos mais profundos, investigacoes e material exploratorio
- `docs/troubleshooting/`: erros recorrentes, causa raiz, workaround e correcao definitiva

Essa divisao funciona bem aqui porque o projeto mistura:

- source C++ de client e server
- runtime pack grande fora do fluxo normal de Git
- banco SQL com dependencia forte de schema
- scripts operacionais para subir e testar ambiente
- investigacoes recorrentes sobre binario, DB e compatibilidade

## O que tem em cada setor

- `docs/guides/server-start-guide.md`: guia operacional focado so em ligar, parar e testar o server local usando os scripts do repo
- `docs/guides/setup-run-test-guide.md`: guia pratico mais completo para restaurar banco, alinhar configuracoes, subir os servidores, abrir o client e testar login
- `docs/analysis/project-analysis.md`: resumo tecnico do que existe no pacote `Files`, como o client/server estao configurados e quais dependencias faltam para subir o ambiente
- `docs/reference/server-commands-reference.md`: referencia dos comandos de player, GM1, GM2, GM3 e GM4/Admin definidos em `Server/server/servercommand.cpp`
- `docs/reference/item-code-and-data-reference.md`: guia de onde achar `itemCode`, `ItemID`, nome de item, tabelas de drop, spawn e monster stats
- `docs/studies/README.md`: definicao do setor de estudos e investigacoes futuras
- `docs/troubleshooting/README.md`: definicao do setor de incidentes e correcoes operacionais
- `docs/troubleshooting/local-runtime-known-issues.md`: erros reais ja vistos no setup local, com causa raiz e workaround
- `scripts/patch-pt-client-localhost.ps1`: patch utilitario para alinhar o `Files/Game/game.dll` com localhost quando o runtime pack vier compilado para IP publico.
- `scripts/assign-pt-character-to-account.ps1`: utilitario para vincular um personagem ja existente do banco a uma conta de teste quando a criacao de personagem estiver falhando por driver/schema.
- `scripts/fix-pt-local-runtime.ps1`: workaround rapido para o ambiente local. Ajusta o gold do `Administrador`, limpa timers invalidos e vincula personagens de teste conhecidos a `admin`.
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

- comando de GM ou player: `docs/reference/server-commands-reference.md`
- item code, ItemID, drop ou monstro: `docs/reference/item-code-and-data-reference.md`
- setup local e ordem de boot: `docs/guides/setup-run-test-guide.md`
- ligar e parar o server pelo fluxo com scripts: `docs/guides/server-start-guide.md`
- analise do runtime pack e riscos conhecidos: `docs/analysis/project-analysis.md`
- bugs de login, cheat `99007` e falha na criacao de personagem: `docs/troubleshooting/local-runtime-known-issues.md`
