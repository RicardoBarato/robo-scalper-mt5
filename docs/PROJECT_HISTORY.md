# Project History

## 1. Origin

The project started as a MetaTrader 5 automation experiment for turning discretionary short-term trading observations into objective Expert Advisor rules.

This is inferred from the initial repository files and early commits that added MQL5 source code, MT5 automation scripts and report-analysis tooling.

## 2. Motivation

The motivation was to study trading automation, risk control, backtesting and systematic validation. The work moved from manual performance review into a repeatable engineering loop: code, compile, backtest, parse results and document findings.

## 3. Technical evolution

The repository evolved through several internal iterations:

- initial EA scaffold;
- automated MT5 compile and backtest scripts;
- report parsing tools;
- risk controls;
- session filters;
- multi-timeframe and regime-oriented research;
- robustness and capital-efficiency tooling.

The public repository keeps the engineering workflow and a safe educational EA scaffold. It excludes production strategy details.

## 4. Relevant versions

Version labels from the internal research phase include v4.4, v4.5 and v4.6 research iterations.

The first official public release is documented as `v1.0-public`. Earlier `v4.x` labels are treated as internal research and hardening context, not public performance claims.

## 5. Risk-management evolution

The project moved toward explicit risk controls:

- live-order disabled-by-default safety;
- symbol guard;
- stop-loss requirement;
- risk-based position sizing;
- spread checks;
- session controls;
- drawdown-aware research in private artifacts.

## 6. Filter evolution

The historical work indicates a shift from high-frequency short-term ideas toward lower-frequency, regime-aware validation.

Public documentation describes this only at a high level. Proprietary filters and optimized parameters are intentionally not published.

## 7. Regime and robustness evolution

The project history shows growing attention to:

- market regime;
- volatility;
- multi-timeframe confirmation;
- concentration of returns;
- stress testing;
- robustness under costs.

The public release keeps the vocabulary and workflow but removes private research outputs.

## 8. Backtest workflow evolution

Automation tools were added to:

- compile MQL5 code with MetaEditor;
- launch MT5 Strategy Tester runs;
- collect logs into `runs/`;
- parse tester output;
- generate robustness and capital-efficiency reports.

Generated outputs are ignored by Git in the public release.

## 9. Current structure

The current public structure contains:

- `MQL5/Experts/RBRiskEngine/RBRiskEngine_Public.mq5`: educational EA scaffold;
- `tools/`: compile, backtest and analysis scripts;
- `examples/`: fictitious settings and parameter notes;
- `docs/`: public architecture, roadmap, release and safety documentation.

## 10. Removed from the public version

The public tracked tree removes or ignores:

- real `.set` presets;
- real backtest reports;
- real broker exports;
- real optimization artifacts;
- local MT5 paths;
- broker-specific configuration;
- private strategy source files;
- performance tables that could reveal private research.

## 11. Private repository scope

The private next version should contain:

- real data;
- real reports;
- real presets;
- optimization studies;
- proprietary filters;
- production parameters;
- walk-forward results;
- Monte Carlo results;
- broker-execution notes;
- private execution logs.

## 12. Next phase

The recommended next phase is a separate private repository for v5 research, while this repository stays as a public, professional and educational portfolio artifact.
