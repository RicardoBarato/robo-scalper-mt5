# Relatorio - Backtest 5 anos

Data do teste: 2026-05-20

## Configuracao

- Robo: `RoboScalper.mq5`
- Preset: `config/RoboScalper.set`
- Ativo: `XAUUSD`
- Timeframe: `M1`
- Periodo: 2021-05-20 ate 2026-05-20
- Deposito inicial: 1000 USD
- Lote: 0.10 fixo
- Direcao: compra apenas
- Stop: 500 pontos
- Alvo: 2400 pontos
- Confluencia MTF: ativa, M5/M15/H1 frouxa
- Trava apos perda rapida: ativa, 120 segundos
- Live orders: desligado
- Rodada: `runs/20260520-123737`

## Resultado geral

| Metrica | Valor |
| --- | ---: |
| Saldo final | 10.24 USD |
| Resultado liquido | -989.76 USD |
| Retorno sobre deposito | -98.98% |
| Trades executados | 74 |
| Vencedores | 10 |
| Perdedores | 64 |
| Winrate | 13.51% |
| Profit factor | 0.70 |
| Lucro bruto | 2341.41 USD |
| Perda bruta | -3331.17 USD |
| Media ganho | 234.14 USD |
| Media perda | -52.05 USD |
| Expectativa por trade | -13.38 USD |
| Maior drawdown fechado | 1129.00 USD |
| Maior drawdown fechado percentual | 99.10% |
| Maior sequencia vencedora | 2 |
| Maior sequencia perdedora | 18 |
| Dias com trades | 69 |
| Dias positivos | 10 |
| Dias negativos | 59 |
| Media de trades por dia operado | 1.07 |
| Duracao media por trade | 69758 s |
| Duracao mediana por trade | 40923 s |

## Observacao importante

O backtest cobriu 5 anos, mas a conta perdeu quase todo o capital ainda em 2021. Apos o saldo cair para 10.24 USD, o robo continuou encontrando sinais ate 2026, mas nao conseguiu enviar ordens por falta de margem.

Resumo dos sinais:

| Item | Quantidade |
| --- | ---: |
| Sinais tecnicos detectados | 11042 |
| Ordens enviadas | 74 |
| Ordens recusadas por falta de margem | 10968 |

Primeiro fechamento registrado:

- 2021-05-20 04:14:20, PnL -50.20 USD

Ultimo fechamento executado:

- 2021-09-30 13:40:40, PnL -50.10 USD

Depois disso, o saldo era insuficiente para abrir `0.10` lote em XAUUSD.

## Resultado por ano

| Ano | Resultado | Trades | Winrate | PF |
| --- | ---: | ---: | ---: | ---: |
| 2021 | -989.76 USD | 74 | 13.51% | 0.70 |
| 2022 | 0.00 USD | 0 | n/a | n/a |
| 2023 | 0.00 USD | 0 | n/a | n/a |
| 2024 | 0.00 USD | 0 | n/a | n/a |
| 2025 | 0.00 USD | 0 | n/a | n/a |
| 2026 | 0.00 USD | 0 | n/a | n/a |

## Resultado por horario de entrada

| Hora | Resultado | Trades | Winrate |
| --- | ---: | ---: | ---: |
| 03h | -690.21 USD | 41 | 12.20% |
| 04h | -197.46 USD | 20 | 15.00% |
| 05h | -269.33 USD | 5 | 0.00% |
| 06h | 167.24 USD | 8 | 25.00% |

## Melhor e pior periodo

- Melhor dia: 2021-08-11, +240.60 USD, 1 trade.
- Pior dia: 2021-07-16, -100.50 USD, 2 trades.
- Melhor mes: 2021-07, +152.24 USD, 13 trades.
- Pior mes: 2021-09, -737.21 USD, 20 trades.

## Leitura tecnica

Este teste mostra que a versao atual ainda nao esta robusta para 5 anos. A logica recente ficou boa nos recortes de 2025/2026, mas o periodo de 2021 destruiu a conta antes que o restante do historico pudesse ser operado.

O principal problema operacional e o lote fixo de 0.10. Com deposito de 1000 USD, uma sequencia longa ruim tira a conta do jogo e depois o MT5 recusa novas entradas por falta de margem.

## Proximas correcoes recomendadas

1. Trocar lote fixo por risco percentual ou lote dinamico por saldo.
2. Adicionar bloqueio de seguranca quando o saldo estiver abaixo da margem minima.
3. Validar a estrategia por ano, nao apenas em blocos bons recentes.
4. Criar modo de teste com reinicio anual de banca para medir o edge do sinal sem a quebra de conta contaminar os anos seguintes.
5. Reavaliar filtro de regime antigo: 2021 teve comportamento claramente hostil para o preset atual.
