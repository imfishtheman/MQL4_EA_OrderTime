//+------------------------------------------------------------------+
//|                                                        Test4.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
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
  
extern datetime EntryTime = D'2019.03.01 00:00'; //Entry Time 
extern BuySell buySell = Buy; //Buy or Sell
extern double lots =0.01; //Lots
extern int stopLossPips = 0; //Stop Loss in Pips
extern bool trailingStopFlag = false; //Trailing Stop Set
extern YesNo closeTimeFlag =  No; //Close Time Enable (Yes/No)
input datetime CloseTime = D'2020.01.01 00:00';
extern long magicNumber ; //Magic Number

//Flag to prevent the same EA from opening additional trades. Flagged after successfully opened
bool executed=false;
bool orderClosed = false; //Last step, order has closed by EA, EA should no longer do anything. 

int buySellHard; //Store hard permanent setting, in case client changes
int ticket=0;
int slippage=5;
double trailStopMktSource=0; //Store last market rate that updated trailing stop rate
int colorVal = clrGreen;
   
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  EventSetTimer(10);
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
   if(orderClosed) {
      Comment("Order has been closed. Remove EA and add again to reset");
      return; //EA's purpose completed previously
   }
   DPrint("OnTick: Exec:"+executed);
   OpenOrder();
   doTrailingStop(ticket);
   CloseOrder();
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
     DPrint("OnTimer: Exec:"+executed);

   if(orderClosed) {
      Comment("Order has been closed. Remove EA and add again to reset");
      return; //EA's purpose completed previously
   }
   //Run checks for opening order
   OpenOrder();
   CloseOrder();
   
//---
   //Print("Test4 ping...");
  }
//+------------------------------------------------------------------+


void OpenOrder(){

   //Exit if order already opened
   if(executed){
      return ;
   }
   Comment("Waiting to open ticket");
      
   
   bool timeToOpen = EntryTime <= LocalTime() ? true : false;
   if (!timeToOpen){
      DPrint("Market: "+Bid+"/"+Ask);

      DPrint("Too Early");
      return;
   }
   
//--- get minimum stop level
   double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
   Print("Minimum Stop Level=",minstoplevel," points");
   double price= buySell==OP_BUY ? Ask : Bid;
//--- calculated SL and TP prices must be normalized
   double stoploss=NormalizeDouble(price-minstoplevel*Point,Digits);
   stoploss=calculateNewStop(buySell, price, stopLossPips);
   if (stopLossPips==0){
      stoploss=0;
   }
   double takeprofit=0;
   
   DPrint("Market: "+Bid+"/"+Ask);
   DPrint("OpenRate: "+price);
   DPrint("StopLoss: "+stoploss);

   ticket=OrderSend(Symbol(),buySellHard,lots,price,slippage,stoploss,takeprofit,"MN:"+magicNumber,magicNumber,0,clrGreen);
   if(ticket<0)
     {
      Print("OrderSend failed with error #",GetLastError());
     }
   else{
      Print("OrderSend placed successfully");
      executed=true;
      OrderSelect(ticket, SELECT_BY_TICKET);
      DPrint("Magic:" +OrderMagicNumber());
      
      DPrint("OpenRate: "+OrderOpenPrice());
      DPrint("Point: "+Point);
      DPrint("OrderType: "+OrderType());
      buySellHard=OrderType();
      Comment("Ticket has been opened:" + ticket);
      }

}

void CloseOrder(){

   //Exit if trade not yet opened and flag to close is not enabled
   if(!executed){
      return ;
   }

   if(!closeTimeFlag){
      return ;
   }
   
   bool timeToClose = CloseTime <= LocalTime() ? true : false;
   if (!timeToClose){
      DPrint("Market: "+Bid+"/"+Ask);

      DPrint("Too Early to close");
      return;
   }

   bool tktFound = OrderSelect(ticket,SELECT_BY_TICKET);
   if (tktFound){
      double closePrice = OrderType()==OP_BUY ? Bid : Ask; //if order was buy, get bid, else ask to close it
      bool closeStatus = OrderClose(OrderTicket(), lots, closePrice,slippage, colorVal);
      if (!closeStatus){
         Print("OrderClose failed with error #",GetLastError());
     }  else{
         Print("OrderClose placed successfully");
         orderClosed=true;
         Comment("Trade has closed. EA must be removed and re-added to set up new conditions");
      }
   }
}


//longShortType is the side used to open a position
double calculateNewStop(int longShortType, double origRate, int pipDist){

   double stoploss=0;
   if(longShortType==OP_BUY){
      stoploss=NormalizeDouble(origRate-pipDist*Point,Digits);
   } else{
      stoploss=NormalizeDouble(origRate+pipDist*Point,Digits);
   }
   
   return stoploss;
}

void doTrailingStop(int ticket){
  
   DPrint("DoTrailig A Exec:"+ executed);

   if(!executed){
      //Reset the market rate that influences trailing stop updates
      trailStopMktSource=0;
      DPrint("DoTrailig Not Opened Yet");
   
      return;
   }
   
      if(!trailingStopFlag){
      //Reset the market rate that influences trailing stop updates
      trailStopMktSource=0;
      DPrint("DoTrailig TrailStop Disabled");
      return;
   }


   DPrint("DoTrailig:"+executed);
   DPrint("DoTrailig:"+trailingStopFlag);
   OrderSelect(ticket, SELECT_BY_TICKET);
   int longShortType= OrderType();
   double currentSL = OrderStopLoss();

   //First time trailFlag is set, we set initial trailTradeRate based on market
   if (trailStopMktSource==0){
      if (longShortType==OP_BUY){
         trailStopMktSource=Bid;
      } else{
         trailStopMktSource=Ask;
      }
      return;
   }
   
   //Check if new market rate is better then previous best market rate(last rate that caused stoploss to move via trailing update)
   double newMarketRate = OrderType()==OP_BUY ? Bid : Ask;
   double diff = getDifference(trailStopMktSource, newMarketRate, OrderType());
   
   if (diff <= 0 ){
      DPrint("Negative market movemnt, do not update sl");
      DPrint("OldMktRate: "+trailStopMktSource);
      DPrint("NewMktRate: "+newMarketRate);

      //Market didn't get better that last best rate, ignore
      return;
   }
   
   DPrint("TrailStop Prep");
   DPrint("OldMktRate: "+trailStopMktSource);
   DPrint("NewMktRate: "+newMarketRate);
   DPrint("DIff: " + diff);
   
   double newSL = OrderStopLoss();
   
   DPrint("OrigSL: "+OrderStopLoss());
   if (OrderType()==OP_BUY){
      newSL+=diff;
   } else{
      newSL-=diff;
   }
   Print("newSL: "+newSL);
   
   bool res = OrderModify(ticket,OrderOpenPrice(),NormalizeDouble(newSL,Digits),OrderTakeProfit(),0,colorVal);
   if(!res)
     Print("Error in OrderModify (TrailStop). Error code=",GetLastError());
   else
     Print("Order modified (TrailStop Updated) successfully.");
     trailStopMktSource = newMarketRate;
   
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

bool debug=true;
void DPrint(string str){
   if(debug)
    Print(str);
}