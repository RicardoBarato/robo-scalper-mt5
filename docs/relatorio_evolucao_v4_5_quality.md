# Relatorio evolucao v4.5 quality

Data: 2026-05-21

## Referencias observadas

Foram observados dois sinais publicos do MQL5:

- GoldWave signal: crescimento alto, XAUUSD como simbolo dominante, baixa frequencia, winrate muito alto, PF alto e DD de equity abaixo de 20%.
- Caiman System: crescimento extremo desde 2022, baixa frequencia real de dias operados, PF muito alto, uso multiativo e DD de equity perto de 30%.

Aprendizado extraido para o RB Ouro:

- qualidade de entrada importa mais que quantidade;
- sinais fortes operam poucos dias e poucas vezes por semana;
- a curva fica mais vendavel quando o robo aceita ficar parado;
- romper e perseguir candle esticado em XAUUSD e perigoso;
- risco alto so faz sentido depois de reduzir o caos da entrada.

## Alteracoes no EA

O `RB_Ouro_v4_4_Port.mq5` passou para versao interna 4.50, mantendo compatibilidade com presets antigos. Os novos recursos ficam desligados por padrao:

- `use_mtf_ema_confirm`: confirma compra/venda por EMAs em M5 e M15.
- `use_breakout_extension_guard`: evita entrada quando o preco ja se afastou demais do nivel rompido.
- `use_retest_entry`: permite armar entrada por reteste apos rompimento.
- `use_break_even`: protege posicoes que andaram a favor por R.
- `use_atr_trailing`: trailing opcional por ATR.
- `use_equity_risk_guard`: reduz risco quando a equity entra em drawdown relevante.

## Backtests XAUUSD M1

Periodo principal: 2023.05.20 a 2026.05.20, deposito 1000 USD, alavancagem 1:500.

| Preset | Retorno | Trades | Winrate | PF | DD % aprox. | Leitura |
|---|---:|---:|---:|---:|---:|---|
| `adaptive-week` | +218.55% | 127 | 46.46% | 1.52 | 19.82% | Melhor equilibrio anterior |
| `quality-hybrid` | +52.14% | 41 | 53.66% | 1.64 | 25.94% | Limpou, mas perdeu potencia |
| `quality-retest` | -12.24% | 70 | 44.29% | 0.90 | 45.80% | Rejeitado |
| `quality-mtf-direct` | +113.80% | 36 | 63.89% | 2.59 | 20.65% | Melhor qualidade tecnica |
| `quality-mtf-rocket` | +177.88% | 40 | 60.00% | 2.23 | 32.96% | Agressivo, ainda controlado |
| `quality-mtf-ultra` | +379.76% | 56 | 55.36% | 1.97 | 45.87% | Maior potencia |
| `quality-mtf-trendrunner` | +481.54% | 36 | 61.11% | 2.77 | 32.20% | Melhor candidato agressivo |

Teste extra de 5 anos da `quality-mtf-ultra`: 2021.05.20 a 2026.05.20.

| Retorno | Trades | Winrate | PF | DD % aprox. | Observacao |
|---:|---:|---:|---:|---:|---|
| +212.80% | 61 | 54.10% | 1.70 | 44.88% | Sobreviveu, mas 2022 foi negativo |

Teste extra de 5 anos da `quality-mtf-trendrunner`: 2021.05.20 a 2026.05.20.

| Retorno | Trades | Winrate | PF | DD % aprox. | Observacao |
|---:|---:|---:|---:|---:|---|
| +206.50% | 39 | 58.97% | 2.19 | 43.65% | Melhor PF, mas ainda sofre em 2022 |

## Conclusao

A evolucao v4.5 trouxe duas familias uteis:

- `quality-mtf-direct`: melhor candidata para produto/forward test, porque tem PF e winrate muito superiores.
- `quality-mtf-direct`: melhor candidata para produto/forward test, porque tem PF e winrate muito superiores.
- `quality-mtf-trendrunner`: melhor candidata agressiva, porque superou a `ultra` em 3 anos com PF maior e DD menor.
- `quality-mtf-ultra`: referencia de potencia bruta, mas inferior ao `trendrunner` na relacao retorno/DD.

O reteste puro foi rejeitado. A proxima evolucao deve atacar o problema de 2022 e dos piores dias de segunda-feira com um filtro de regime macro/overextension, sem bloquear segunda-feira inteira porque ela continua sendo a principal fonte de ganho.
