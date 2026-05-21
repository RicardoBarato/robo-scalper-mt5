# Presets RB Ouro

Este arquivo registra as principais versoes salvas do `RB_Ouro_v4_4_Port` e o motivo de cada uma existir.

Todos os resultados abaixo foram testados em XAUUSD M1, periodo 2023.05.20 a 2026.05.20, deposito inicial 1000 USD, alavancagem 1:500. Os presets permanecem com `InpEnableLiveOrders=false` por seguranca.

## Comparativo rapido

| Preset | Ideia | Dias | Horas | Retorno | Trades | Winrate | PF | DD aprox. |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `RB_Ouro_v4_4_Port.refined.set` | Expressiva original, risco alto mas controlado | Seg/Ter | 3,14 | +85.65% | 74 | 50.00% | 1.52 | 228.76 |
| `RB_Ouro_v4_4_Port.rocket-mon-tue.set` | Crescimento maximo aceitando grande oscilacao | Seg/Ter | 3,14 | +238.46% | 74 | 50.00% | 1.44 | 954.60 |
| `RB_Ouro_v4_4_Port.rocket-monday.set` | Nucleo mais limpo da rocket | Seg | 3,14 | +136.26% | 36 | 55.56% | 1.93 | 423.48 |
| `RB_Ouro_v4_4_Port.adaptive-week.set` | Semana viva com risco por contexto | Todos | 1,3,14,15,22 | +218.55% | 127 | 46.46% | 1.52 | 613.66 |
| `RB_Ouro_v4_4_Port.ustec-curiosity.set` | Curiosidade USTEC com o mesmo cerebro | Seg/Ter | 3,14 | 0.00% | 0 | 0.00% | 0 | 0.00 |

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
