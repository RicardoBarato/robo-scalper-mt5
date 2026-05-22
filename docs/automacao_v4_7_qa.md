# Automacao RB Ouro v4.7 QA

Esta branch adiciona uma camada de QA/backtest para evoluir o RB Ouro sem sobrescrever o EA base.

## Objetivo

Validar uma versao v4.7 QA com correcoes estruturais antes de otimizar novos parametros:

- opcao de sinais por candle fechado (`InpUseClosedBarSignals`);
- correcao de preco real do stop quando `MinSL_points` e aplicado;
- filtro de margem antes de enviar ordem;
- filtro de `MagicNumber`, simbolo e `DEAL_ENTRY_OUT` no controle de stop diario;
- `OnDeinit` liberando handles de indicadores.

## Arquivos adicionados

- `tools/prepare_rb_ouro_v4_7_qa.py`: gera `MQL5/Experts/RoboScalper/RB_Ouro_v4_7_QA.mq5` a partir da v4.6 atual.
- `tools/run_matrix.ps1`: roda varias janelas/presets usando `tools/mt5_backtest.ps1`.
- `tools/summarize_runs.py`: le a pasta `runs/` e gera leaderboard em CSV/Markdown.
- `config/matrix/rb_ouro_v4_7_qa_matrix.csv`: matriz inicial 3 anos/5 anos, intrabar/closed-bar.
- `config/RB_Ouro_v4_7_QA.closedbar.set`: preset fechado para comparar contra o comportamento intrabar.

## Como rodar no Windows com MT5 instalado

No PowerShell, dentro da raiz do repositorio:

```powershell
python tools\prepare_rb_ouro_v4_7_qa.py
```

Depois rode a matriz:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_matrix.ps1 -PrepareV47 -TimeoutSeconds 1200
```

Se o MT5 precisar de login explicito:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_matrix.ps1 `
  -PrepareV47 `
  -TimeoutSeconds 1200 `
  -Login "SEU_LOGIN" `
  -Server "Tickmill-SEU_SERVIDOR"
```

Evite salvar senha em arquivo. Prefira deixar o terminal MT5 ja logado.

## Gerar ranking depois dos testes

```powershell
python tools\summarize_runs.py --runs runs --output docs\leaderboard_rb_ouro.md --csv docs\leaderboard_rb_ouro.csv
```

## Leitura esperada dos resultados

A comparacao principal nao e so lucro final. A ordem de avaliacao deve ser:

1. compilou sem erro;
2. gerou trades no periodo;
3. PF acima de 1.6;
4. drawdown aceitavel;
5. resultado 3 anos nao depende de uma unica fase;
6. resultado 5 anos nao destruiu a conta em 2022;
7. closed-bar nao degrada demais contra intrabar.

Se o closed-bar cair muito contra intrabar, o resultado anterior provavelmente dependia demais de informacao intrabar ou de execucao otimista. Se closed-bar continuar forte, a tese fica bem mais robusta.

## Proxima hipotese apos QA

Separar a execucao de reteste do filtro de candle explosivo. Na v4.6/v4.7, o reteste ainda passa por grande parte do mesmo funil do breakout direto. A proxima evolucao recomendada e permitir que o reteste seja validado por retomada/estrutura, nao por novo candle explosivo.
