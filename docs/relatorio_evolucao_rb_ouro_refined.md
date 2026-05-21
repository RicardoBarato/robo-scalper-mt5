# Relatorio de evolucao - RB_Ouro_v4_4_Port

Data do ciclo: 2026-05-20  
Ativo: XAUUSD  
Timeframe: M1  
Periodo principal de teste: 2023.05.20 a 2026.05.20  
Deposito: 1000 USD  
Alavancagem: 1:500  

## Hipotese

Os relatorios manuais mostraram que o metodo do Ricardo nao e um sistema de alta frequencia constante. O ganho aparece concentrado em janelas especificas; quando o robo tenta operar todos os contextos, ele copia mais caos do que tecnica.

O foco desta rodada foi transformar esse aprendizado em filtros objetivos:

- operar apenas XAUUSD;
- priorizar compra, porque os backtests do port mostraram venda fraca;
- usar mascara de hora do servidor;
- usar mascara de dia da semana;
- manter bloqueios de seguranca: live off por padrao, cooldown apos falha de ordem, limite de perdas por dia e filtro de spread.

## Fontes externas consultadas

- CME Gold Futures fact card: horarios quase 24h no Globex e intervalo diario de manutencao, util para entender por que alguns horarios ficam ruins ou sem liquidez: https://www.cmegroup.com/content/dam/cmegroup/market-regulation/files/gold-futures-and-options-fact-card.pdf
- XS XAUUSD scalping guide: reforca que o scalping em ouro depende muito de sessao, liquidez, spread e risco: https://www.xs.com/en/blog/gold-scalping-trading-strategy/
- Pro-Scalper ATR on XAUUSD: reforca ATR como ferramenta de regime, stop e position sizing em ouro: https://www.pro-scalper.com/indicators/atr-gold-trading

## Mudancas no codigo

Arquivo principal: `MQL5/Experts/RoboScalper/RB_Ouro_v4_4_Port.mq5`

Novos controles:

- `trade_hour_mask`: permite operar somente horas especificas do servidor, por exemplo `3,14`.
- `trade_weekday_mask`: permite operar somente dias especificos, usando `1=segunda ... 5=sexta`.
- `allow_buy` e `allow_sell`: separa compra e venda sem alterar a logica principal.
- `avoid_first_minutes_of_hour`: evita primeiros minutos da hora.
- `cooldown_seconds_after_order_fail`: evita spam de ordem quando o mercado esta fechado ou a margem falha.

Preset final testado:

- `config/RB_Ouro_v4_4_Port.refined.set`
- compra apenas;
- horas `3,14`;
- dias `1,2` (segunda e terca);
- live orders desligado;
- risco expressivo: `risk_base_pct=0.030`, `risk_min_pct=0.012`, `risk_max_pct=0.048`.

## Comparativo dos testes

| Versao | Run | Retorno | Trades | Winrate | PF | DD aprox. | Leitura |
|---|---:|---:|---:|---:|---:|---:|---|
| Port limpo v4.4 | `RB_Ouro_v4_4_Port_clean_3y` | +2.67% | 2 | 100.00% | Inf | 0.00 | Positivo, mas sem amostra. |
| Balanced | `RB_Ouro_balanced_3y` | +2.76% | 160 | 41.25% | 1.05 | 106.48 | Muitos trades fracos. |
| Manual burst solto | `RoboScalper_manual_burst_3y` | -99.73% | 4063 | 28.67% | 0.40 | 997.34 | Overtrade destrutivo. |
| Mascara ampla | `RB_Ouro_hourmask_3y` | +7.28% | 172 | 41.28% | 1.11 | 183.91 | Melhor, mas ainda ruidoso. |
| Compra, 3/14/15, seg-ter-qua | `RB_Ouro_refined_mon_tue_wed_3y` | +21.62% | 99 | 46.46% | 1.46 | 81.00 | Bom equilibrio inicial. |
| Compra, 3/14, seg-ter, risco menor | `RB_Ouro_refined_mon_tue_3_14_3y` | +21.98% | 47 | 55.32% | 2.07 | 32.06 | Nucleo mais limpo. |
| Compra, 3/14, seg-ter, risco expressivo | `RB_Ouro_refined_expressive_3y` | +85.65% | 74 | 50.00% | 1.52 | 228.76 | Melhor retorno, risco maior. |

## Resultado da versao expressiva

Resumo:

- Saldo final: 1856.53 USD
- Lucro liquido: +856.53 USD
- Retorno: +85.65%
- Trades: 74
- Winrate: 50.00%
- Profit factor: 1.52
- Drawdown aproximado: 228.76 USD
- Maior sequencia de perdas: 5

Por ano:

| Ano | Trades | Winrate | PnL |
|---:|---:|---:|---:|
| 2023 | 3 | 66.67% | +79.16 |
| 2024 | 17 | 41.18% | +38.64 |
| 2025 | 45 | 53.33% | +688.53 |
| 2026 | 9 | 44.44% | +80.71 |

Por hora:

| Hora | Trades | Winrate | PnL | PF |
|---:|---:|---:|---:|---:|
| 3 | 41 | 53.66% | +489.91 | 1.52 |
| 14 | 33 | 45.45% | +397.13 | 1.52 |

Por dia:

| Dia | Trades | Winrate | PnL | PF |
|---|---:|---:|---:|---:|
| Segunda | 36 | 55.56% | +704.84 | 2.03 |
| Terca | 38 | 44.74% | +182.20 | 1.18 |

## Observacoes importantes

Este resultado e muito melhor que as versoes anteriores, mas ainda nao deve ir para conta real sem validacao forward. A amostra ficou seletiva: 74 trades em 3 anos. Isso e bom para filtrar caos, mas exige teste em demo e, idealmente, mais walk-forward.

O preset esta com `InpEnableLiveOrders=false`. Para operar real, a chave precisa ser alterada conscientemente no MT5. O primeiro uso recomendado e em demo/forward, mantendo um risco menor que o preset expressivo ate confirmar que o broker, spread e execucao batem com o testador.
