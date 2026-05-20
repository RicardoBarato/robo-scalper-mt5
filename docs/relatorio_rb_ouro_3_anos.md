# Relatorio RB_Ouro 3 anos

Data do teste: 2026-05-20  
Periodo: 2023-05-20 a 2026-05-20  
Ativo/timeframe: XAUUSD, M1  
Deposito: 1000 USD  
Alavancagem: 1:500  
Modelo: every tick

## Resultado das duas versoes originais

| EA | Saldo final | Retorno | Trades | Wins | Losses | Winrate | PF | DD aprox. |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| RB_Ouro_v4_3 | 1026.66 | +2.67% | 2 | 2 | 0 | 100.00% | infinito | 0.00 |
| RB_Ouro_v4_4 | 1026.66 | +2.67% | 2 | 2 | 0 | 100.00% | infinito | 0.00 |

Rodadas:
- `runs/20260520-200609-RB_Ouro_v4_3_3y`
- `runs/20260520-200810-RB_Ouro_v4_4_3y`

## Leitura

As duas versoes foram positivas, mas a amostra foi muito pequena: apenas 2 trades em 3 anos. Isso mostra que o valor principal dessas versoes nao e frequencia; e filtro. Elas cortam quase todo o mercado e deixam passar somente rompimentos muito especificos:

- sessoes 8-11 e 13-16;
- risco por percentual da conta, com lote dinamico;
- limite de 6 trades/dia;
- filtro H1 por EMA 50/200;
- estrutura M15;
- ADX M1 e ADX M15;
- ciclo M5 de squeeze/contracao para expansao;
- gatilho de expansao por ATR/range;
- alvo em 2R, sem runner/trailing.

## Assimilacao no projeto

Criei um port limpo em:

- `MQL5/Experts/RoboScalper/RB_Ouro_v4_4_Port.mq5`

Mudancas no port:

- adiciona trava de simbolo `InpAllowedSymbol`;
- mantem ordens reais desligadas por padrao com `InpEnableLiveOrders=false`;
- permite backtest com `InpEnableTesterOrders=true`;
- adiciona `InpMagicNumber`;
- renomeia `mode` para `InpMode`, removendo warnings de compilacao.

Backtest do port atual:

| EA | Saldo final | Retorno | Trades | Wins | Losses | Winrate | PF | DD aprox. |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| RB_Ouro_v4_4_Port | 1026.66 | +2.67% | 2 | 2 | 0 | 100.00% | infinito | 0.00 |

Rodada do port limpo:

- `runs/20260520-202526-RB_Ouro_v4_4_Port_clean_3y`

## Comparativo com RoboScalper

Tambem apliquei parte do aprendizado no RoboScalper principal:

- lote por risco percentual (`InpUseRiskSizing`, `InpRiskPerTradePct`);
- sessoes 8-11 e 13-16;
- maximo de 6 trades por sessao;
- spread maximo 35 pontos;
- cooldown de 15 minutos apos perda;
- H1 ligado com 50/200;
- confluencia M5/M15/H1 exigindo 3 alinhamentos;
- range minimo de 2.2 ATR.

Resultado do RoboScalper principal apos esses filtros:

| EA | Saldo final | Retorno | Trades | Winrate | PF | DD aprox. |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| RoboScalper seletivo | 819.95 | -18.00% | 433 | 30.72% | 0.89 | 236.91 |

Rodada:

- `runs/20260520-201910-RoboScalper_selective_3y`

Conclusao: a gestao e os filtros reduziram muito o estrago, mas o motor de entrada atual ainda nao tem edge. A base mais promissora agora e evoluir o `RB_Ouro_v4_4_Port` para aumentar frequencia com controle, em vez de tentar forcar o RoboScalper original a operar mais.
