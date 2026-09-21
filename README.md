# Atualização v11 — Dimensão da Pureza

Veja CHANGELOG-v11.txt para a progressão, os testes e as limitações desta versão.
Diamante e avarita são gerados em mundos novos. Saves antigos mantêm o terreno existente.
A imagem do diálogo não chegou: o texto provisório está em scripts/purity_dialogue.gd.

# Atualização v10

Veja CHANGELOG-v10.txt para as mudanças e limitações. Esta versão parte da v9 enviada pelo usuário.

# Dreads Craft — primeira base nativa

Projeto Godot 4.7.2, GDScript, renderizador Compatibility. Criado a partir da versão PC do Dreads Craft, preservando as imagens originais. Não usa HTML ou navegador para executar.

## Abrir no Windows

Extraia o ZIP e execute `Instalar-e-abrir.cmd`. O arquivo baixa o Godot 4.7.2 x64 do endereço oficial, extrai para `.tools` dentro deste projeto e abre o editor. Não precisa de instalação global nem altera PATH ou políticas do Windows. Requer conexão com a internet e PowerShell. O comando foi preparado, mas não foi executado em Windows neste ambiente Linux.

Se você já tem Godot, importe `project.godot`. No editor, F6 executa a cena aberta e F5 executa o projeto. Para abrir no VS Code, abra esta pasta inteira. As modificações do código nesta pasta serão lidas pelo Godot; não existe sincronização automática com o chat.

Download manual oficial: https://godotengine.org/download/windows/

## Entregue nesta etapa

- Spike normal e demônio com quadros de idle, caminhada, salto, ataque e dano.
- Personagem CharacterBody2D: física nativa, colisões, tolerância de pulo e voo no Criativo.
- Criação de mundo com nome, seed e modo travado após criar.
- Terreno de 320 x 96 blocos, cavernas conectadas, entradas de minas, árvores e ruínas.
- Quebrar e colocar na célula sob o mouse, com alcance, obstrução e proteção contra colocar dentro do Spike.
- Inventário, barra de itens e crafting manual / bancada.
- Esqueleto e lobo com perseguição, combate e animação de morte; aparecem à noite, exceto no Pacífico.
- Vida, fome, carne consumível, dia/noite, pausa e dificuldade.
- Um slot de mundo salvo com backup, salvamento a cada 20 segundos e ao sair.
- Interface sem emojis e sem dicas de teclas sobre o jogo.


## Passe visual para PC

Esta versão recebeu um passe visual voltado ao PC: menu principal dark medieval, fundo de menu próprio, HUD com molduras góticas, barras de vida e fome, relógio central, botões de inventário/criação/menu/tela cheia com ícones, hotbar central com sprites de itens e nome do item selecionado. Os blocos de terra, grama, pedra, madeira, folhas, tábuas, bancada, carvão e ferro agora usam texturas pixel art consistentes; carvão e ferro compartilham a mesma base de pedra para manter os minérios padronizados. O cenário distante também foi reforçado com lua, névoa, estrelas, montanhas, castelo e ruínas em múltiplos planos.

Os ícones e molduras visuais ficam em `assets/items`, `assets/tiles` e `assets/ui`.

## Limites desta etapa

É a primeira etapa da migração, não uma cópia completa do HTML. NPC/missões e Relíquia Vital ainda não têm sua lógica portada; as imagens do NPC estão preservadas para a próxima etapa. O menu de múltiplos mundos e a importação dos saves do navegador também ficam para a próxima etapa. Criar outro mundo substitui o slot atual; o backup é atualizado a cada salvamento. Não há multiplayer.

O save nativo é independente do localStorage do navegador. O jogo HTML e seus saves não foram alterados. Os quadros existentes de ataque são poses únicas: não foram criados sprites novos nesta entrega.

## Código

- `scenes/main.tscn`: cena principal.
- `scripts/main.gd`: sessão, menus, interação com blocos e ciclo do mundo.
- `scripts/player.gd`: personagem e física.
- `scripts/world.gd`: geração, desenho visível e colisores por segmentos de linha.
- `scripts/items.gd`: itens e receitas.
- `scripts/mob.gd`: inimigos e combate.
- `scripts/sprites.gd`: recortes AtlasTexture e animação dos sprites existentes.
- `scripts/save_game.gd`: gravação e leitura de saves versionados.
- `scripts/backdrop.gd`: cenário de fundo.
- `scripts/selection.gd`: mira e progresso de mineração desenhados acima do mundo.
- `tests/smoke.gd`: integração executada pela engine, em diretório separado de testes.

## Comandos (fora da interface do jogo)

A/D ou setas: andar. Espaço/W: pular/subir. S/Shift: descer no Criativo. Mouse esquerdo: minerar ou atacar com espada selecionada. Mouse direito: colocar, usar bancada ou comer carne selecionada. F: atacar. E: inventário. C: craft. Esc: pausa/fechar. 1–6 ou roda: item.

## Validação

Godot 4.7.2 instalado e executado no ambiente Linux. Importação de recursos e testes reais em modo headless. Os testes cobrem terreno, animações disponíveis, colisão com chão, direção, pulo, colocação e consumo de bloco, craft manual, bloqueio de receitas avançadas, menus, mobs/recompensa, save/load e voo ao apertar/soltar.

Executar: `godot --headless --path . --script tests/smoke.gd`

A validação visual com janela e o instalador Windows ainda precisam de teste no PC. O ambiente não tinha servidor gráfico disponível.
