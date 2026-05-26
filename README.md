# rb-risk-engine-mt5

![MQL5](https://img.shields.io/badge/MQL5-Expert%20Advisor-blue)
![MetaTrader 5](https://img.shields.io/badge/MetaTrader%205-supported-informational)
![Educational](https://img.shields.io/badge/status-educational-lightgrey)
![Risk Management](https://img.shields.io/badge/focus-risk%20management-success)

Educational MetaTrader 5 / MQL5 risk-engine framework focused on systematic trading research, risk controls, backtesting workflow and public/private project hygiene.

This public repository is a sanitized educational release. It is not a profit promise, trading recommendation, signal service, investment product, or production trading system.

## Status

Public educational release: `v1.0-public`.

This is the first official public release of RB Risk Engine MT5.

The project started as a short-term trading automation experiment and evolved into a risk-managed Expert Advisor research framework. The public version keeps the architecture, tooling and documentation useful for portfolio review, while private strategy logic, real presets and real reports are intentionally excluded.

## Why this project matters

This project is not about promising returns. It demonstrates how a discretionary trading idea can be translated into a controlled engineering workflow:

- define objective rules;
- protect capital with explicit risk controls;
- automate compile and backtest loops;
- document assumptions and limitations;
- separate public educational code from private research;
- avoid publishing sensitive broker, account or strategy artifacts.

## Portfolio Value

This repository demonstrates practical experience with MQL5 development, Expert Advisor structure, systematic trading research, risk management, automated backtesting workflow, repository organization, documentation and security hygiene.

It also shows an important engineering decision: the public repository exposes a safe framework, not the private edge, real parameters, broker exports or optimization history.

## Skills demonstrated

- MQL5 / MetaTrader 5 development;
- Expert Advisor architecture;
- systematic trading research;
- risk management;
- backtesting workflow;
- code organization;
- documentation;
- security hygiene;
- public/private project separation.

## Technologies

- MetaTrader 5;
- MQL5;
- PowerShell automation;
- Python report parsing;
- Strategy Tester workflow;
- Git and GitHub.

## Repository structure

```text
.
|-- MQL5/
|   `-- Experts/
|       `-- RBRiskEngine/
|           `-- RBRiskEngine_Public.mq5
|-- config/
|   `-- mt5.local.example.ps1
|-- docs/
|   |-- ARCHITECTURE.md
|   |-- PRIVATE_NEXT_VERSION_PLAN.md
|   |-- PROJECT_HISTORY.md
|   |-- PUBLIC_RELEASE_NOTES.md
|   |-- ROADMAP.md
|   `-- SAFETY_AND_RISK_NOTICE.md
|-- examples/
|   |-- README.md
|   |-- RBRiskEngine_Public.example.set
|   `-- example-parameters.md
|-- tools/
|   |-- mt5_backtest.ps1
|   |-- mt5_compile.ps1
|   |-- mt5_common.ps1
|   |-- mt5_parse_run.ps1
|   |-- mt5_robustness.py
|   `-- analyze_mt5_reports.py
|-- CHANGELOG.md
|-- SECURITY.md
|-- SECURITY_AUDIT_REPORT.md
`-- README.md
```

## Install

1. Install MetaTrader 5.
2. Clone this repository.
3. Copy the local MT5 configuration example:

```powershell
Copy-Item config\mt5.local.example.ps1 config\mt5.local.ps1
```

4. Edit `config\mt5.local.ps1` with your local MT5 install path and data directory.

The local file is ignored by Git.

## Compile

```powershell
powershell -ExecutionPolicy Bypass -File tools\mt5_compile.ps1
```

The script copies `MQL5\Experts\RBRiskEngine\RBRiskEngine_Public.mq5` into the MT5 data directory and calls `MetaEditor64.exe`.

## Run in demo or Strategy Tester

Use demo mode first. The public EA has live orders disabled by default:

```text
InpEnableLiveOrders=false
InpEnableTesterOrders=true
```

Run a basic backtest:

```powershell
powershell -ExecutionPolicy Bypass -File tools\mt5_backtest.ps1 -CompileFirst
```

Use the fictitious example preset:

```powershell
powershell -ExecutionPolicy Bypass -File tools\mt5_backtest.ps1 `
  -SetPath examples\RBRiskEngine_Public.example.set `
  -ExpertParameters RBRiskEngine_Public.example.set `
  -CompileFirst
```

Backtest artifacts are written to `runs/`, which is intentionally ignored by Git.

## Example configuration

Public examples are in `examples/`.

They are fictitious and should not be treated as optimized settings. Real presets, broker data, account reports and production settings should stay private.

## Logs and reports

The tools can collect tester logs and summarize backtest output. Generated reports belong in ignored folders such as `runs/`, `reports/` or `backtests/` unless they are fully synthetic and intentionally safe for public release.

## What is not included

The public version does not include:

- private strategy logic;
- real presets;
- real broker exports;
- real account reports;
- optimization grids;
- production parameters;
- sensitive backtest results;
- account numbers, server names, credentials or local machine paths.

## Known limitations

- The public EA is an educational scaffold, not a finished strategy.
- Backtests can overestimate future performance.
- Spread, slippage, latency and broker execution can materially change results.
- CFDs and leveraged products can cause rapid losses.
- A security audit and public-history cleanup were completed before the official public release; see `SECURITY_AUDIT_REPORT.md`.

## Roadmap

Public roadmap:

- keep documentation clean and educational;
- improve examples with synthetic data only;
- keep the public EA safe and readable;
- maintain strong `.gitignore` coverage.

Private roadmap:

- continue strategy research in a private repository;
- keep real reports, presets and broker data outside public Git;
- run walk-forward, Monte Carlo and robustness checks;
- document risk-adjusted results privately.

## Security

See `SECURITY.md` and `SECURITY_AUDIT_REPORT.md`.

Do not commit credentials, `.set` production files, broker exports, real reports, account identifiers or logs.

## Responsibility

This repository is for software engineering and educational research. It is not financial advice. Trading involves risk, and past performance does not guarantee future results.
