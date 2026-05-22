# Relatorio evolucao v4.6 regime e risco

Data: 2026-05-22

## Hipotese

O `quality-mtf-trendrunner` melhorou a captura de tendencia, mas o teste de 5 anos mostrou fragilidade em 2022. A hipotese inicial era que um filtro macro D1 bloquearia compras ruins em ambiente desfavoravel.

## Mudancas no EA

O EA passou para versao interna 4.60 e recebeu filtro macro opcional:

- `use_macro_regime_filter`
- `TF_macro`
- `EMA_macro_fast`
- `EMA_macro_slow`
- `macro_use_closed_bar`
- `macro_require_fast_above_slow`
- `macro_require_price_above_fast`
- `macro_slope_bars`
- `macro_min_slope_ATR`

Os inputs ficam desligados por padrao, preservando compatibilidade com presets antigos.

## Testes

Periodo principal: XAUUSD M1, 2023.05.20 a 2026.05.20, deposito 1000 USD.

| Preset | Retorno | Trades | Winrate | PF | DD % aprox. | Leitura |
|---|---:|---:|---:|---:|---:|---|
| `trendrunner` | +481.54% | 36 | 61.11% | 2.77 | 32.20% | Base agressiva |
| `trendrunner-d1soft` | +481.54% | 36 | 61.11% | 2.77 | 32.20% | Sem efeito pratico |
| `trendrunner-d1strict` | +448.28% | 33 | 60.61% | 2.77 | 32.88% | Preserva retorno, nao melhora DD |
| `trendrunner-guarded` | +309.32% | 32 | 62.50% | 2.66 | 23.99% | Melhor controle de risco |

Teste extra de 5 anos: XAUUSD M1, 2021.05.20 a 2026.05.20, deposito 1000 USD.

| Preset | Retorno | Trades | Winrate | PF | DD % aprox. | PnL 2022 | Leitura |
|---|---:|---:|---:|---:|---:|---:|---|
| `trendrunner` | +206.50% | 39 | 58.97% | 2.19 | 43.65% | -363.77 | Agressivo, sofre cedo |
| `trendrunner-d1soft` | +206.50% | 39 | 58.97% | 2.19 | 43.65% | -363.77 | Filtro inutil |
| `trendrunner-d1strict` | +207.16% | 38 | 57.89% | 2.23 | 44.64% | -363.77 | Nao resolve 2022 |
| `trendrunner-guarded` | +137.11% | 32 | 56.25% | 2.12 | 25.53% | -233.71 | Reduz DD, corta retorno |

## Conclusao

EMA diaria simples nao identifica o problema de 2022. Os trades ruins ainda ocorrem quando o filtro D1 considera o ambiente aceitavel.

O problema mais claro e risco alto antes de existir lucro acumulado. O `trendrunner-guarded` reduz o DD de 5 anos de 43.65% para 25.53%, mas tambem reduz o retorno de 3 anos de +481.54% para +309.32%.

## Proxima etapa

Testar um modelo progressivo de risco:

- risco moderado ate a curva criar margem de lucro;
- risco cheio quando equity estiver acima de um patamar;
- reducao gradual em drawdown, nao corte unico;
- manter `trendrunner` como perfil agressivo e `guarded` como referencia controlada.
