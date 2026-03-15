# Priston Tale Docs

Atualizado em: 2026-03-15

Esta pasta guarda a documentacao local do projeto e do pacote `Files` que foi copiado para dentro do repo.

## O que tem aqui

- `project-analysis.md`: resumo tecnico do que existe no pacote `Files`, como o client/server estao configurados e quais dependencias faltam para subir o ambiente.
- `setup-run-test-guide.md`: guia pratico para restaurar banco, alinhar configuracoes, subir os servidores, abrir o client e testar login.

## Convencao de revisao

Sim, vale a pena colocar data nas docs.

- Use sempre `Atualizado em: AAAA-MM-DD` no topo.
- Quando mudar runtime, banco, senha, IP, driver SQL ou fluxo de start, atualize a data.
- Se a mudanca for grande, acrescente um pequeno resumo no topo dizendo o que foi revisado.

## Regra pratica para este repo

- O source e os scripts valem a pena ficar no Git.
- A pasta `Files` tem cerca de `10.9 GB`, entao o ideal e tratar isso como runtime pack local, release asset, storage externo ou Git LFS.
- Para manter historico confiavel, documente sempre o estado real do runtime pack que esta sendo usado junto do source.
