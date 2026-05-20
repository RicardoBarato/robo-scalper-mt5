//+------------------------------------------------------------------+
//|                                                  RB_Ouro_v4_4.mq5 |
//|  v4.4: Robustness Mode (mais trades) mantendo ciclo/expansão      |
//|  mode=0 Selective (PF max) | mode=1 Robust (PF>=1.6 alvo)         |
//+------------------------------------------------------------------+
#property strict
#property version "4.40"

#include <Trade/Trade.mqh>
CTrade trade;

//==================== SAFETY ====================//
input string InpAllowedSymbol = "XAUUSD";
input bool   InpEnableLiveOrders = false;
input bool   InpEnableTesterOrders = true;
input int    InpMagicNumber = 55749699;

//==================== MODE ====================//
// 0 = Selective (v4.3-like) | 1 = Robust (mais trades)
input int InpMode = 1;

//==================== INPUTS ====================//
input int session_reset_hour = 20;
input int cooldown_minutes_after_sl = 15;

input int SpreadMax_points     = 35;
input int SlippageMax_points  = 30;

input double risk_base_pct     = 0.007;
input double max_daily_loss_R  = 3.0;
input int    max_trades_day    = 6;

// SESSION (power windows)
input bool use_session_filter = true;
input int session1_start_hour = 8;
input int session1_end_hour   = 11;
input int session2_start_hour = 13;
input int session2_end_hour   = 16;

// BASE
input int ATR_period   = 14;   // ATR M1
input int ADX_period   = 14;   // ADX M1
input double ADX_min   = 25.0;
input int MinATR_points = 120;

input ENUM_TIMEFRAMES TF_bias     = PERIOD_H1;
input int EMA_bias_fast = 50;
input int EMA_bias_slow = 200;

input ENUM_TIMEFRAMES TF_structure = PERIOD_M15;
input int structure_lookback = 14;

input double impulse_mult      = 2.2;
input double close_pos_min     = 0.70;

input double structural_buffer_ATR = 0.25;
input int    MinSL_points = 80;

input double TP_R = 2.0;

// REGIME (M5)
input bool use_vol_regime = true;
input ENUM_TIMEFRAMES TF_vol = PERIOD_M5;
input int ATR_vol_period = 14;
input int ATR_vol_sma_len = 200;
input double atr_exp_mult = 1.00;

// Risk scaler
input bool use_risk_scaler = true;
input double risk_min_pct = 0.004;
input double risk_max_pct = 0.010;
input double risk_scaler_k = 0.8;

// SQUEEZE (M5)
input bool use_squeeze_filter = true;
input ENUM_TIMEFRAMES TF_squeeze = PERIOD_M5;
input int bb_period = 20;
input double bb_dev = 2.0;
input int kc_ema_period = 20;
input int kc_atr_period = 20;
input double kc_mult = 1.30;
input int squeeze_release_window_bars = 10;

// Cycle filter
input bool use_cycle_filter = true;
input int cycle_lookback_bars = 36;

// Volatility Expansion Trigger (M1)
input bool use_atr_accel = true;
input int  atr_accel_sma_len = 200;
input double exp_ratio_min = 1.15;

input bool use_range_expansion = true;
input double range_exp_mult = 2.4;

// ADX M15 gate
input bool use_adx_m15_gate = true;
input int  ADX_M15_period = 14;
input double ADX_M15_min_selective = 18.0;
input double ADX_M15_min_robust    = 16.0;

// allow_no_squeeze by mode
input bool allow_no_squeeze_selective = false;
input bool allow_no_squeeze_robust    = true;

//==================== STATE ====================//
double daily_loss_R=0.0;
int trades_today=0;
bool locked_today=false;
int session_day_key=-1;
datetime last_sl_time=0;

bool squeeze_prev_on=false;
int squeeze_release_countdown=0;
datetime last_squeeze_bar_time=0;

bool squeeze_seen_recent=false;

// handles
int atr_m1_handle=INVALID_HANDLE;
int adx_m1_handle=INVALID_HANDLE;
int ema_fast_handle=INVALID_HANDLE;
int ema_slow_handle=INVALID_HANDLE;

int atr_vol_handle=INVALID_HANDLE;

int bb_handle=INVALID_HANDLE;
int kc_ema_handle=INVALID_HANDLE;
int kc_atr_handle=INVALID_HANDLE;

int adx_m15_handle=INVALID_HANDLE;

//==================== HELPERS ====================//
int GetSessionDayKey(datetime t)
{
   datetime shifted = t - (session_reset_hour * 3600);
   MqlDateTime tm; TimeToStruct(shifted, tm);
   return (tm.year*10000 + tm.mon*100 + tm.day);
}

void ResetDailyIfNeeded()
{
   int key=GetSessionDayKey(TimeCurrent());
   if(key!=session_day_key)
   {
      session_day_key=key;
      daily_loss_R=0.0;
      trades_today=0;
      locked_today=false;
      last_sl_time=0;

      squeeze_prev_on=false;
      squeeze_release_countdown=0;
      last_squeeze_bar_time=0;
      squeeze_seen_recent=false;
   }
}

double GetValuePerPoint()
{
   double tick_value=SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size =SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point     =SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(tick_size<=0.0) return 0.0;
   return tick_value*(point/tick_size);
}

double NormalizeLots(double lots)
{
   double step=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step<=0.0) return 0.0;
   lots=MathFloor(lots/step)*step;
   if(lots<minLot) return 0.0;
   if(lots>maxLot) lots=maxLot;
   return lots;
}

double CalcLots(double sl_points, double risk_pct)
{
   if(sl_points<=0.0) return 0.0;
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_money=equity*risk_pct;
   double vpp=GetValuePerPoint();
   if(vpp<=0.0) return 0.0;
   return NormalizeLots(risk_money/(sl_points*vpp));
}

bool SpreadOK()
{
   double spread_points=(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/_Point;
   return (spread_points<=SpreadMax_points);
}

bool InWindow(int h,int start,int end_exclusive)
{
   if(start<end_exclusive) return (h>=start && h<end_exclusive);
   if(start>end_exclusive) return (h>=start || h<end_exclusive);
   return false;
}

bool SessionOK()
{
   if(!use_session_filter) return true;
   MqlDateTime tm; TimeToStruct(TimeCurrent(), tm);
   int h=tm.hour;
   return (InWindow(h,session1_start_hour,session1_end_hour) ||
           InWindow(h,session2_start_hour,session2_end_hour));
}

bool BiasUp()
{
   double f[1], s[1];
   if(CopyBuffer(ema_fast_handle,0,0,1,f)!=1) return false;
   if(CopyBuffer(ema_slow_handle,0,0,1,s)!=1) return false;
   return (f[0]>s[0]);
}
bool BiasDown()
{
   double f[1], s[1];
   if(CopyBuffer(ema_fast_handle,0,0,1,f)!=1) return false;
   if(CopyBuffer(ema_slow_handle,0,0,1,s)!=1) return false;
   return (f[0]<s[0]);
}

bool GetM15StructureLevels(double &HH15,double &LL15)
{
   int idxH=iHighest(_Symbol, TF_structure, MODE_HIGH, structure_lookback, 1);
   int idxL=iLowest(_Symbol, TF_structure, MODE_LOW,  structure_lookback, 1);
   if(idxH<0 || idxL<0) return false;
   HH15=iHigh(_Symbol, TF_structure, idxH);
   LL15=iLow(_Symbol,  TF_structure, idxL);
   return true;
}

// Regime + risk
bool GetVolRatio(double &ratio)
{
   ratio=1.0;
   if(!use_vol_regime && !use_risk_scaler) return true;
   int need=MathMax(ATR_vol_sma_len,2);
   double buf[];
   ArrayResize(buf,need);
   if(CopyBuffer(atr_vol_handle,0,0,need,buf)!=need) return false;
   double atr_now=buf[0];
   double sum=0.0;
   for(int i=0;i<ATR_vol_sma_len && i<need;i++) sum+=buf[i];
   double atr_avg=sum/ATR_vol_sma_len;
   if(atr_avg<=0.0) return false;
   ratio=atr_now/atr_avg;
   return true;
}

bool VolatilityRegimeOK(double vol_ratio)
{
   if(!use_vol_regime) return true;
   return (vol_ratio>=atr_exp_mult);
}

double CalcRiskPct(double vol_ratio)
{
   double r=risk_base_pct;
   if(use_risk_scaler)
   {
      double mult=1.0 + risk_scaler_k*(vol_ratio-1.0);
      r=risk_base_pct*mult;
      if(r<risk_min_pct) r=risk_min_pct;
      if(r>risk_max_pct) r=risk_max_pct;
   }
   return r;
}

// Squeeze computations
bool ComputeSqueezeOn(bool &squeeze_on)
{
   squeeze_on=false;
   if(!use_squeeze_filter) return true;

   double bb_up[1], bb_dn[1];
   if(CopyBuffer(bb_handle,0,0,1,bb_up)!=1) return false;
   if(CopyBuffer(bb_handle,2,0,1,bb_dn)!=1) return false;

   double ema_mid[1], atr_kc[1];
   if(CopyBuffer(kc_ema_handle,0,0,1,ema_mid)!=1) return false;
   if(CopyBuffer(kc_atr_handle,0,0,1,atr_kc)!=1) return false;

   double kc_upper=ema_mid[0] + kc_mult*atr_kc[0];
   double kc_lower=ema_mid[0] - kc_mult*atr_kc[0];

   squeeze_on = (bb_up[0] < kc_upper) && (bb_dn[0] > kc_lower);
   return true;
}

void UpdateCycleMemory()
{
   if(!use_squeeze_filter || !use_cycle_filter) return;

   datetime t0=iTime(_Symbol, TF_squeeze, 0);
   if(t0==0) return;

   static int bars_since_squeeze=1000000;

   if(last_squeeze_bar_time==0) last_squeeze_bar_time=t0;

   if(t0!=last_squeeze_bar_time)
   {
      last_squeeze_bar_time=t0;

      bool squeeze_on=false;
      if(ComputeSqueezeOn(squeeze_on))
      {
         if(squeeze_on){ squeeze_seen_recent=true; bars_since_squeeze=0; }
         else bars_since_squeeze++;
      }

      if(bars_since_squeeze > cycle_lookback_bars) squeeze_seen_recent=false;

      if(squeeze_release_countdown>0) squeeze_release_countdown--;
   }
}

bool SqueezeGateOK()
{
   if(!use_squeeze_filter) return true;

   UpdateCycleMemory();

   bool squeeze_on=false;
   if(!ComputeSqueezeOn(squeeze_on)) return false;

   if(squeeze_prev_on && !squeeze_on)
      squeeze_release_countdown=squeeze_release_window_bars;

   squeeze_prev_on=squeeze_on;

   if(squeeze_on) return false;

   bool in_release = (squeeze_release_countdown>0);

   bool allow_no_squeeze = (InpMode==0) ? allow_no_squeeze_selective : allow_no_squeeze_robust;
   double adx_m15_min = (InpMode==0) ? ADX_M15_min_selective : ADX_M15_min_robust;

   // store adx_m15_min via global static? we'll query in ADX_M15_OK()
   // Cycle logic
   if(use_cycle_filter)
   {
      if(squeeze_seen_recent && in_release) return true;
      return allow_no_squeeze;
   }

   if(in_release) return true;
   return allow_no_squeeze;
}

// Vol expansion trigger
bool ATRAccelerationOK()
{
   if(!use_atr_accel) return true;
   int need=MathMax(atr_accel_sma_len,2);
   double buf[];
   ArrayResize(buf,need);
   if(CopyBuffer(atr_m1_handle,0,0,need,buf)!=need) return false;
   double atr_now=buf[0];
   double sum=0.0;
   for(int i=0;i<atr_accel_sma_len && i<need;i++) sum+=buf[i];
   double atr_avg=sum/atr_accel_sma_len;
   if(atr_avg<=0.0) return false;
   return (atr_now >= atr_avg*exp_ratio_min);
}

bool RangeExpansionOK(double atr_points)
{
   if(!use_range_expansion) return true;
   double high0=iHigh(_Symbol, PERIOD_M1, 0);
   double low0 =iLow(_Symbol,  PERIOD_M1, 0);
   double range_points=(high0-low0)/_Point;
   return (range_points >= range_exp_mult*atr_points);
}

bool VolExpansionTriggerOK(double atr_points)
{
   bool a=ATRAccelerationOK();
   bool b=RangeExpansionOK(atr_points);

   if(use_atr_accel && use_range_expansion) return (a || b);
   if(use_atr_accel) return a;
   if(use_range_expansion) return b;
   return true;
}

bool ADX_M15_OK()
{
   if(!use_adx_m15_gate) return true;
   double buf[1];
   if(CopyBuffer(adx_m15_handle,0,0,1,buf)!=1) return false;
   double minv = (InpMode==0) ? ADX_M15_min_selective : ADX_M15_min_robust;
   return (buf[0] >= minv);
}

//==================== ONINIT ====================//
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagicNumber);

   atr_m1_handle = iATR(_Symbol, PERIOD_M1, ATR_period);
   adx_m1_handle = iADX(_Symbol, PERIOD_M1, ADX_period);
   ema_fast_handle = iMA(_Symbol, TF_bias, EMA_bias_fast, 0, MODE_EMA, PRICE_CLOSE);
   ema_slow_handle = iMA(_Symbol, TF_bias, EMA_bias_slow, 0, MODE_EMA, PRICE_CLOSE);

   if(use_vol_regime || use_risk_scaler)
      atr_vol_handle = iATR(_Symbol, TF_vol, ATR_vol_period);

   if(use_squeeze_filter)
   {
      bb_handle = iBands(_Symbol, TF_squeeze, bb_period, 0, bb_dev, PRICE_CLOSE);
      kc_ema_handle = iMA(_Symbol, TF_squeeze, kc_ema_period, 0, MODE_EMA, PRICE_CLOSE);
      kc_atr_handle = iATR(_Symbol, TF_squeeze, kc_atr_period);
   }

   if(use_adx_m15_gate)
      adx_m15_handle = iADX(_Symbol, PERIOD_M15, ADX_M15_period);

   if(atr_m1_handle==INVALID_HANDLE || adx_m1_handle==INVALID_HANDLE ||
      ema_fast_handle==INVALID_HANDLE || ema_slow_handle==INVALID_HANDLE)
      return INIT_FAILED;

   if((use_vol_regime || use_risk_scaler) && atr_vol_handle==INVALID_HANDLE)
      return INIT_FAILED;

   if(use_squeeze_filter && (bb_handle==INVALID_HANDLE || kc_ema_handle==INVALID_HANDLE || kc_atr_handle==INVALID_HANDLE))
      return INIT_FAILED;

   if(use_adx_m15_gate && adx_m15_handle==INVALID_HANDLE)
      return INIT_FAILED;

   trade.SetDeviationInPoints(SlippageMax_points);
   session_day_key = GetSessionDayKey(TimeCurrent());
   return INIT_SUCCEEDED;
}

//==================== ONTICK ====================//
void OnTick()
{
   if(_Symbol != InpAllowedSymbol)
      return;

   ResetDailyIfNeeded();

   if(last_sl_time>0 && (TimeCurrent()-last_sl_time) < cooldown_minutes_after_sl*60) return;
   if(!SessionOK()) return;
   if(PositionSelect(_Symbol)) return;

   if(locked_today) return;
   if(trades_today >= max_trades_day) return;
   if(!SpreadOK()) return;

   double vol_ratio=1.0;
   if(!GetVolRatio(vol_ratio)) return;
   if(!VolatilityRegimeOK(vol_ratio)) return;
   double risk_pct=CalcRiskPct(vol_ratio);

   if(!SqueezeGateOK()) return;
   if(!ADX_M15_OK()) return;

   bool bias_up=BiasUp();
   bool bias_dn=BiasDown();
   if(!bias_up && !bias_dn) return;

   double atr_buf[1];
   if(CopyBuffer(atr_m1_handle,0,0,1,atr_buf)!=1) return;
   double atr_points=atr_buf[0]/_Point;
   if(atr_points < MinATR_points) return;

   if(!VolExpansionTriggerOK(atr_points)) return;

   double adx_buf[1];
   if(CopyBuffer(adx_m1_handle,0,0,1,adx_buf)!=1) return;
   if(adx_buf[0] < ADX_min) return;

   double HH15=0.0, LL15=0.0;
   if(!GetM15StructureLevels(HH15,LL15)) return;

   double high0=iHigh(_Symbol, PERIOD_M1, 0);
   double low0 =iLow(_Symbol,  PERIOD_M1, 0);
   double close0=iClose(_Symbol, PERIOD_M1, 0);

   double range_points=(high0-low0)/_Point;
   if(range_points < impulse_mult*atr_points) return;

   double close_pos = (high0>low0) ? ((close0-low0)/(high0-low0)) : 0.5;

   double ask=SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double buffer_points=structural_buffer_ATR*atr_points;

   if(bias_up && bid>HH15 && close_pos>=close_pos_min)
   {
      double sl_price = LL15 - buffer_points*_Point;
      double sl_points = (ask - sl_price)/_Point;
      if(sl_points < MinSL_points) sl_points = MinSL_points;

      double lots=CalcLots(sl_points, risk_pct);
      if(lots<=0.0) return;

      double tp_price = ask + (TP_R*sl_points)*_Point;

      if(CanSendOrders() && trade.Buy(lots,_Symbol,ask,sl_price,tp_price))
         trades_today++;
      return;
   }

   if(bias_dn && ask<LL15 && close_pos <= (1.0-close_pos_min))
   {
      double sl_price = HH15 + buffer_points*_Point;
      double sl_points = (sl_price - bid)/_Point;
      if(sl_points < MinSL_points) sl_points = MinSL_points;

      double lots=CalcLots(sl_points, risk_pct);
      if(lots<=0.0) return;

      double tp_price = bid - (TP_R*sl_points)*_Point;

      if(CanSendOrders() && trade.Sell(lots,_Symbol,bid,sl_price,tp_price))
         trades_today++;
      return;
   }
}

//==================== ONTRADETRANSACTION ====================//
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD) return;
   if(trans.deal<=0) return;

   datetime now=TimeCurrent();
   HistorySelect(now-86400, now+60);

   long reason=(long)HistoryDealGetInteger(trans.deal, DEAL_REASON);
   if(reason==DEAL_REASON_SL)
   {
      daily_loss_R -= 1.0;
      last_sl_time = TimeCurrent();
      if(daily_loss_R <= -max_daily_loss_R) locked_today=true;
   }
}

bool CanSendOrders()
{
   return InpEnableLiveOrders ||
      (InpEnableTesterOrders && (bool)MQLInfoInteger(MQL_TESTER));
}
