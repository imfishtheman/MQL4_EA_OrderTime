//+------------------------------------------------------------------+
//|                                                    HMAPivots.mq4 |
//|                                                 Michael Fishman. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Michael Fishman."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


string pivotsFilePath="gStdPivots";
string hmaFilePath="HMA_Russian_Color";

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
 
//The current rate market must breach to force an update on StopLoss
double trailStopDependentRate=0;

double usePoint;
int ticket=0;


bool entryOrdPlaced = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!MagicNumberValidator()){
   return (INIT_PARAMETERS_INCORRECT);
   }
   

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
      HandlePositionClosed();
      doTrailingStop(ticket);
      
      
      if(entryOrdPlaced){
         Comment("Position opened. EA Still in testing mode");
         return;
      }
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
      return HMABlue;
   }
   
   if (hmaRedCurrent!=INT_MAX && hmaBlueCurrent==INT_MAX){
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

  if(entryOrdPlaced){
   return;
  }
  
  
  double normalizedEntryRate = NormalizeDouble(lstClsdCndlHigh,Digits);
  double normalizedStopLoss = NormalizeDouble(lstClsdCndlLow,Digits);
  double normalizedTakeProfit = CalculateLongOrderTakeProfit(normalizedEntryRate);
  int OpType = normalizedEntryRate > Ask ? OP_BUYSTOP : OP_BUYLIMIT;
 
  double slippage=10;
  ticket=0;
   ticket=OrderSend(Symbol(),OpType,LotSize,normalizedEntryRate,slippage,normalizedStopLoss,normalizedTakeProfit,"MN:"+MagicNumber,MagicNumber,0,clrGreen);
   if(ticket<=0)
     {
      Print("OrderSend failed with error #",GetLastError());
     }
   else {
      Print("OrderSend placed successfully");
      entryOrdPlaced=true;
      
      //Set initial Trailing Stop Dependency
//      trailStopDependentRate = normalizedEntryRate-(PipProfit*usePoint);
//      Print("Initial TrailStopDependentRate: "+trailStopDependentRate);
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
   if(debug){
      return true;
   }
   
   double lstClsdCndlOpen = Open[1];
   double clsPrice = Close[1];
   if(lstClsdCndlOpen > clsPrice){
      return true;
   } else {
      DPrint("Failed last Closed Cndle Open > clsPrice");
      DPrint(lstClsdCndlOpen+" > "+clsPrice);
      return false;
   }
}

//+------------------------------------------------------------------+
//| Validation check for HMABlue condition
//+------------------------------------------------------------------+
bool PrevLastClosedCandleOpenGreaterThenClosePrice(){
   if(debug){
      return true;
   }
   
   double prvToLstCandlOpen = Open[2];
   double clsPrice = Close[2];
      
   if(prvToLstCandlOpen > clsPrice){
      return true;
   } else {
      DPrint("Failed Prev to Last Candle Open > clsPrice");
      DPrint(prvToLstCandlOpen+" > "+clsPrice);
      return false;
   }
}

void HandleHMABlue(double pivotRate){
   //Print("Doing Blue logic");
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


  if(entryOrdPlaced){
   //Print("Already Opened Order");
   return;
  }
  
  
  double normalizedEntryRate = NormalizeDouble(lstClsdCndlLow,Digits);
  double normalizedStopLoss = NormalizeDouble(lstClsdCndlHigh,Digits);
  double normalizedTakeProfit = CalculateShortOrderTakeProfit(normalizedEntryRate);
  int OpType = normalizedEntryRate < Bid ? OP_SELLSTOP : OP_SELLLIMIT;
 
  DPrint("PlacingOrder OPType:"+OpType+", Rt:"+normalizedEntryRate+", SL:"+normalizedStopLoss);
  double slippage=10;
  ticket=0;
  //Placing our Pending Order
   ticket=OrderSend(Symbol(),OpType,LotSize,normalizedEntryRate,slippage,normalizedStopLoss,normalizedTakeProfit,"MN:"+MagicNumber,MagicNumber,0,clrGreen);
   if(ticket<=0)
     {
      Print("OrderSend failed with error #",GetLastError());
     }
   else {
      Print("OrderSend placed successfully");
      entryOrdPlaced=true;
      //Set initial Trailing Stop Dependency
//      trailStopDependentRate = normalizedEntryRate+(TakeProfit*usePoint);
//      Print("Initial TrailStopDependentRate: "+trailStopDependentRate);
      }

}

//+------------------------------------------------------------------+
//| Validation check for HMARed condition
//+------------------------------------------------------------------+
bool LastClosedCandleOpenLessThenClosePrice(){
   if(debug){
      return true;
   }

   double lstClsdCndlOpen = Open[1];
   double clsPrice = Close[1];
   if(lstClsdCndlOpen < clsPrice){
      return true;
   } else {
      DPrint("Failed last Closed Cndle Open < clsPrice");
      DPrint(lstClsdCndlOpen+" < "+clsPrice);
      return false;
   }
}

//+------------------------------------------------------------------+
//| Validation check for HMARed condition
//+------------------------------------------------------------------+
bool PrevLastClosedCandleOpenLessThenClosePrice(){
   if(debug){
      return true;
   }
   
   double prvToLstCandlOpen = Open[2];
   double clsPrice = Close[2];
      
   if(prvToLstCandlOpen < clsPrice){
      return true;
   } else {
      DPrint("Failed Prev to Last Candle Open < clsPrice");
      DPrint(prvToLstCandlOpen+" < "+clsPrice);
      return false;
   }
}


void HandleHMARed(double pivotRate){
   //DPrint("Doing Red logic");

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


void doTrailingStop(int ticket){ 
   
   bool found = OrderSelect(ticket, SELECT_BY_TICKET);
/*
   if (found){
   //Print(__FUNCTION__" Order was found");
     //Don't do trailing stop if no stoploss value is set
      if (OrderStopLoss()==0){
       // Print("Invalid trailing stop param, No stoploss detected");
        return; 
        }  
        //Print(__FUNCTION__" Optype:"+OrderType());
        //Return if Order is still in pending state
      if ( !(OrderType()==OP_BUY || OrderType()==OP_SELL)){
         
        return; 
      }
   } 
*/
   if (!found){
      //Print(__FUNCTION__+" ticketn not found");
      return;
   }
   
   if ( !(OrderType()==OP_BUY || OrderType()==OP_SELL)){
      //Print(__FUNCTION__+" ticket not open yet");
       
        return;
   }
   
   
   //int longShortType= OrderType();
   //double currentSL = OrderStopLoss();
   

   //Check if new market rate is better then previous best market rate(last rate that caused stoploss to move via trailing update)
   double newMarketRate = OrderType()==OP_BUY ? Bid : Ask;
   
   //Initialize the dependent rate first time
   if(trailStopDependentRate==0){
      trailStopDependentRate=newMarketRate;
      Print("Initialized primary trailStopDepRate: "+trailStopDependentRate);
      return;
   }
   
   double diff = getDifference(trailStopDependentRate, newMarketRate, OrderType());
   
   if (diff <= 0 ){
      DPrint("Negative market movemnt, do not update sl");
      DPrint("OldMktRate: "+trailStopDependentRate);
      DPrint("NewMktRate: "+newMarketRate);

      //Market didn't get better than last best rate, ignore
      return;
   }
   
   DPrint("TrailStop Prep");
   Print("OldMktRate: "+trailStopDependentRate);
   Print("NewMktRate: "+newMarketRate);
   DPrint("DIff: " + diff);
   
   double newSL = OrderStopLoss();
   
   DPrint("OrigSL: "+OrderStopLoss());
   if (OrderType()==OP_BUY){
      newSL+=diff;
   } else{
      newSL-=diff;
   }

   
   bool res = OrderModify(ticket,OrderOpenPrice(),NormalizeDouble(newSL,Digits),OrderTakeProfit(),0,clrGreen);
   if(!res){
     Print("ModifyParams, OldSL:"+OrderStopLoss()+", NewSL:"+newSL);
     Print("Error in OrderModify (TrailStop). Error code=",GetLastError());
     Print("Diff: "+diff);
     }
   else{
     Print("Order modified (TrailStop Updated) successfully.");
     trailStopDependentRate = newMarketRate;
     Print("Diff: "+diff);
   }
} 

//get difference between 2 prices,  with correct sign depending on long/short/order type
double getDifference(double oldRate, double newRate, int orderType){
   double diff=oldRate-newRate;

   //Buy orders, difference direction should be swapped. newRate being higher is a good thing
   if (orderType==OP_BUY){ 
        diff*=-1;
   } 
   
   return diff;
}


void HandlePositionClosed(){

   if (ticket!=0){
      bool found = OrderSelect(ticket, SELECT_BY_TICKET);
      if (!found || OrderCloseTime()!=0){
         ticket=0;
         entryOrdPlaced=false;
         trailStopDependentRate=0;
      }
    }
}

bool MagicNumberValidator(){
   int total = OrdersTotal();
   for (int i=0; i< OrdersTotal(); i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
        if(MagicNumber== OrderMagicNumber()){
         Print("EA already has ticket opened with specified Magic Number");
         return false;
        }
   }
   
   return true;
}


bool debug=false;
void DPrint(string str){
   if(debug)
    Print(str);
}
