//+------------------------------------------------------------------+
//|                                                  RoboScalper.mq5 |
//| Base inicial para filtrar tecnica e bloquear caos.               |
//+------------------------------------------------------------------+
#property copyright "Ricardo Barato"
#property version   "1.000"
#property strict

#include <Trade/Trade.mqh>

enum RobotState
{
   STATE_IDLE = 0,
   STATE_TECHNIQUE_READY = 1,
   STATE_IN_POSITION = 2,
   STATE_COOLDOWN = 3,
   STATE_LOCKED = 4
};

enum H1FilterMode
{
   H1_FILTER_STRICT_TREND = 0,
   H1_FILTER_BLOCK_OPPOSITE = 1
};

input string InpAllowedSymbol = "XAUUSD";
input bool   InpEnableLiveOrders = false;
input bool   InpEnableTesterOrders = true;
input int    InpMagicNumber = 55749699;

input double InpFixedLot = 0.10;
input bool   InpUseRiskSizing = true;
input double InpRiskPerTradePct = 0.007;
input double InpMaxLot = 0.50;
input int    InpMaxSpreadPoints = 35;
input int    InpStopLossPoints = 500;
input int    InpTakeProfitPoints = 1000;

input int    InpSessionStartHour = 8;
input int    InpSessionEndHour = 11;
input bool   InpUseSecondSession = true;
input int    InpSession2StartHour = 13;
input int    InpSession2EndHour = 16;
input int    InpMaxTradesPerSession = 6;
input int    InpMaxConsecutiveLosses = 3;
input int    InpCooldownSecondsAfterLoss = 900;
input int    InpCooldownSecondsAfterLossStreak = 900;
input bool   InpLockSessionAfterFastLoss = true;
input int    InpFastLossSeconds = 120;
input int    InpMaxPositionSeconds = 0;

input double InpMaxSessionLossMoney = 200.0;
input double InpMaxDailyLossMoney = 300.0;
input double InpSessionProfitLockMoney = 500.0;
input double InpMaxGivebackFromPeakMoney = 150.0;

input bool   InpAllowBuy = true;
input bool   InpAllowSell = false;
input int    InpAtrPeriod = 14;
input int    InpBreakoutLookback = 14;
input int    InpFastTrendPeriod = 5;
input int    InpSlowTrendPeriod = 20;
input bool   InpUseMtfConfluence = true;
input int    InpMtfFastTrendPeriod = 3;
input int    InpMtfSlowTrendPeriod = 12;
input int    InpMtfMinAligned = 3;
input bool   InpUseH1TrendFilter = true;
input H1FilterMode InpH1FilterMode = H1_FILTER_BLOCK_OPPOSITE;
input int    InpH1FastTrendPeriod = 50;
input int    InpH1SlowTrendPeriod = 200;
input bool   InpUseBreakoutRetest = false;
input int    InpRetestMaxBars = 5;
input int    InpRetestTolerancePoints = 150;
input bool   InpRequireRetestCandleDirection = true;
input bool   InpUseM1WSignal = false;
input int    InpWLookbackBars = 12;
input int    InpWTolerancePoints = 180;
input double InpWMinNecklineAtr = 0.40;
input double InpMinBodyAtr = 0.45;
input double InpMinRangeAtr = 2.20;
input double InpCloseNearExtreme = 0.70;
input int    InpMinSecondsBetweenEntries = 20;

CTrade trade;

RobotState g_state = STATE_IDLE;
datetime   g_session_day = 0;
datetime   g_cooldown_until = 0;
double     g_session_start_equity = 0.0;
double     g_session_peak_equity = 0.0;
double     g_day_start_equity = 0.0;
int        g_trades_this_session = 0;
int        g_consecutive_losses = 0;
datetime   g_last_signal_bar_time = 0;
datetime   g_last_entry_time = 0;
int        g_pending_retest_direction = 0;
double     g_pending_retest_level = 0.0;
datetime   g_pending_retest_expires = 0;
datetime   g_pending_retest_source_bar = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagicNumber);
   ResetSession();
   Print("RoboScalper iniciado em modo seguro. Live orders: ", InpEnableLiveOrders);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(_Symbol != InpAllowedSymbol)
   {
      g_state = STATE_IDLE;
      return;
   }

   RollSessionIfNeeded();
   ManageOpenPositions();

   if(IsLockedByRisk())
   {
      g_state = STATE_LOCKED;
      return;
   }

   if(TimeCurrent() < g_cooldown_until)
   {
      g_state = STATE_COOLDOWN;
      return;
   }

   if(HasOpenPosition())
   {
      g_state = STATE_IN_POSITION;
      return;
   }

   if(!IsTradingWindow() || !IsSpreadOk())
   {
      g_state = STATE_IDLE;
      return;
   }

   int direction = 0;
   if(!BuildTechniqueSignal(direction))
   {
      g_state = STATE_TECHNIQUE_READY;
      return;
   }

   TryOpen(direction);
}

//+------------------------------------------------------------------+
void ResetSession()
{
   g_session_day = StartOfDay(TimeCurrent());
   g_session_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_session_peak_equity = g_session_start_equity;
   g_day_start_equity = g_session_start_equity;
   g_trades_this_session = 0;
   g_consecutive_losses = 0;
   g_cooldown_until = 0;
   g_last_signal_bar_time = 0;
   g_last_entry_time = 0;
   ClearPendingRetest();
   g_state = STATE_IDLE;
}

//+------------------------------------------------------------------+
void RollSessionIfNeeded()
{
   datetime today = StartOfDay(TimeCurrent());
   if(today != g_session_day)
      ResetSession();

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > g_session_peak_equity)
      g_session_peak_equity = equity;
}

//+------------------------------------------------------------------+
datetime StartOfDay(datetime value)
{
   MqlDateTime dt;
   TimeToStruct(value, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
bool IsTradingWindow()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(IsWithinHourWindow(dt.hour, InpSessionStartHour, InpSessionEndHour))
      return true;

   return InpUseSecondSession &&
      IsWithinHourWindow(dt.hour, InpSession2StartHour, InpSession2EndHour);
}

//+------------------------------------------------------------------+
bool IsWithinHourWindow(int hour, int start_hour, int end_hour)
{
   if(start_hour <= end_hour)
      return hour >= start_hour && hour <= end_hour;

   return hour >= start_hour || hour <= end_hour;
}

//+------------------------------------------------------------------+
bool IsSpreadOk()
{
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   return spread > 0 && spread <= InpMaxSpreadPoints;
}

//+------------------------------------------------------------------+
bool IsLockedByRisk()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double session_pnl = equity - g_session_start_equity;
   double daily_pnl = equity - g_day_start_equity;
   double giveback = g_session_peak_equity - equity;

   if(g_trades_this_session >= InpMaxTradesPerSession)
      return true;

   if(session_pnl <= -InpMaxSessionLossMoney)
      return true;

   if(daily_pnl <= -InpMaxDailyLossMoney)
      return true;

   if(g_session_peak_equity - g_session_start_equity >= InpSessionProfitLockMoney &&
      giveback >= InpMaxGivebackFromPeakMoney)
      return true;

   return false;
}

//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   if(InpMaxPositionSeconds <= 0)
      return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;

      datetime opened_at = (datetime)PositionGetInteger(POSITION_TIME);
      if(TimeCurrent() - opened_at > InpMaxPositionSeconds)
      {
         Print("Fechando posicao por tempo maximo de scalp. Ticket: ", ticket);
         if(CanSendOrders())
         {
            bool closed = trade.PositionClose(ticket);
            Print("Fechamento por tempo enviado: ", closed,
                  " retcode: ", trade.ResultRetcode(),
                  " ", trade.ResultRetcodeDescription());
         }
      }
   }
}

//+------------------------------------------------------------------+
bool BuildTechniqueSignal(int &direction)
{
   direction = 0;

   if(TimeCurrent() - g_last_entry_time < InpMinSecondsBetweenEntries)
      return false;

   int needed_bars = MathMax(InpSlowTrendPeriod, InpBreakoutLookback) + InpAtrPeriod + 5;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   int copied = CopyRates(_Symbol, PERIOD_M1, 0, needed_bars, rates);
   if(copied < needed_bars)
      return false;

   MqlRates signal_bar = rates[1];
   if(signal_bar.time == g_last_signal_bar_time)
      return false;

   if(InpUseBreakoutRetest && TryConfirmPendingRetest(rates, copied, direction))
   {
      if(!PassHigherTimeframeFilter(direction))
         return false;

      if(!PassMtfConfluence(direction))
         return false;

      g_last_signal_bar_time = signal_bar.time;
      ClearPendingRetest();
      return true;
   }

   double atr = CalculateAtr(rates, copied, InpAtrPeriod);
   if(atr <= 0.0)
      return false;

   double fast_trend = AverageClose(rates, copied, 1, InpFastTrendPeriod);
   double slow_trend = AverageClose(rates, copied, 1, InpSlowTrendPeriod);
   if(fast_trend <= 0.0 || slow_trend <= 0.0)
      return false;

   double body = MathAbs(signal_bar.close - signal_bar.open);
   double range = signal_bar.high - signal_bar.low;
   if(range <= 0.0)
      return false;

   if(body < atr * InpMinBodyAtr)
      return false;

   if(range < atr * InpMinRangeAtr)
      return false;

   double highest = HighestHigh(rates, copied, 2, InpBreakoutLookback);
   double lowest = LowestLow(rates, copied, 2, InpBreakoutLookback);
   if(highest <= 0.0 || lowest <= 0.0)
      return false;

   double close_position = (signal_bar.close - signal_bar.low) / range;
   bool buy_signal =
      InpAllowBuy &&
      signal_bar.close > signal_bar.open &&
      signal_bar.close > highest &&
      close_position >= InpCloseNearExtreme &&
      fast_trend > slow_trend &&
      signal_bar.close > slow_trend;

   bool sell_signal =
      InpAllowSell &&
      signal_bar.close < signal_bar.open &&
      signal_bar.close < lowest &&
      close_position <= (1.0 - InpCloseNearExtreme) &&
      fast_trend < slow_trend &&
      signal_bar.close < slow_trend;

   bool w_signal = false;
   int w_direction = 0;
   if(InpUseM1WSignal)
      w_signal = DetectM1WSignal(rates, copied, atr, w_direction);

   if(buy_signal)
      direction = 1;
   else if(sell_signal)
      direction = -1;
   else if(w_signal)
      direction = w_direction;
   else
      return false;

   if(!PassHigherTimeframeFilter(direction))
      return false;

   if(!PassMtfConfluence(direction))
      return false;

   if(InpUseBreakoutRetest && (buy_signal || sell_signal))
   {
      double breakout_level = direction > 0 ? highest : lowest;
      RegisterPendingRetest(direction, breakout_level, signal_bar.time);
      g_last_signal_bar_time = signal_bar.time;
      return false;
   }

   g_last_signal_bar_time = signal_bar.time;
   return true;
}

//+------------------------------------------------------------------+
void TryOpen(int direction)
{
   if(direction == 0)
      return;

   double lot = InpUseRiskSizing ?
      CalculateRiskLot(InpStopLossPoints) :
      NormalizeLot(MathMin(InpFixedLot, InpMaxLot));

   if(lot <= 0.0)
      return;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double sl = 0.0;
   double tp = 0.0;

   if(direction > 0)
   {
      sl = NormalizeDouble(tick.ask - InpStopLossPoints * point, digits);
      tp = NormalizeDouble(tick.ask + InpTakeProfitPoints * point, digits);
   }
   else
   {
      sl = NormalizeDouble(tick.bid + InpStopLossPoints * point, digits);
      tp = NormalizeDouble(tick.bid - InpTakeProfitPoints * point, digits);
   }

   bool can_send_orders = CanSendOrders();

   bool sent = false;
   if(can_send_orders)
   {
      if(direction > 0)
         sent = trade.Buy(lot, _Symbol, 0.0, sl, tp, "RS momentum buy");
      else
         sent = trade.Sell(lot, _Symbol, 0.0, sl, tp, "RS momentum sell");
   }

   if(sent)
   {
      g_trades_this_session++;
      g_last_entry_time = TimeCurrent();
   }

   Print("Sinal tecnico: ", direction,
         " lote: ", lot,
         " SL: ", sl,
         " TP: ", tp,
         " envio habilitado: ", can_send_orders,
         " enviado: ", sent,
         " retcode: ", trade.ResultRetcode(),
         " ", trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
void OnTradeTransaction(
   const MqlTradeTransaction &trans,
   const MqlTradeRequest &request,
   const MqlTradeResult &result
)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;

   ulong deal = trans.deal;
   if(!HistoryDealSelect(deal))
      return;

   if(HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol)
      return;

   if((int)HistoryDealGetInteger(deal, DEAL_MAGIC) != InpMagicNumber)
      return;

   if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_OUT)
      return;

   double pnl = HistoryDealGetDouble(deal, DEAL_PROFIT) +
                HistoryDealGetDouble(deal, DEAL_COMMISSION) +
                HistoryDealGetDouble(deal, DEAL_SWAP);

   if(pnl < 0)
   {
      int trade_duration_seconds = ClosedDealDurationSeconds(deal);
      bool locked_after_fast_loss = false;

      if(InpLockSessionAfterFastLoss &&
         InpFastLossSeconds > 0 &&
         trade_duration_seconds >= 0 &&
         trade_duration_seconds <= InpFastLossSeconds)
      {
         datetime next_day = StartOfDay(TimeCurrent()) + 86400;
         if(next_day > g_cooldown_until)
            g_cooldown_until = next_day;

         Print("Perda rapida detectada (", trade_duration_seconds,
               "s). Sessao bloqueada ate: ", g_cooldown_until);
         g_consecutive_losses = 0;
         locked_after_fast_loss = true;
      }

      if(!locked_after_fast_loss)
      {
         g_consecutive_losses++;
         if(g_consecutive_losses >= InpMaxConsecutiveLosses)
         {
            g_cooldown_until = TimeCurrent() + InpCooldownSecondsAfterLossStreak;
            Print("Sequencia de perdas atingida. Cooldown longo ate: ", g_cooldown_until);
            g_consecutive_losses = 0;
         }
         else
         {
            g_cooldown_until = TimeCurrent() + InpCooldownSecondsAfterLoss;
         }
      }
   }
   else if(pnl > 0)
   {
      g_consecutive_losses = 0;
   }

   Print("Fechamento registrado. PnL: ", pnl,
         " perdas consecutivas: ", g_consecutive_losses);
}

//+------------------------------------------------------------------+
int ClosedDealDurationSeconds(ulong exit_deal)
{
   if(!HistoryDealSelect(exit_deal))
      return -1;

   long position_id = HistoryDealGetInteger(exit_deal, DEAL_POSITION_ID);
   datetime closed_at = (datetime)HistoryDealGetInteger(exit_deal, DEAL_TIME);
   if(position_id <= 0 || closed_at <= 0)
      return -1;

   if(!HistorySelect(0, TimeCurrent()))
      return -1;

   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0 || ticket == exit_deal)
         continue;

      if(!HistoryDealSelect(ticket))
         continue;

      if(HistoryDealGetInteger(ticket, DEAL_POSITION_ID) != position_id)
         continue;

      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_IN)
         continue;

      datetime opened_at = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      if(opened_at <= 0)
         return -1;

      return (int)(closed_at - opened_at);
   }

   return -1;
}

//+------------------------------------------------------------------+
double CalculateAtr(const MqlRates &rates[], int copied, int period)
{
   if(copied <= period + 2 || period <= 0)
      return 0.0;

   double total = 0.0;
   for(int i = 1; i <= period; i++)
   {
      double high_low = rates[i].high - rates[i].low;
      double high_close = MathAbs(rates[i].high - rates[i + 1].close);
      double low_close = MathAbs(rates[i].low - rates[i + 1].close);
      total += MathMax(high_low, MathMax(high_close, low_close));
   }

   return total / period;
}

//+------------------------------------------------------------------+
double AverageClose(const MqlRates &rates[], int copied, int start, int period)
{
   if(period <= 0 || start + period > copied)
      return 0.0;

   double total = 0.0;
   for(int i = start; i < start + period; i++)
      total += rates[i].close;

   return total / period;
}

//+------------------------------------------------------------------+
double HighestHigh(const MqlRates &rates[], int copied, int start, int period)
{
   if(period <= 0 || start + period > copied)
      return 0.0;

   double value = rates[start].high;
   for(int i = start + 1; i < start + period; i++)
      value = MathMax(value, rates[i].high);

   return value;
}

//+------------------------------------------------------------------+
double LowestLow(const MqlRates &rates[], int copied, int start, int period)
{
   if(period <= 0 || start + period > copied)
      return 0.0;

   double value = rates[start].low;
   for(int i = start + 1; i < start + period; i++)
      value = MathMin(value, rates[i].low);

   return value;
}

//+------------------------------------------------------------------+
void ClearPendingRetest()
{
   g_pending_retest_direction = 0;
   g_pending_retest_level = 0.0;
   g_pending_retest_expires = 0;
   g_pending_retest_source_bar = 0;
}

//+------------------------------------------------------------------+
void RegisterPendingRetest(int direction, double breakout_level, datetime source_bar_time)
{
   int seconds_per_bar = PeriodSeconds(PERIOD_M1);
   if(seconds_per_bar <= 0)
      seconds_per_bar = 60;

   g_pending_retest_direction = direction;
   g_pending_retest_level = breakout_level;
   g_pending_retest_source_bar = source_bar_time;
   g_pending_retest_expires = source_bar_time + InpRetestMaxBars * seconds_per_bar;

   Print("Rompimento aguardando reteste. Direcao: ", direction,
         " nivel: ", breakout_level,
         " expira: ", g_pending_retest_expires);
}

//+------------------------------------------------------------------+
bool TryConfirmPendingRetest(const MqlRates &rates[], int copied, int &direction)
{
   direction = 0;

   if(g_pending_retest_direction == 0 || g_pending_retest_level <= 0.0)
      return false;

   if(copied < 3)
      return false;

   MqlRates signal_bar = rates[1];
   if(signal_bar.time <= g_pending_retest_source_bar)
      return false;

   if(signal_bar.time > g_pending_retest_expires)
   {
      Print("Reteste expirado sem confirmacao. Nivel: ", g_pending_retest_level);
      ClearPendingRetest();
      return false;
   }

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tolerance = InpRetestTolerancePoints * point;
   double range = signal_bar.high - signal_bar.low;
   if(range <= 0.0)
      return false;

   double close_position = (signal_bar.close - signal_bar.low) / range;

   if(g_pending_retest_direction > 0)
   {
      bool touched = signal_bar.low <= g_pending_retest_level + tolerance;
      bool held = signal_bar.close >= g_pending_retest_level;
      bool candle_ok = !InpRequireRetestCandleDirection || signal_bar.close > signal_bar.open;

      if(touched && held && candle_ok && close_position >= 0.45)
      {
         direction = 1;
         Print("Reteste comprador confirmado no nivel: ", g_pending_retest_level);
         return true;
      }
   }

   if(g_pending_retest_direction < 0)
   {
      bool touched = signal_bar.high >= g_pending_retest_level - tolerance;
      bool held = signal_bar.close <= g_pending_retest_level;
      bool candle_ok = !InpRequireRetestCandleDirection || signal_bar.close < signal_bar.open;

      if(touched && held && candle_ok && close_position <= 0.55)
      {
         direction = -1;
         Print("Reteste vendedor confirmado no nivel: ", g_pending_retest_level);
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
bool DetectM1WSignal(const MqlRates &rates[], int copied, double atr, int &direction)
{
   direction = 0;

   int lookback = MathMax(InpWLookbackBars, 8);
   if(copied < lookback + 2 || atr <= 0.0)
      return false;

   MqlRates signal_bar = rates[1];
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tolerance = InpWTolerancePoints * point;

   if(InpAllowBuy && signal_bar.close > signal_bar.open)
   {
      double neckline = HighestHigh(rates, copied, 2, lookback - 2);
      double right_low = LowestLow(rates, copied, 2, 4);
      double left_low = LowestLow(rates, copied, 6, lookback - 6);
      double base_low = MathMin(left_low, right_low);

      bool lows_ok = right_low >= left_low - tolerance;
      bool neckline_ok = neckline - base_low >= atr * InpWMinNecklineAtr;

      if(neckline > 0.0 && signal_bar.close > neckline && lows_ok && neckline_ok)
      {
         direction = 1;
         return true;
      }
   }

   if(InpAllowSell && signal_bar.close < signal_bar.open)
   {
      double neckline = LowestLow(rates, copied, 2, lookback - 2);
      double right_high = HighestHigh(rates, copied, 2, 4);
      double left_high = HighestHigh(rates, copied, 6, lookback - 6);
      double base_high = MathMax(left_high, right_high);

      bool highs_ok = right_high <= left_high + tolerance;
      bool neckline_ok = base_high - neckline >= atr * InpWMinNecklineAtr;

      if(neckline > 0.0 && signal_bar.close < neckline && highs_ok && neckline_ok)
      {
         direction = -1;
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
double CalculateRiskLot(int stop_loss_points)
{
   if(stop_loss_points <= 0 || InpRiskPerTradePct <= 0.0)
      return NormalizeLot(MathMin(InpFixedLot, InpMaxLot));

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   if(equity <= 0.0 || tick_value <= 0.0 || tick_size <= 0.0 || point <= 0.0)
      return NormalizeLot(MathMin(InpFixedLot, InpMaxLot));

   double risk_money = equity * InpRiskPerTradePct;
   double stop_distance = stop_loss_points * point;
   double loss_per_lot = (stop_distance / tick_size) * tick_value;
   if(loss_per_lot <= 0.0)
      return NormalizeLot(MathMin(InpFixedLot, InpMaxLot));

   return NormalizeLot(MathMin(risk_money / loss_per_lot, InpMaxLot));
}

//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(step <= 0.0)
      step = 0.01;

   lot = MathMax(min_lot, MathMin(lot, max_lot));
   lot = MathFloor(lot / step) * step;

   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
bool PassHigherTimeframeFilter(int direction)
{
   if(!InpUseH1TrendFilter)
      return true;

   int needed_bars = MathMax(InpH1FastTrendPeriod, InpH1SlowTrendPeriod) + 3;
   MqlRates h1_rates[];
   ArraySetAsSeries(h1_rates, true);

   int copied = CopyRates(_Symbol, PERIOD_H1, 0, needed_bars, h1_rates);
   if(copied < needed_bars)
      return false;

   double fast = AverageClose(h1_rates, copied, 1, InpH1FastTrendPeriod);
   double slow = AverageClose(h1_rates, copied, 1, InpH1SlowTrendPeriod);
   if(fast <= 0.0 || slow <= 0.0)
      return false;

   double last_close = h1_rates[1].close;

   if(InpH1FilterMode == H1_FILTER_BLOCK_OPPOSITE)
   {
      if(direction > 0)
         return !(fast < slow && last_close < slow);

      if(direction < 0)
         return !(fast > slow && last_close > slow);

      return false;
   }

   if(direction > 0)
      return fast > slow && last_close > slow;

   if(direction < 0)
      return fast < slow && last_close < slow;

   return false;
}

//+------------------------------------------------------------------+
bool PassMtfConfluence(int direction)
{
   if(!InpUseMtfConfluence)
      return true;

   int aligned = 0;
   int opposite = 0;

   int m5_bias = TimeframeBias(PERIOD_M5, direction);
   int m15_bias = TimeframeBias(PERIOD_M15, direction);
   int h1_bias = TimeframeBias(PERIOD_H1, direction);

   if(m5_bias > 0)
      aligned++;
   else if(m5_bias < 0)
      opposite++;

   if(m15_bias > 0)
      aligned++;
   else if(m15_bias < 0)
      opposite++;

   if(h1_bias > 0)
      aligned++;
   else if(h1_bias < 0)
      opposite++;

   if(opposite >= 2)
      return false;

   return aligned >= InpMtfMinAligned;
}

//+------------------------------------------------------------------+
int TimeframeBias(ENUM_TIMEFRAMES timeframe, int direction)
{
   int needed_bars = MathMax(InpMtfFastTrendPeriod, InpMtfSlowTrendPeriod) + 3;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   int copied = CopyRates(_Symbol, timeframe, 0, needed_bars, rates);
   if(copied < needed_bars)
      return 0;

   double fast = AverageClose(rates, copied, 1, InpMtfFastTrendPeriod);
   double slow = AverageClose(rates, copied, 1, InpMtfSlowTrendPeriod);
   if(fast <= 0.0 || slow <= 0.0)
      return 0;

   double last_close = rates[1].close;

   if(direction > 0)
   {
      if(fast >= slow && last_close >= slow)
         return 1;

      if(fast < slow && last_close < slow)
         return -1;
   }

   if(direction < 0)
   {
      if(fast <= slow && last_close <= slow)
         return 1;

      if(fast > slow && last_close > slow)
         return -1;
   }

   return 0;
}

//+------------------------------------------------------------------+
bool CanSendOrders()
{
   return InpEnableLiveOrders ||
      (InpEnableTesterOrders && (bool)MQLInfoInteger(MQL_TESTER));
}
