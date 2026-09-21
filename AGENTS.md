# Dreads Craft — orientação para Codex

- Converse em português. O usuário não quer emojis no código/interface nem dicas de comandos sobre o jogo.
- Este é um projeto Godot 4.7.2 com GDScript. Não volte a implementar o jogo em HTML.
- Preserve assets originais de Heitor. Os arquivos image-001 e image-002 eram JPEG identificados como PNG no HTML; apenas a extensão foi corrigida.
- Sobrevivência usa Spike normal; Criativo usa Spike demônio. Modo definido na criação do mundo.
- Direção vem do movimento. Somente o ataque pode virar o personagem para o mouse.
- Mineração/colocação usam a mesma célula, com alcance, obstrução e bloqueio de sobreposição com o jogador.
- Craft de tábuas e bancada é manual; equipamentos exigem bancada na Sobrevivência.
- Não apague saves do usuário. Testes usam DreadsCraftTests. Antes de mudar formato, implemente migração e preserve backups.
- Rode Godot --headless --path . --script tests/smoke.gd. Verifique logs: Godot pode retornar 0 mesmo com alguns erros de script.
- Prioridades seguintes: NPC e missão, vários slots de mundos, polimento visual em janela, mais frames de animação, importação dos saves do HTML, segmentação do mundo em chunks.
- Abra README.md para o estado exato da migração. Não afirme que todos os sistemas antigos foram migrados.
