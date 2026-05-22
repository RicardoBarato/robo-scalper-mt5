# Presets RB Ouro

Este arquivo registra as principais versoes salvas do `RB_Ouro_v4_4_Port` e o motivo de cada uma existir.

Todos os resultados abaixo foram testados em XAUUSD M1, periodo 2023.05.20 a 2026.05.20, deposito inicial 1000 USD, alavancagem 1:500. Os presets permanecem com `InpEnableLiveOrders=false` por seguranca.

## Comparativo rapido

| Preset | Ideia | Dias | Horas | Retorno | Trades | Winrate | PF | DD aprox. | DD % aprox. |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `RB_Ouro_v4_4_Port.refined.set` | Expressiva original, risco alto mas controlado | Seg/Ter | 3,14 | +85.65% | 74 | 50.00% | 1.52 | 228.76 | 14.43% |
| `RB_Ouro_v4_4_Port.rocket-mon-tue.set` | Crescimento maximo aceitando grande oscilacao | Seg/Ter | 3,14 | +238.46% | 74 | 50.00% | 1.44 | 954.60 | 34.14% |
| `RB_Ouro_v4_4_Port.rocket-monday.set` | Nucleo mais limpo da rocket | Seg | 3,14 | +136.26% | 36 | 55.56% | 1.93 | 423.48 | 26.43% |
| `RB_Ouro_v4_4_Port.adaptive-week.set` | Semana viva com risco por contexto | Todos | 1,3,14,15,22 | +218.55% | 127 | 46.46% | 1.52 | 613.66 | 19.82% |
| `RB_Ouro_v4_4_Port.quality-hybrid.set` | MTF + reteste apenas quando esticado | Todos | 1,3,14,15,22 | +52.14% | 41 | 53.66% | 1.64 | 325.07 | 25.94% |
| `RB_Ouro_v4_4_Port.quality-retest.set` | Reteste obrigatorio apos rompimento | Todos | 1,3,14,15,22 | -12.24% | 70 | 44.29% | 0.90 | 611.81 | 45.80% |
| `RB_Ouro_v4_4_Port.quality-mtf-direct.set` | Rompimento direto com confirmacao M5/M15 | Todos | 1,3,14,15,22 | +113.80% | 36 | 63.89% | 2.59 | 258.51 | 20.65% |
| `RB_Ouro_v4_4_Port.quality-mtf-rocket.set` | MTF direct com risco alto controlado | Todos | 1,3,14,15,22 | +177.88% | 40 | 60.00% | 2.23 | 518.87 | 32.96% |
| `RB_Ouro_v4_4_Port.quality-mtf-ultra.set` | MTF direct agressivo para capital pequeno | Todos | 1,3,14,15,22 | +379.76% | 56 | 55.36% | 1.97 | 1342.49 | 45.87% |
| `RB_Ouro_v4_4_Port.quality-mtf-trendrunner.set` | H4 trend runner com TP maior e trailing ATR | Todos | 1,3,14,15,22 | +481.54% | 36 | 61.11% | 2.77 | 1183.25 | 32.20% |
| `RB_Ouro_v4_4_Port.ustec-curiosity.set` | Curiosidade USTEC com o mesmo cerebro | Seg/Ter | 3,14 | 0.00% | 0 | 0.00% | 0 | 0.00 | 0.00% |

## Diferenciais

### `refined.set`

Primeiro preset que ficou realmente promissor. Usa somente compra, horas 3 e 14, segunda e terca, risco expressivo mas abaixo da rocket. E uma boa referencia de estabilidade relativa.

### `rocket-mon-tue.set`

Versao de capital pequeno e descartavel. Cresce mais, mas o drawdown quase encosta no tamanho da conta inicial. Serve para teste agressivo, nao como perfil principal sem forward.

### `rocket-monday.set`

Reduz a exposicao para segunda-feira. O retorno cai, mas o profit factor melhora bastante. E a versao mais bonita quando o criterio principal e qualidade por trade.

### `adaptive-week.set`

Resposta ao problema de limitar dias. Ela nao bloqueia dias uteis: usa `weekday_risk_multipliers` e `hour_risk_multipliers` para graduar risco, e endurece os filtros quando a qualidade do contexto e baixa.

Exemplo do preset atual:

- segunda: risco cheio;
- terca: risco reduzido;
- quarta/sexta: risco menor, mas ainda pode capturar movimento;
- quinta: risco simbolico e filtro duro, porque historicamente foi ruim;
- horas 3 e 14: risco principal;
- horas 15 e 22: risco menor;
- hora 1: quase experimental.

Este preset preserva oportunidades fora de segunda/terca, mas evita tratar todos os contextos como iguais.

### `quality-hybrid.set`

Primeira resposta aos sinais MQL5 estudados em 2026-05-21. Usa confirmacao de EMA em M5/M15, evita rompimentos muito esticados, permite entrada direta quando o candle ainda nao fugiu e arma reteste quando o preco estica demais.

Melhorou winrate/PF, mas reduziu demais o retorno. Serve como experimento de limpeza, nao como candidato principal.

### `quality-retest.set`

Forca esperar pullback depois do rompimento. Foi rejeitado pelo backtest: o ouro realmente volta muito apos romper, mas esse gatilho de reteste ficou tarde e destruiu a assimetria.

### `quality-mtf-direct.set`

Versao de qualidade mais limpa ate agora. Mantem rompimento direto, mas exige convergencia M5/M15 e bloqueia entrada quando o preco ja esta esticado demais contra o nivel rompido.

Resultado de 3 anos: winrate 63.89%, PF 2.59, retorno +113.80% e DD aprox. 20.65%. E o melhor perfil tecnico para transformar em algo mais vendavel/estavel.

### `quality-mtf-rocket.set`

Escala risco sobre a `quality-mtf-direct`, dando mais peso aos contextos que carregaram retorno e menor risco aos dias/horarios fracos. Entregou +177.88% em 3 anos, com PF 2.23 e DD 32.96%.

### `quality-mtf-ultra.set`

Versao agressiva para capital pequeno. Em 3 anos entregou +379.76%, PF 1.97, winrate 55.36% e DD 45.87%. Em 5 anos entregou +212.80%, PF 1.70, winrate 54.10% e DD 44.88%.

Conclusao: e a maior potencia da familia v4.5, mas ainda nao e perfil limpo. O ano de 2022 foi negativo e mostra que precisamos de um filtro de regime macro/overextension antes de pensar em producao.

### `quality-mtf-trendrunner.set`

Versao criada para capturar mais do movimento estrutural do ouro. Usa vies H4, confirmacao M15/H1, TP mais distante e trailing por ATR. A ideia e deixar os melhores movimentos andarem, em vez de encerrar todos os trades com alvo curto de scalper.

Resultado de 3 anos: +481.54%, winrate 61.11%, PF 2.77, DD aprox. 32.20%, 36 trades. Resultado de 5 anos: +206.50%, winrate 58.97%, PF 2.19, DD aprox. 43.65%, 39 trades.

Conclusao: e o melhor candidato agressivo ate agora. Ele supera a `quality-mtf-ultra` no periodo de 3 anos com PF maior e DD menor, mas ainda mostra fragilidade em 2022. Deve ser a base da proxima rodada, com filtro de regime para evitar operar long em ambiente macro ruim.

### `ustec-curiosity.set`

Foi testado em USTEC com dados completos e gerou zero trades. Conclusao: o setup atual e especifico do XAUUSD; para USTEC, o correto e criar outro perfil de filtros, nao reutilizar o do ouro.

## Nova logica no codigo

O EA agora tem dois grupos de filtro:

- filtros duros: `trade_hour_mask` e `trade_weekday_mask`, quando queremos bloquear explicitamente;
- filtros graduais: `weekday_risk_multipliers`, `hour_risk_multipliers`, `weak_quality_*`.

Quando o contexto e fraco, o robo:

- reduz o risco;
- exige ADX maior;
- exige candle de impulso maior;
- exige fechamento mais forte perto da extremidade do candle.

Essa abordagem deve ser a base das proximas evolucoes, porque evita perder dias inteiros sem abrir a porta para o caos.

## Logica v4.5

Os novos presets usam recursos opcionais adicionados ao EA:

- confirmacao de tendencia em M5/M15 por pilha de EMAs;
- bloqueio de rompimento esticado por ATR;
- gatilho de reteste apos rompimento, mantido para pesquisa mas rejeitado no preset puro;
- break-even opcional por R;
- filtro de risco por drawdown da propria equity;
- parser atualizado para registrar DD nominal, DD percentual, pico e fundo da queda.
