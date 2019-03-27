//+------------------------------------------------------------------+
//|                                                    HMAPivots.mq4 |
//|                                                 Michael Fishman. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Michael Fishman."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

enum BuySell{
   Buy= OP_BUY,
   Sell= OP_SELL
};

enum YesNo{
   No=0,
   Yes=1
};

enum PivotLabels{
   S3=0,
   S2=1,
   S1=2,
   Pivot=3,
   R1=4,
   R2=5,
   R3=6
};

enum HMAColors{
   HMABlue=0,
   HMARed=1,
   HMABoth=2 //Current moment on indicator contains both fields. Direction changing
};

input int HMAPeriods = 21; //HMAPeriods
input ENUM_MA_METHOD HMAMethod = MODE_SMA;
input ENUM_APPLIED_PRICE HMAPrice=PRICE_CLOSE;

input int PivotsGMTShift = 0;
input int PivotRange = 10;
input PivotLabels PivotLevel = Pivot;

input int MagicNumber = 12345;

input double LotSize =0.01;
input int TakeProfit = 20;
input int PipProfit = 40;

string pivotsFilePath="Mike\\gStdPivots";
string hmaFilePath="Mike\\HMA_Russian_Color";
double usePoint;
int ticket=0;

bool tktOpened = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(Digits()==2 || Digits()==3) usePoint=0.01;
   if(Digits()==4 || Digits()==5) usePoint=0.0001;

      
//--- create timer
   //EventSetTimer(60);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

      double selectedPivotRate = iCustom(NULL, 0, pivotsFilePath, PivotsGMTShift, clrGreen,clrRed, 10,20,PivotLevel,0);
      DPrint("OnTick SelectedPivotLvl: "+selectedPivotRate);      

      double s3Rate = iCustom(NULL, 0, pivotsFilePath, PivotsGMTShift, clrGreen,clrRed, 10,20,S3,0);
      DPrint("OnTick S3Rate: "+s3Rate);      

      double s2Rate = iCustom(NULL, 0, pivotsFilePath, PivotsGMTShift, clrGreen,clrRed, 10,20,S2,0);
      DPrint("OnTick S12Rate: "+s2Rate);
      
      double s1Rate = iCustom(NULL, 0, pivotsFilePath, PivotsGMTShift, clrGreen,clrRed, 10,20,S1,0);
      DPrint("OnTick S1Rate: "+s1Rate);
      
      double pivotRate = iCustom(NULL, 0, pivotsFilePath, PivotsGMTShift, clrGreen,clrRed, 10,20,Pivot,0);
      DPrint("OnTick pivotRate: "+pivotRate);

      double r1Rate = iCustom(NULL, 0, pivotsFilePath, PivotsGMTShift, clrGreen,clrRed, 10,20,R1,0);
      DPrint("OnTick R3Rate: "+r1Rate);

      double r2Rate = iCustom(NULL, 0, pivotsFilePath, PivotsGMTShift, clrGreen,clrRed, 10,20,R2,0);
      DPrint("OnTick R3Rate: "+r2Rate);

      double r3Rate = iCustom(NULL, 0, pivotsFilePath, PivotsGMTShift, clrGreen,clrRed, 10,20,R3,0);
      DPrint("OnTick R3Rate: "+r3Rate);

      double hmaBlue = iCustom(NULL, 0, hmaFilePath, HMAPeriods, HMAMethod, HMAPrice, HMABlue,0);
      DPrint("OnTick HMABlue: "+hmaBlue);
      
      double hmaRed = iCustom(NULL, 0, hmaFilePath, HMAPeriods, HMAMethod, HMAPrice, HMARed,0);
      DPrint("OnTick HMARed: "+hmaRed);

      
      HMAColors hma = GetCurrentHMAColor(hmaBlue,hmaRed);
      
      if (hma==HMABlue){
         HandleHMABlue(selectedPivotRate);
      } else if(hma==HMARed) {
         HandleHMARed(selectedPivotRate);
      }
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Determine if current HMA line is Blue or Red        
//| Input variables are those queried from the indicator                                         |
//+------------------------------------------------------------------+
HMAColors GetCurrentHMAColor(double hmaBlueCurrent, double hmaRedCurrent){
   if (hmaBlueCurrent!=INT_MAX && hmaRedCurrent!=INT_MAX){
      return HMABoth;  //Does nothing.  We are at time where HMA changes direction/color
   }
   
   if (hmaBlueCurrent!=INT_MAX && hmaRedCurrent==INT_MAX){
      Print("Ret Blue");
      return HMABlue;
   }
   
   if (hmaRedCurrent!=INT_MAX && hmaBlueCurrent==INT_MAX){
      Print("Ret Red");
      return HMARed;
   }
   
   //Handle if both fields are INT_MAX? both not found? not sure if this is possible...
   return -1;
}


//+------------------------------------------------------------------+
//| Entry Order placement to open ticket with a buy via HMA - Blue line                                                  |
//+------------------------------------------------------------------+
void PlaceEntryOrderBuy(){//double entryRate, BuySell buySell, double stoploss){
         //Place entry
   double lstClsdCndlHigh = High[1]; //Used as open rate on entry order
   double lstClsdCndlLow = Low[1];   //Used as stop loss on entry order  

  if(tktOpened){
   //Print("Already Opened Order");
   return;
  }
  
  
  double normalizedEntryRate = NormalizeDouble(lstClsdCndlHigh,Digits);
  double normalizedStopLoss = NormalizeDouble(lstClsdCndlLow,Digits);
  double normalizedTakeProfit = CalculateLongOrderTakeProfit(normalizedEntryRate);
  int OpType = normalizedEntryRate > Ask ? OP_BUYSTOP : OP_BUYLIMIT;
 
  double slippage=10;
  ticket=0;
   ticket=OrderSend(Symbol(),OpType,LotSize,normalizedEntryRate,slippage,normalizedStopLoss,normalizedTakeProfit,"MN:"+MagicNumber,MagicNumber,0,clrGreen);
   if(ticket<0)
     {
      Print("OrderSend failed with error #",GetLastError());
     }
   else {
      Print("OrderSend placed successfully");
      tktOpened=true;
      }

}

double CalculateLongOrderTakeProfit(double orderRate){
   double takeProfit = NormalizeDouble(orderRate+(TakeProfit*usePoint),Digits);
   return takeProfit;
}



//+------------------------------------------------------------------+
//| Validation check for HMABlue condition
//+------------------------------------------------------------------+
bool LastClosedCandleOpenGreaterThenClosePrice(){
   double lstClsdCndlOpen = Open[1];
   double clsPrice = Close[0];
   if(lstClsdCndlOpen > clsPrice){
      return true;
   } else {
      Print("Failed last Closed Cndle Open > clsPrice");
      Print(lstClsdCndlOpen+" > "+clsPrice);
      return false;
   }
}

//+------------------------------------------------------------------+
//| Validation check for HMABlue condition
//+------------------------------------------------------------------+
bool PrevLastClosedCandleOpenGreaterThenClosePrice(){
   double prvToLstCandlOpen = Open[2];
   double clsPrice = Close[0];
      
   if(prvToLstCandlOpen > clsPrice){
      return true;
   } else {
      Print("Failed Prev to Last Candle Open > clsPrice");
      Print(prvToLstCandlOpen+" > "+clsPrice);
      return false;
   }
}

void HandleHMABlue(double pivotRate){
   Print("Doing Blue logic");
   double currClose = Close[0];
   double prevClose = Close[1];
      
   if (ValidateClosePriceVsPivotLvlRange(PivotLevel, pivotRate, PivotRange)){
      if (LastClosedCandleOpenGreaterThenClosePrice()){
          if(PrevLastClosedCandleOpenGreaterThenClosePrice() ){
            PlaceEntryOrderBuy();
         }
       } 
   } 
}


double CalculateShortOrderTakeProfit(double orderRate){
   double takeProfit = NormalizeDouble(orderRate-(TakeProfit*usePoint),Digits);
   return takeProfit;
}


//--------------
//+------------------------------------------------------------------+
//| Entry Order placement to open ticket with a Sell via HMA - Ren line                                                  |
//+------------------------------------------------------------------+
void PlaceEntryOrderSell(){//double entryRate, BuySell buySell, double stoploss){
         //Place entry
   double lstClsdCndlLow = Low[1];   //Used as open rate on entry order  
   double lstClsdCndlHigh = High[1]; //Used as stop loss on entry order

  if(tktOpened){
   //Print("Already Opened Order");
   return;
  }
  
  
  double normalizedEntryRate = NormalizeDouble(lstClsdCndlLow,Digits);
  double normalizedStopLoss = NormalizeDouble(lstClsdCndlHigh,Digits);
  double normalizedTakeProfit = CalculateShortOrderTakeProfit(normalizedEntryRate);
  int OpType = normalizedEntryRate > Bid ? OP_BUYSTOP : OP_BUYLIMIT;
 
  double slippage=10;
  ticket=0;
   ticket=OrderSend(Symbol(),OpType,LotSize,normalizedEntryRate,slippage,normalizedStopLoss,normalizedTakeProfit,"MN:"+MagicNumber,MagicNumber,0,clrGreen);
   if(ticket<0)
     {
      Print("OrderSend failed with error #",GetLastError());
     }
   else {
      Print("OrderSend placed successfully");
      tktOpened=true;
      }

}

//+------------------------------------------------------------------+
//| Validation check for HMARed condition
//+------------------------------------------------------------------+
bool LastClosedCandleOpenLessThenClosePrice(){
   double lstClsdCndlOpen = Open[1];
   double clsPrice = Close[0];
   if(lstClsdCndlOpen < clsPrice){
      return true;
   } else {
      Print("Failed last Closed Cndle Open < clsPrice");
      Print(lstClsdCndlOpen+" < "+clsPrice);
      return false;
   }
}

//+------------------------------------------------------------------+
//| Validation check for HMARed condition
//+------------------------------------------------------------------+
bool PrevLastClosedCandleOpenLessThenClosePrice(){
   double prvToLstCandlOpen = Open[2];
   double clsPrice = Close[0];
      
   if(prvToLstCandlOpen < clsPrice){
      return true;
   } else {
      Print("Failed Prev to Last Candle Open < clsPrice");
      Print(prvToLstCandlOpen+" < "+clsPrice);
      return false;
   }
}


void HandleHMARed(double pivotRate){
   DPrint("Doing Red logic");

   if (ValidateClosePriceVsPivotLvlRange(PivotLevel, pivotRate, PivotRange)){
      if (LastClosedCandleOpenLessThenClosePrice()){
          if(PrevLastClosedCandleOpenLessThenClosePrice() ){
            PlaceEntryOrderSell();
         }
       } 
   } 

}



//+------------------------------------------------------------------+
//| Initial validation check of algorithm.  Used for both HMA conditions                                                  |
//+------------------------------------------------------------------+
bool ValidateClosePriceVsPivotLvlRange(int pivotLvl, double pivotVal, double pipRange){
   bool ret = false;
   double closePriceLastCandl = Close[0]; //Assuming last candle = current candle?
   double openThresholdPlus = pivotVal+(pipRange*usePoint);
   double openThresholdNeg = pivotVal-(pipRange*usePoint);

   DPrint(__FUNCTION__"PipMagic:"+pipRange*usePoint);
   DPrint(__FUNCTION__"closePriceLastCandl:" +closePriceLastCandl);
   DPrint(__FUNCTION__"--:--"+pivotVal+"--:--"+pipRange);
   DPrint(__FUNCTION__":: "+openThresholdPlus+"--:--"+openThresholdNeg);
   
   if (closePriceLastCandl > openThresholdPlus){
      DPrint(__FUNCTION__"CloseLastCandl Greater then pivot range");
      ret = true;
   } else if (closePriceLastCandl < openThresholdNeg){
      DPrint(__FUNCTION__"CloseLastCandl Less then pivot range");
      ret = true;
   }

   if(!ret){
      DPrint(__FUNCTION__" Failed Validate Close Price Vs Pivot Lvl Range");
      DPrint(__FUNCTION__" "+closePriceLastCandl + " vs " + pivotVal + ". PipRange="+pipRange);
      DPrint(__FUNCTION__" "+closePriceLastCandl + " > " + openThresholdPlus + ". PipRange="+pipRange);
      DPrint(__FUNCTION__" "+closePriceLastCandl + " < " + openThresholdNeg + ". PipRange="+pipRange);
      
   }
   DPrint(__FUNCTION__+"- Returning: "+ret);
   return ret;
}







bool debug=true;
void DPrint(string str){
   if(debug)
    Print(str);
}