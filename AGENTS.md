# Projeto Robo Scalper MT5

Este arquivo da contexto operacional para agentes/assistentes que trabalharem neste repositorio.

## Objetivo Atual

Construir e validar Expert Advisors MQL5 para XAUUSD, com postura de engenharia quant:

- formular hipoteses testaveis;
- medir contra benchmark claro;
- evitar overfitting;
- priorizar retorno ajustado a drawdown;
- documentar decisoes, resultados e presets;
- manter compatibilidade com Strategy Tester do MT5.

O projeto comecou como scalper, mas os melhores resultados atuais vieram de menor frequencia e captura de tendencia/volatilidade. Portanto, nao assumir que "mais trades" e melhor.

## Ambiente

- Plataforma: MetaTrader 5 / MQL5.
- Corretora/testes locais: Tickmill MT5.
- Principal ativo: XAUUSD.
- Timeframe de execucao: M1.
- Timeframes auxiliares: M5, M15, H1 e H4.
- Scripts de automacao ficam em `tools/`.
- Presets ficam em `config/`.
- Relatorios ficam em `docs/`.

## Melhor Estado Conhecido

Benchmark do ouro no periodo 2023.05.20 a 2026.05.20:

- XAUUSD aproximado: 1977.50 para 4546.63.
- Buy-and-hold aproximado: +129.92%.

Principais presets testados:

- `RB_Ouro_v4_4_Port.adaptive-week.set`: +218.55%, PF 1.52, DD aprox. 19.82%, 127 trades.
- `RB_Ouro_v4_4_Port.quality-mtf-direct.set`: +113.80%, PF 2.59, DD aprox. 20.65%, 36 trades.
- `RB_Ouro_v4_4_Port.quality-mtf-ultra.set`: +379.76%, PF 1.97, DD aprox. 45.87%, 56 trades.
- `RB_Ouro_v4_4_Port.quality-mtf-trendrunner.set`: +481.54%, PF 2.77, DD aprox. 32.20%, 36 trades.
- `RB_Ouro_v4_4_Port.quality-mtf-trendrunner-guarded.set`: +309.32%, PF 2.66, DD aprox. 23.99%, 32 trades.

Leitura atual:

- `quality-mtf-direct` e a melhor candidata para forward/produto conservador.
- `quality-mtf-trendrunner` e a melhor candidata agressiva.
- `quality-mtf-trendrunner-guarded` e a melhor candidata de risco controlado.
- `quality-mtf-ultra` fica como referencia de potencia bruta, mas perdeu para o `trendrunner` em retorno/DD no teste de 3 anos.

## Direcao Quant

Nao tratar o robo como scalper puro. A evidencia atual favorece:

- baixa frequencia;
- filtro de regime;
- confirmacao multi-timeframe;
- entradas em rompimento/momentum com controle de extensao;
- TP maior e trailing ATR quando o ouro esta em regime direcional;
- risco dinamico por contexto, volatilidade e drawdown de equity.

Evitar:

- martingale;
- grid agressivo;
- aumentar risco apos perda;
- otimizar dezenas de parametros sem tese;
- conclusoes baseadas apenas em lucro final.

## Proxima Hipotese Prioritaria

O `quality-mtf-trendrunner` melhorou muito em 3 anos, mas o teste de 5 anos ainda mostrou fragilidade em 2022. O filtro D1 por EMA foi testado e nao resolveu. O corte mais rapido de risco por equity reduziu DD, mas cortou retorno.

Proxima evolucao recomendada:

1. Criar risco progressivo por equity/regime, em vez de corte binario.
2. Medir se reduz 2022 sem destruir 2025.
3. Comparar 3 anos e 5 anos.
4. Avaliar retorno, PF, DD percentual, max loss streak, trades/ano e dependencia de poucos dias.

## Regras de Risco

- Todo trade precisa ter stop loss definido.
- Nunca abrir operacao sem SL.
- O lote deve ser calculado por risco percentual do equity/balance.
- Deve existir limite de perda diaria.
- Deve existir pausa apos sequencia de stops.
- Nao conectar em conta real sem confirmacao explicita.
- Considerar tudo estudo/backtest ate autorizacao explicita para live.

## Workflow Esperado

1. Ler o codigo e os presets existentes.
2. Formular a hipotese antes de alterar.
3. Implementar mudanca pequena e mensuravel.
4. Compilar no MetaEditor/MT5.
5. Rodar backtest 3 anos e, quando promissor, 5 anos.
6. Atualizar `docs/presets_rb_ouro.md` e relatorios relevantes.
7. Commitar e subir para GitHub quando a rodada tiver resultado util.
