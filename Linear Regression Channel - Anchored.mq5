//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "Delimited Linear Regression Channel"
#property indicator_chart_window
#property indicator_buffers 33
#property indicator_plots   33

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_REG_SOURCE {
   Open,           // Open
   High,           // High
   Low,             // Low
   Close,         // Close
   Typical,     // Typical
};

//+----------------------------------------------+
//|  Middle channel line drawing parameters      |
//+----------------------------------------------+
//---- drawing the indicator as a label
#property indicator_type1   DRAW_LINE
//---- displaying the indicator label
#property indicator_label1  "Canal de regressão linear"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input string nickname                     = "";
input string                     Id = "+canalreg";                                           // Identifier

input group "***************  Time delimiters ***************"
input datetime                   data_inicial = "2021.12.8 12:00:00";                  // Initial date
input datetime                   data_final = "2022.1.18 10:00:00";                    // Final date
input color                      TimeFromColor = clrLime;                              // Left border line color
input int                        TimeFromWidth = 1;                                    // Left border line width
input ENUM_LINE_STYLE            TimeFromStyle = STYLE_DASH;                           // Left border line style
input color                      TimeToColor = clrRed;                                 // Right border line color
input int                        TimeToWidth = 1;                                      // Right border line width
input ENUM_LINE_STYLE            TimeToStyle = STYLE_DASH;                             // Right border line style
input bool                       AutoLimitLines = true;                                // Automatic limit left and right lines
input bool                       FitToLines = true;                                    // Automatic fit histogram inside lines
input bool                       KeepRightLineUpdated = true;                          // Automatic update of the rightmost line
input int                        ShiftCandles = 3;                                     // Distance in candles to adjust on automatic
input int                        WaitMilliseconds = 500000;                            // Timer (milliseconds) for recalculation

input group "***************  Regressão Linear ***************"
input bool                       EnableRegression = true;                              // Exibe a curva de regressão linear
input ENUM_REG_SOURCE            RegressionSource = Close;                             // Fonte dos dados da curva de regressão linear
input color                      RegColor = clrMagenta;                                // Cor da linha do indicador
input int                        RegWidth = 1;                                         // Espessura da linha do indicador
input ENUM_LINE_STYLE            RegStyle = STYLE_SOLID;                               // Estilo da linha do indicador
input double                     ChannelWidth = 1;                                     // Largura das bandas do canal
input double                     DeviationsNumber = 1;                                 // Número de desvios a serem exibidos
input double                     DeviationsOffset = 0;                                 // Deslocamento dos desvios
input color                      RegChannelColor = clrMagenta;                         // Cor da linha do canal
input int                        RegChannelWidth = 1;                                  // Espessura da linha do canal
input ENUM_LINE_STYLE            RegChannelStyle = STYLE_DOT;                          // Estilo da linha do canal

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime timeFrom;
datetime timeTo;
string _prefix;
string _timeFromLine;
string _timeToLine;
color _timeToColor;
color _timeFromColor;
int _timeToWidth;
int _timeFromWidth;
//--- indicator buffers
double regBuffer[];
double stDevBuffer[];
double upChannel1[], upChannel2[], upChannel3[], upChannel4[], upChannel5[], upChannel6[], upChannel7[], upChannel8[];
double upChannel9[], upChannel10[], upChannel11[], upChannel12[], upChannel13[], upChannel14[], upChannel15[], upChannel16[];
double downChannel1[], downChannel2[], downChannel3[], downChannel4[], downChannel5[], downChannel6[], downChannel7[], downChannel8[];
double downChannel9[], downChannel10[], downChannel11[], downChannel12[], downChannel13[], downChannel14[], downChannel15[], downChannel16[];
int totalRates;
long totalCandles = 0;
bool temPrioridade = true;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//---- initializations of a variable for the indicator short name
   string shortname = "Canal de desvio-padrão ancorado";
//---- creating a name for displaying in a separate sub-window and in a tooltip
   if (nickname != "")
      IndicatorSetString(INDICATOR_SHORTNAME, nickname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);
//

   _prefix = Id + " m1 ";
   _timeFromLine = Id + "-from";
   _timeToLine = Id + "-to";

   ObjectCreate(0, "existeCanalRegressao", OBJ_TEXT, 0, 0, 0);

   if(ObjectFind(0, "existeVolumeProfile") != 0)
      temPrioridade = false;
   _timeToColor = TimeToColor;
   _timeFromColor = TimeFromColor;
   _timeToWidth = TimeToWidth;
   _timeFromWidth = TimeFromWidth;

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);

// set regBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0, regBuffer, INDICATOR_DATA);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, RegColor);
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, RegWidth);
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, RegStyle);
   PlotIndexSetString(0, PLOT_LABEL, "Curva de regressão linear");

   SetIndexBuffer(1, upChannel1, INDICATOR_DATA);
   SetIndexBuffer(2, upChannel2, INDICATOR_DATA);
   SetIndexBuffer(3, upChannel3, INDICATOR_DATA);
   SetIndexBuffer(4, upChannel4, INDICATOR_DATA);
   SetIndexBuffer(5, upChannel5, INDICATOR_DATA);
   SetIndexBuffer(6, upChannel6, INDICATOR_DATA);
   SetIndexBuffer(7, upChannel7, INDICATOR_DATA);
   SetIndexBuffer(8, upChannel8, INDICATOR_DATA);
   SetIndexBuffer(9, upChannel9, INDICATOR_DATA);
   SetIndexBuffer(10, upChannel10, INDICATOR_DATA);
   SetIndexBuffer(11, upChannel11, INDICATOR_DATA);
   SetIndexBuffer(12, upChannel12, INDICATOR_DATA);
   SetIndexBuffer(13, upChannel13, INDICATOR_DATA);
   SetIndexBuffer(14, upChannel14, INDICATOR_DATA);
   SetIndexBuffer(15, upChannel15, INDICATOR_DATA);
   SetIndexBuffer(16, upChannel16, INDICATOR_DATA);
   SetIndexBuffer(17, downChannel1, INDICATOR_DATA);
   SetIndexBuffer(18, downChannel2, INDICATOR_DATA);
   SetIndexBuffer(19, downChannel3, INDICATOR_DATA);
   SetIndexBuffer(20, downChannel4, INDICATOR_DATA);
   SetIndexBuffer(21, downChannel5, INDICATOR_DATA);
   SetIndexBuffer(22, downChannel6, INDICATOR_DATA);
   SetIndexBuffer(23, downChannel7, INDICATOR_DATA);
   SetIndexBuffer(24, downChannel8, INDICATOR_DATA);
   SetIndexBuffer(25, downChannel9, INDICATOR_DATA);
   SetIndexBuffer(26, downChannel10, INDICATOR_DATA);
   SetIndexBuffer(27, downChannel11, INDICATOR_DATA);
   SetIndexBuffer(28, downChannel12, INDICATOR_DATA);
   SetIndexBuffer(29, downChannel13, INDICATOR_DATA);
   SetIndexBuffer(30, downChannel14, INDICATOR_DATA);
   SetIndexBuffer(31, downChannel15, INDICATOR_DATA);
   SetIndexBuffer(32, downChannel16, INDICATOR_DATA);

   for (int i = 1; i <= 33; i++) {
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0.0); // restriction to draw empty values for the indicator
      PlotIndexSetInteger(i, PLOT_LINE_COLOR, RegChannelColor);
      PlotIndexSetInteger(i, PLOT_DRAW_TYPE, DRAW_LINE);
      PlotIndexSetInteger(i, PLOT_LINE_WIDTH, RegChannelWidth);
      PlotIndexSetInteger(i, PLOT_LINE_STYLE, RegChannelStyle);
   }

// indexing the elements in buffers as timeseries
   ArraySetAsSeries(regBuffer, true);
   ArraySetAsSeries(upChannel1, true);
   ArraySetAsSeries(upChannel2, true);
   ArraySetAsSeries(upChannel3, true);
   ArraySetAsSeries(upChannel4, true);
   ArraySetAsSeries(upChannel5, true);
   ArraySetAsSeries(upChannel6, true);
   ArraySetAsSeries(upChannel7, true);
   ArraySetAsSeries(upChannel8, true);
   ArraySetAsSeries(upChannel9, true);
   ArraySetAsSeries(upChannel10, true);
   ArraySetAsSeries(upChannel11, true);
   ArraySetAsSeries(upChannel12, true);
   ArraySetAsSeries(upChannel13, true);
   ArraySetAsSeries(upChannel14, true);
   ArraySetAsSeries(upChannel15, true);
   ArraySetAsSeries(upChannel16, true);
   ArraySetAsSeries(downChannel1, true);
   ArraySetAsSeries(downChannel2, true);
   ArraySetAsSeries(downChannel3, true);
   ArraySetAsSeries(downChannel4, true);
   ArraySetAsSeries(downChannel5, true);
   ArraySetAsSeries(downChannel6, true);
   ArraySetAsSeries(downChannel7, true);
   ArraySetAsSeries(downChannel8, true);
   ArraySetAsSeries(downChannel9, true);
   ArraySetAsSeries(downChannel10, true);
   ArraySetAsSeries(downChannel11, true);
   ArraySetAsSeries(downChannel12, true);
   ArraySetAsSeries(downChannel13, true);
   ArraySetAsSeries(downChannel14, true);
   ArraySetAsSeries(downChannel15, true);
   ArraySetAsSeries(downChannel16, true);



   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   totalRates = rates_total;
   CheckTimer();

   return(1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

   if(UninitializeReason() == REASON_REMOVE) {
      ObjectDelete(0, _timeFromLine);
      ObjectDelete(0, _timeToLine);
   }
   delete(_updateTimer);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update() {

   timeFrom = GetObjectTime1(_timeFromLine);
   timeTo = GetObjectTime1(_timeToLine);

   if((timeFrom == 0) || (timeTo == 0)) {
      datetime timeLeft = GetBarTime(WindowFirstVisibleBar());
      datetime timeRight = GetBarTime(WindowFirstVisibleBar() - WindowBarsPerChart());
      ulong timeRange = timeRight - timeLeft;

      timeFrom = (datetime)(timeLeft + timeRange / 3);
      timeTo = (datetime)(timeLeft + timeRange * 2 / 3);

      timeFrom = data_inicial;
      timeTo = data_final;

      DrawVLine(_timeFromLine, timeFrom, _timeFromColor, _timeFromWidth, TimeFromStyle, true, true, false, 1000);
      DrawVLine(_timeToLine, timeTo, _timeToColor, _timeToWidth, TimeToStyle, true, true, false, 1000);

   }

   datetime minimumDate = iTime(_Symbol, PERIOD_CURRENT, iBars(_Symbol, _Period) - 1);
   datetime maximumDate = iTime(_Symbol, PERIOD_CURRENT, 0);
   if (timeFrom < minimumDate) {
      ObjectSetInteger(0, _timeFromLine, OBJPROP_TIME, 0, minimumDate);
      timeFrom = minimumDate;
   }

   if (AutoLimitLines) {
      datetime hoje = StringToTime(TimeToString(TimeCurrent() + (PeriodSeconds(PERIOD_CURRENT)), TIME_DATE));
      hoje = maximumDate + PeriodSeconds(PERIOD_CURRENT) * ShiftCandles;
      if (timeTo > hoje)
         timeTo = hoje;
   }

   if (KeepRightLineUpdated) {
      datetime lastCandleShifted = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT);
      if (timeTo >= lastCandleShifted) {
         datetime hoje = StringToTime(TimeToString(TimeCurrent() + (PeriodSeconds(PERIOD_CURRENT)), TIME_DATE) );
         hoje = lastCandleShifted +  PeriodSeconds(PERIOD_CURRENT) * ShiftCandles;
         timeTo = hoje;
      }
   }

   ObjectSetInteger(0, _timeToLine, OBJPROP_TIME, 0, timeTo);

   ObjectEnable(0, _timeFromLine);
   ObjectEnable(0, _timeToLine);

   ObjectSetInteger(0, _timeToLine, OBJPROP_COLOR, _timeToColor);
   ObjectSetInteger(0, _timeToLine, OBJPROP_WIDTH, _timeToWidth);
   ObjectSetInteger(0, _timeToLine, OBJPROP_STYLE, TimeToStyle);
   ObjectSetInteger(0, _timeToLine, OBJPROP_BACK, false);
   ObjectSetInteger(0, _timeToLine, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, _timeToLine, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, _timeToLine, OBJPROP_ZORDER, 1000);

   ObjectSetInteger(0, _timeFromLine, OBJPROP_COLOR, _timeFromColor);
   ObjectSetInteger(0, _timeFromLine, OBJPROP_WIDTH, _timeFromWidth);
   ObjectSetInteger(0, _timeFromLine, OBJPROP_STYLE, TimeFromStyle);
   ObjectSetInteger(0, _timeFromLine, OBJPROP_BACK, false);
   ObjectSetInteger(0, _timeFromLine, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, _timeFromLine, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, _timeFromLine, OBJPROP_ZORDER, 1000);

   if(timeFrom > timeTo)
      Swap(timeFrom, timeTo);

   int barFrom, barTo;
   if(!GetRangeBars(timeFrom, timeTo, barFrom, barTo))
      return(false);

   CalculateRegression(barFrom, barTo, RegressionSource);

   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CalculateRegression(int fromBar, int toBar, ENUM_REG_SOURCE tipo) {

   double dataArray[];

   double dataArrayClose[], dataArrayHigh[], dataArrayLow[];

   if (toBar < 0)
      toBar = 0;
   int CalcBars = MathAbs(fromBar - toBar) + 1;

   if (tipo == Close) {
      CopyClose(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArray);
      CopyClose(Symbol(), PERIOD_CURRENT, 0, totalRates, dataArrayClose);
      ArrayReverse(dataArrayClose);
   } else if (tipo == Open)
      CopyOpen(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArray);
   else if (tipo == High)
      CopyHigh(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArray);
   else if (tipo == Low)
      CopyLow(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArray);
   else if (tipo == Typical) {

      CopyClose(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArrayClose);
      CopyHigh(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArrayHigh);
      CopyLow(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArrayLow);
      ArrayResize(dataArray, ArraySize(dataArrayClose));
      for(int i = 0; i < ArraySize(dataArrayClose); i++) {
         dataArray[i] = (dataArrayHigh[i] + dataArrayLow[i] + dataArrayClose[i]) / 3;
      }
      ArrayFree(dataArrayClose);
      ArrayFree(dataArrayHigh);
      ArrayFree(dataArrayLow);
   }

   ArrayReverse(dataArray);

   for(int n = 0; n < ArraySize(regBuffer) - 1; n++) {
      regBuffer[n] = 0.0;
      upChannel1[n] = 0.0;
      downChannel1[n] = 0.0;
      upChannel2[n] = 0.0;
      downChannel2[n] = 0.0;
      upChannel3[n] = 0.0;
      downChannel3[n] = 0.0;
      upChannel4[n] = 0.0;
      downChannel4[n] = 0.0;
      upChannel5[n] = 0.0;
      downChannel5[n] = 0.0;
      upChannel6[n] = 0.0;
      downChannel6[n] = 0.0;
      upChannel7[n] = 0.0;
      downChannel7[n] = 0.0;
      upChannel8[n] = 0.0;
      downChannel8[n] = 0.0;
      upChannel9[n] = 0.0;
      downChannel9[n] = 0.0;
      upChannel10[n] = 0.0;
      downChannel10[n] = 0.0;
      upChannel11[n] = 0.0;
      downChannel11[n] = 0.0;
      upChannel12[n] = 0.0;
      downChannel12[n] = 0.0;
      upChannel13[n] = 0.0;
      downChannel13[n] = 0.0;
      upChannel14[n] = 0.0;
      downChannel14[n] = 0.0;
      upChannel15[n] = 0.0;
      downChannel15[n] = 0.0;
      upChannel16[n] = 0.0;
      downChannel16[n] = 0.0;
   }

   double A = 0, B = 0;
   CalcAB(dataArrayClose, fromBar, toBar, A, B);
//double stdev = GetStdDev(dataArray, ArraySize(dataArray) - 1, 0); //calculate standand deviation

   int indiceFinal = CalcBars - 1;
   for(int i = fromBar; i >= toBar; i--) {
      regBuffer[i] = (A * (i) + B);
   }
//regBuffer[fromBar] = dataArray[fromBar];

//calculamos a distância máxima entre a linha de regressão e os fechamentos
   long bar = 0;
   double resultado = 0, l = 0, h = 0;

   for(bar = toBar; bar < fromBar; bar++) {
      h = MathMax(h, dataArrayClose[bar] - regBuffer[bar]);
      l = MathMax(l, regBuffer[bar] - dataArrayClose[bar]);
   }

   if(h > l)
      resultado = h;
   else
      resultado = l;

   for(int i = toBar; i <= fromBar; i++) {

      if (DeviationsNumber >= 16) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[i] = regBuffer[i] + resultado * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[i] = regBuffer[i] + resultado * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[i] = regBuffer[i] + resultado * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[i] = regBuffer[i] + resultado * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[i] = regBuffer[i] + resultado * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[i] = regBuffer[i] + resultado * ((10 + DeviationsOffset) * ChannelWidth);
         upChannel11[i] = regBuffer[i] + resultado * ((11 + DeviationsOffset) * ChannelWidth);
         upChannel12[i] = regBuffer[i] + resultado * ((12 + DeviationsOffset) * ChannelWidth);
         upChannel13[i] = regBuffer[i] + resultado * ((13 + DeviationsOffset) * ChannelWidth);
         upChannel14[i] = regBuffer[i] + resultado * ((14 + DeviationsOffset) * ChannelWidth);
         upChannel15[i] = regBuffer[i] + resultado * ((15 + DeviationsOffset) * ChannelWidth);
         upChannel16[i] = regBuffer[i] + resultado * ((16 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[i] = regBuffer[i] - resultado * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[i] = regBuffer[i] - resultado * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[i] = regBuffer[i] - resultado * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[i] = regBuffer[i] - resultado * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[i] = regBuffer[i] - resultado * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[i] = regBuffer[i] - resultado * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel11[i] = regBuffer[i] - resultado * ((11 + DeviationsOffset) * ChannelWidth);
         downChannel12[i] = regBuffer[i] - resultado * ((12 + DeviationsOffset) * ChannelWidth);
         downChannel13[i] = regBuffer[i] - resultado * ((13 + DeviationsOffset) * ChannelWidth);
         downChannel14[i] = regBuffer[i] - resultado * ((14 + DeviationsOffset) * ChannelWidth);
         downChannel15[i] = regBuffer[i] - resultado * ((15 + DeviationsOffset) * ChannelWidth);
         downChannel16[i] = regBuffer[i] - resultado * ((16 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 15) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[i] = regBuffer[i] + resultado * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[i] = regBuffer[i] + resultado * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[i] = regBuffer[i] + resultado * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[i] = regBuffer[i] + resultado * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[i] = regBuffer[i] + resultado * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[i] = regBuffer[i] + resultado * ((10 + DeviationsOffset) * ChannelWidth);
         upChannel11[i] = regBuffer[i] + resultado * ((11 + DeviationsOffset) * ChannelWidth);
         upChannel12[i] = regBuffer[i] + resultado * ((12 + DeviationsOffset) * ChannelWidth);
         upChannel13[i] = regBuffer[i] + resultado * ((13 + DeviationsOffset) * ChannelWidth);
         upChannel14[i] = regBuffer[i] + resultado * ((14 + DeviationsOffset) * ChannelWidth);
         upChannel15[i] = regBuffer[i] + resultado * ((15 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[i] = regBuffer[i] - resultado * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[i] = regBuffer[i] - resultado * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[i] = regBuffer[i] - resultado * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[i] = regBuffer[i] - resultado * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[i] = regBuffer[i] - resultado * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[i] = regBuffer[i] - resultado * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel11[i] = regBuffer[i] - resultado * ((11 + DeviationsOffset) * ChannelWidth);
         downChannel12[i] = regBuffer[i] - resultado * ((12 + DeviationsOffset) * ChannelWidth);
         downChannel13[i] = regBuffer[i] - resultado * ((13 + DeviationsOffset) * ChannelWidth);
         downChannel14[i] = regBuffer[i] - resultado * ((14 + DeviationsOffset) * ChannelWidth);
         downChannel15[i] = regBuffer[i] - resultado * ((15 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 14) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[i] = regBuffer[i] + resultado * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[i] = regBuffer[i] + resultado * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[i] = regBuffer[i] + resultado * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[i] = regBuffer[i] + resultado * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[i] = regBuffer[i] + resultado * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[i] = regBuffer[i] + resultado * ((10 + DeviationsOffset) * ChannelWidth);
         upChannel11[i] = regBuffer[i] + resultado * ((11 + DeviationsOffset) * ChannelWidth);
         upChannel12[i] = regBuffer[i] + resultado * ((12 + DeviationsOffset) * ChannelWidth);
         upChannel13[i] = regBuffer[i] + resultado * ((13 + DeviationsOffset) * ChannelWidth);
         upChannel14[i] = regBuffer[i] + resultado * ((14 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[i] = regBuffer[i] - resultado * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[i] = regBuffer[i] - resultado * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[i] = regBuffer[i] - resultado * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[i] = regBuffer[i] - resultado * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[i] = regBuffer[i] - resultado * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[i] = regBuffer[i] - resultado * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel11[i] = regBuffer[i] - resultado * ((11 + DeviationsOffset) * ChannelWidth);
         downChannel12[i] = regBuffer[i] - resultado * ((12 + DeviationsOffset) * ChannelWidth);
         downChannel13[i] = regBuffer[i] - resultado * ((13 + DeviationsOffset) * ChannelWidth);
         downChannel14[i] = regBuffer[i] - resultado * ((14 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 13) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[i] = regBuffer[i] + resultado * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[i] = regBuffer[i] + resultado * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[i] = regBuffer[i] + resultado * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[i] = regBuffer[i] + resultado * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[i] = regBuffer[i] + resultado * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[i] = regBuffer[i] + resultado * ((10 + DeviationsOffset) * ChannelWidth);
         upChannel11[i] = regBuffer[i] + resultado * ((11 + DeviationsOffset) * ChannelWidth);
         upChannel12[i] = regBuffer[i] + resultado * ((12 + DeviationsOffset) * ChannelWidth);
         upChannel13[i] = regBuffer[i] + resultado * ((13 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[i] = regBuffer[i] - resultado * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[i] = regBuffer[i] - resultado * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[i] = regBuffer[i] - resultado * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[i] = regBuffer[i] - resultado * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[i] = regBuffer[i] - resultado * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[i] = regBuffer[i] - resultado * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel11[i] = regBuffer[i] - resultado * ((11 + DeviationsOffset) * ChannelWidth);
         downChannel12[i] = regBuffer[i] - resultado * ((12 + DeviationsOffset) * ChannelWidth);
         downChannel13[i] = regBuffer[i] - resultado * ((13 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 12) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[i] = regBuffer[i] + resultado * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[i] = regBuffer[i] + resultado * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[i] = regBuffer[i] + resultado * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[i] = regBuffer[i] + resultado * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[i] = regBuffer[i] + resultado * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[i] = regBuffer[i] + resultado * ((10 + DeviationsOffset) * ChannelWidth);
         upChannel11[i] = regBuffer[i] + resultado * ((11 + DeviationsOffset) * ChannelWidth);
         upChannel12[i] = regBuffer[i] + resultado * ((12 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[i] = regBuffer[i] - resultado * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[i] = regBuffer[i] - resultado * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[i] = regBuffer[i] - resultado * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[i] = regBuffer[i] - resultado * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[i] = regBuffer[i] - resultado * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[i] = regBuffer[i] - resultado * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel11[i] = regBuffer[i] - resultado * ((11 + DeviationsOffset) * ChannelWidth);
         downChannel12[i] = regBuffer[i] - resultado * ((12 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 11) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[i] = regBuffer[i] + resultado * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[i] = regBuffer[i] + resultado * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[i] = regBuffer[i] + resultado * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[i] = regBuffer[i] + resultado * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[i] = regBuffer[i] + resultado * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[i] = regBuffer[i] + resultado * ((10 + DeviationsOffset) * ChannelWidth);
         upChannel11[i] = regBuffer[i] + resultado * ((11 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[i] = regBuffer[i] - resultado * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[i] = regBuffer[i] - resultado * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[i] = regBuffer[i] - resultado * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[i] = regBuffer[i] - resultado * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[i] = regBuffer[i] - resultado * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[i] = regBuffer[i] - resultado * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel11[i] = regBuffer[i] - resultado * ((11 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 10) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[i] = regBuffer[i] + resultado * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[i] = regBuffer[i] + resultado * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[i] = regBuffer[i] + resultado * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[i] = regBuffer[i] + resultado * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[i] = regBuffer[i] + resultado * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[i] = regBuffer[i] + resultado * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[i] = regBuffer[i] - resultado * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[i] = regBuffer[i] - resultado * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[i] = regBuffer[i] - resultado * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[i] = regBuffer[i] - resultado * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[i] = regBuffer[i] - resultado * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[i] = regBuffer[i] - resultado * ((10 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 9) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[i] = regBuffer[i] + resultado * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[i] = regBuffer[i] + resultado * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[i] = regBuffer[i] + resultado * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[i] = regBuffer[i] + resultado * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[i] = regBuffer[i] + resultado * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[i] = regBuffer[i] - resultado * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[i] = regBuffer[i] - resultado * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[i] = regBuffer[i] - resultado * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[i] = regBuffer[i] - resultado * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[i] = regBuffer[i] - resultado * ((9 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 8) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[i] = regBuffer[i] + resultado * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[i] = regBuffer[i] + resultado * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[i] = regBuffer[i] + resultado * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[i] = regBuffer[i] + resultado * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[i] = regBuffer[i] - resultado * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[i] = regBuffer[i] - resultado * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[i] = regBuffer[i] - resultado * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[i] = regBuffer[i] - resultado * ((8 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 7) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[i] = regBuffer[i] + resultado * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[i] = regBuffer[i] + resultado * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[i] = regBuffer[i] + resultado * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[i] = regBuffer[i] - resultado * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[i] = regBuffer[i] - resultado * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[i] = regBuffer[i] - resultado * ((7 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 6) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[i] = regBuffer[i] + resultado * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[i] = regBuffer[i] + resultado * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[i] = regBuffer[i] - resultado * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[i] = regBuffer[i] - resultado * ((6 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 5) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[i] = regBuffer[i] + resultado * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[i] = regBuffer[i] - resultado * ((5 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 4) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[i] = regBuffer[i] + resultado * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[i] = regBuffer[i] - resultado * ((4 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 3) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[i] = regBuffer[i] + resultado * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[i] = regBuffer[i] - resultado * ((3 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 2) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[i] = regBuffer[i] + resultado * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[i] = regBuffer[i] - resultado * ((2 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 1) {
         upChannel1[i] = regBuffer[i] + resultado * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel1[i] = regBuffer[i] - resultado * ((1 + DeviationsOffset) * ChannelWidth);
      }
   }

   return 1;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define KEY_RIGHT   68
#define KEY_LEFT  65
#define KEY_PLUS   107
#define KEY_MINUS  109

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {

   if(id == CHARTEVENT_OBJECT_DRAG) {
      if((sparam == _timeFromLine) || (sparam == _timeToLine))
         //Update();
         _lastOK = false;
      CheckTimer();
   }

   static bool keyPressed = false;
   int barraLimite, barraNova, barraFrom, barraTo, primeiraBarraVisivel, ultimaBarraVisivel, ultimaBarraSerie;
   datetime tempoTimeFrom, tempoTimeTo, tempoBarra0, tempoUltimaBarraSerie;

   if(id == CHARTEVENT_KEYDOWN) {
      if(lparam == KEY_RIGHT || lparam == KEY_LEFT) {
         if(!keyPressed)
            keyPressed = true;
         else
            keyPressed = false;

         // definição das variáveis comuns
         if ((ObjectGetInteger(0, _timeToLine, OBJPROP_SELECTED) == true) || (ObjectGetInteger(0, _timeFromLine, OBJPROP_SELECTED) == true)) {
            totalCandles = Bars(_Symbol, PERIOD_CURRENT);
            ultimaBarraSerie = totalCandles - 1;
            ultimaBarraVisivel = WindowFirstVisibleBar();
            barraFrom = iBarShift(_Symbol, PERIOD_CURRENT, ObjectGetInteger(0, _timeFromLine, OBJPROP_TIME));
            barraTo = iBarShift(_Symbol, PERIOD_CURRENT, ObjectGetInteger(0, _timeToLine, OBJPROP_TIME));
            tempoTimeFrom = GetObjectTime1(_timeFromLine);
            tempoTimeTo = GetObjectTime1(_timeToLine);
            tempoBarra0 = iTime(_Symbol, PERIOD_CURRENT, 0);

            tempoUltimaBarraSerie = iTime(_Symbol, PERIOD_CURRENT, totalCandles - 1);
         }
      }

      switch(int(lparam))  {
      case KEY_RIGHT: {
         if (ObjectGetInteger(0, _timeToLine, OBJPROP_SELECTED) == true) {
            if (barraFrom <= primeiraBarraVisivel)
               barraLimite = barraFrom;
            else
               barraLimite = primeiraBarraVisivel;

            barraNova = barraTo - 1;
            if (barraNova >= 0) {
               datetime tempoNovo = iTime(_Symbol, PERIOD_CURRENT, barraNova);
               ObjectSetInteger(0, _timeToLine, OBJPROP_TIME, 0, tempoNovo);
               timeTo = tempoNovo;
               _lastOK = false;
               CheckTimer();
            } else if (barraNova < 0) {
               datetime tempoNovo = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT);
               ObjectSetInteger(0, _timeToLine, OBJPROP_TIME, 0, tempoNovo);
               timeTo = tempoNovo;
               _lastOK = false;
               CheckTimer();
            }
         }

         if (ObjectGetInteger(0, _timeFromLine, OBJPROP_SELECTED) == true) {
            barraLimite = 0;
            if (barraTo >= 0)
               barraLimite = barraTo;

            barraNova = barraFrom - 1;
            if (barraNova > barraLimite) {
               datetime tempoNovo = iTime(_Symbol, PERIOD_CURRENT, barraNova);
               ObjectSetInteger(0, _timeFromLine, OBJPROP_TIME, 0, tempoNovo);
               timeFrom = tempoNovo;
               _lastOK = false;
               CheckTimer();
            }
         }


      }
      break;

      case KEY_LEFT:  {
         if (ObjectGetInteger(0, _timeToLine, OBJPROP_SELECTED) == true) {
            barraTo = iBarShift(_Symbol, PERIOD_CURRENT, ObjectGetInteger(0, _timeToLine, OBJPROP_TIME));
            if (tempoTimeTo <= tempoUltimaBarraSerie) {
               barraNova = 0;
            } else {
               if (tempoTimeTo > tempoBarra0) {
                  barraNova = 0;
               } else {
                  barraNova = barraTo + 1;
               }
            }

            datetime tempoNovo = iTime(_Symbol, PERIOD_CURRENT, barraNova);
            ObjectSetInteger(0, _timeToLine, OBJPROP_TIME, 0, tempoNovo);
            timeTo = tempoNovo;
            _lastOK = false;
            CheckTimer();
         }

         if (ObjectGetInteger(0, _timeFromLine, OBJPROP_SELECTED) == true) {
            if (tempoTimeFrom <= tempoUltimaBarraSerie)
               barraNova = barraFrom;
            else
               barraNova = barraFrom + 1;

            barraLimite = ultimaBarraSerie;

            if (barraNova < barraLimite) {
               datetime tempoNovo = iTime(_Symbol, PERIOD_CURRENT, barraNova);
               ObjectSetInteger(0, _timeFromLine, OBJPROP_TIME, 0, tempoNovo);
               timeFrom = tempoNovo;
               _lastOK = false;
               CheckTimer();
            }
         }
      }
      break;
      }

   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//Linear Regression Calculation for sample data: arr[]
//line equation  y = f(x)  = ax + b
void CalcAB(const double& arr[], int start, int end, double& a, double& b) {

   a = 0.0;
   b = 0.0;
   int size = MathAbs(start - end) + 1;
   if(size < 2)
      return;

   double sumxy = 0.0, sumx = 0.0, sumy = 0.0, sumx2 = 0.0;
   for(int i = start; i >= end; i--) {
      sumxy += i * arr[i];
      sumy += arr[i];
      sumx += i;
      sumx2 += i * i;
   }

   double M = size * sumx2 - sumx * sumx;
   if(M == 0.0)
      return;

   a = (size * sumxy - sumx * sumy) / M;
   b = (sumy - a * sumx) / size;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetStdDev(const double &arr[], int start, int end) {
   int size = MathAbs(start - end) + 1;
   if(size < 2)
      return(0.0);

   double sum = 0.0;
   for(int i = start; i >= end; i--) {
      sum = sum + arr[i];
   }

   sum = sum / size;

   double sum2 = 0.0;
   for(int i = start; i >= end; i--) {
      sum2 = sum2 + (arr[i] - sum) * (arr[i] - sum);
   }

   sum2 = sum2 / (size - 1);
   sum2 = MathSqrt(sum2);

   return(sum2);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime GetObjectTime1(const string name) {
   datetime time;

   if(!ObjectGetInteger(0, name, OBJPROP_TIME, 0, time))
      return(0);

   return(time);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime GetBarTime(const int shift, ENUM_TIMEFRAMES period = PERIOD_CURRENT) {
   if(shift >= 0)
      return(miTime(_Symbol, period, shift));
   else
      return(miTime(_Symbol, period, 0) - shift * PeriodSeconds(period));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GetRangeBars(const datetime ptimeFrom, const datetime ptimeTo, int &barFrom, int &barTo) {
   barFrom = GetTimeBarRight(ptimeFrom);
   barTo = GetTimeBarRight(ptimeTo);
   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetTimeBarRight(datetime time, ENUM_TIMEFRAMES period = PERIOD_CURRENT) {
   int bar = miBarShift(_Symbol, period, time);
   datetime t = miTime(_Symbol, period, bar);

   if((t != time) && (bar == 0)) {
      bar = (int)((miTime(_Symbol, period, 0) - time) / PeriodSeconds(period));
   } else {
      if(t < time)
         bar--;
   }

   return(bar);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int miBarShift(string symbol, ENUM_TIMEFRAMES timeframe, datetime time, bool exact = false) {
   if(time < 0)
      return(-1);

   datetime arr[];
   datetime time1;
   CopyTime(symbol, timeframe, 0, 1, arr);
   time1 = arr[0];

   if(CopyTime(symbol, timeframe, time, time1, arr) <= 0)
      return(-1);

   if(ArraySize(arr) > 2)
      return(ArraySize(arr) - 1);

   return(time < time1 ? 1 : 0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int WindowBarsPerChart() {
   return((int)ChartGetInteger(0, CHART_WIDTH_IN_BARS));
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int WindowFirstVisibleBar() {
   return((int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawVLine(const string name, const datetime time1, const color lineColor, const int width, const int style, const bool back = true, const bool hidden = true, const bool selectable = false, const int zorder = 0) {
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_VLINE, 0, time1, 0);
   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_BACK, back);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, hidden);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zorder);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime miTime(string symbol, ENUM_TIMEFRAMES timeframe, int index) {
   if(index < 0)
      return(-1);

   datetime arr[];

   if(CopyTime(symbol, timeframe, index, 1, arr) <= 0)
      return(-1);

   return(arr[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectEnable(const long chartId, const string name) {
   ObjectSetInteger(chartId, name, OBJPROP_HIDDEN, false);
   ObjectSetInteger(chartId, name, OBJPROP_SELECTABLE, true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectDisable(const long chartId, const string name) {
   ObjectSetInteger(chartId, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(chartId, name, OBJPROP_SELECTABLE, false);
}

template<typename T>
void Swap(T &value1, T &value2) {
   T tmp = value1;
   value1 = value2;
   value2 = tmp;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {
 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      _lastOK = Update();

      if(!_lastOK)
         EventSetTimer(3);

      ChartRedraw(0);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool _lastOK = false;
MillisecondTimer *_updateTimer;
//+------------------------------------------------------------------+
