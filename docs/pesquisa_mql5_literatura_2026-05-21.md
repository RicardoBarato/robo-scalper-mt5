# Pesquisa MQL5 e literatura - 2026-05-21

## Benchmark do ouro

Periodo comparavel ao backtest principal: 2023.05.20 a 2026.05.20.

Como 2023.05.20 foi sabado, foi usado o fechamento util anterior do XAUUSD:

- 2023.05.19 close: 1977.50
- 2026.05.20 close: 4546.63
- alta aproximada: +129.92%
- multiplicacao do preco: 2.30x

Fontes consultadas:

- Historico XAUUSD 2004-2025 via dataset publico do Hugging Face para o preco inicial.
- Investing.com XAU/USD Historical Data para 2026.05.20.

## Sinais MQL5 observados

### GoldWave signal

Caracteristicas visiveis no MQL5:

- XAUUSD como foco principal.
- Growth aproximado: 591.62%.
- Trades: 212.
- Winrate: 96.69%.
- Profit factor: 6.74.
- Trades por semana: 4.
- Tempo medio: 2 horas.
- DD de equity informado: 17.04%.
- Algo trading: 99%.

Leitura: perfil muito seletivo, baixo numero de trades semanais, perda media maior que ganho medio, mas altissimo acerto. Isso sugere filtro forte e provavel saida rapida, nao uma estrategia de capturar tendencia longa.

### Caiman System

Caracteristicas visiveis no MQL5:

- Growth aproximado: 1,861,961.61%.
- Trades: 290.
- Winrate: 90.68%.
- Profit factor: 23.87.
- Trades por semana: 5.
- Tempo medio: 11 horas.
- DD de equity informado: 29.40%.
- Trading days: 101 em 1391 dias.
- Algo trading: 0%.

Leitura: opera muito pouco em relacao ao tempo total, com grande seletividade. O DD de equity e muito maior que o DD de balance, entao a metrica critica e equity DD, nao apenas balance DD.

## Literatura e principios aplicaveis

### Time-series momentum / trend following

Moskowitz, Ooi e Pedersen documentam momentum de 1 a 12 meses em futuros de indices, moedas, commodities e bonds. A implicacao para o nosso XAUUSD e que nao basta scalpar rompimento em M1: o robo precisa reconhecer quando o ouro esta em regime direcional e permitir que parte do trade ande.

### Trend following secular

Hurst, Ooi e Pedersen estudam trend following desde 1880 e encontram retorno positivo medio em varios regimes macro. A implicacao pratica e usar filtros de tendencia de timeframe maior e nao tentar operar todos os micro-movimentos como eventos independentes.

### Volatility-managed exposure

Moreira e Muir mostram que modular exposicao por volatilidade pode melhorar a qualidade de risco. A implicacao pratica e reduzir risco quando a volatilidade/drawdown sobe e aumentar apenas em contexto validado.

### Regras tecnicas simples

Brock, Lakonishok e LeBaron encontram evidencia historica para medias moveis e trading ranges, mas isso nao significa que qualquer regra tecnica funciona. A aplicacao correta e usar regras simples como filtro de regime, nao otimizar dezenas de parametros ate encaixar no passado.

## Implicacao para o RB Ouro

O caminho mais defensavel e separar o robo em duas camadas:

- camada de regime: tendencia H4/D1, volatilidade e drawdown de equity;
- camada de entrada: rompimento M1/M15 com confirmacao MTF e filtro de extensao.

A nova `quality-mtf-trendrunner` implementa a primeira tentativa dessa ideia com H4 bias, confirmacao M15/H1, TP maior e trailing ATR. O resultado de 3 anos melhorou a relacao retorno/DD, mas o teste de 5 anos ainda mostrou fragilidade em 2022. A proxima pesquisa deve focar em filtro de regime negativo para compra em ouro.
