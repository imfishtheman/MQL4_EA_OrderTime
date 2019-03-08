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
  
input datetime EntryTime = D'2019.03.01 00:00'; //Entry Time 
extern BuySell buySell = Buy; //Buy or Sell
extern double lots =0.01; //Lots
extern int stopLossPips = 0; //Stop Loss in Pips
extern bool trailingStop = false; //Trailing Stop Set
extern YesNo closeTimeFlag =  No; //Close Time Enable (Yes/No)
input datetime CloseTime = D'2020.01.01 00:00';
extern long magicNumber ; //Magic Number

//Flag to prevent the same EA from opening additional trades. Flagged after successfully opened
bool executed=false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  EventSetTimer(1);
  /*
  //MessageBox("Are you sure!!");
  Print("OnInit called");
  Print("Magic: "+magic);
  Print("Executed: "+executed);
  
//--- create timer
   EventSetTimer(4);
   if(executed){
   return (INIT_SUCCEEDED);
   }
//--- get minimum stop level
   double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
   Print("Minimum Stop Level=",minstoplevel," points");
   double price=Bid;
//--- calculated SL and TP prices must be normalized
   double stoploss=NormalizeDouble(Bid-minstoplevel*Point,Digits);
   double takeprofit=NormalizeDouble(Bid+minstoplevel*Point,Digits);
   stoploss=0;
   takeprofit=0;
//--- place market order to buy 1 lot
   int ticket=OrderSend(Symbol(),OP_SELL,.01,price,3,stoploss,takeprofit,"My order",16384,0,clrGreen);
   if(ticket<0)
     {
      Print("OrderSend failed with error #",GetLastError());
     }
   else{
      Print("OrderSend placed successfully");
      executed=true;
      OrderSelect(ticket, SELECT_BY_TICKET);
      Print("Magic:" +OrderMagicNumber());
      magic=OrderMagicNumber();
      Print("OpenRate: "+OrderOpenPrice());
      Print("Point: "+Point);
      Print("OrderType: "+OrderType());

      }
*/
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
   OpenOrder();
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
  /*
   Print("LocalTime: " + TimeLocal());
   Print("EntryTime: " + EntryTime);
   string question = EntryTime <= LocalTime() ? "No" : "Yes";
   Print("EntryTime > LocalTime : "+ question);
   */
   //Run checks for opening order
   OpenOrder();
//---
   //Print("Test4 ping...");
  }
//+------------------------------------------------------------------+


void OpenOrder(){

   //Exit if order already opened
   if(executed){
      return ;
   }
   
   bool timeToOpen = EntryTime <= LocalTime() ? true : false;
   if (!timeToOpen){
      Print("Too Early");
      return;
   }
   
//--- get minimum stop level
   double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
   Print("Minimum Stop Level=",minstoplevel," points");
   double price= buySell==OP_BUY ? Ask : Bid;
//--- calculated SL and TP prices must be normalized
   double stoploss=NormalizeDouble(price-minstoplevel*Point,Digits);
   stoploss=0;
   double takeprofit=0;
//--- place market order to buy 1 lot

   int ticket=OrderSend(Symbol(),buySell,lots,price,3,stoploss,takeprofit,"My order",magicNumber,0,clrGreen);
   if(ticket<0)
     {
      Print("OrderSend failed with error #",GetLastError());
     }
   else{
      Print("OrderSend placed successfully");
      executed=true;
      OrderSelect(ticket, SELECT_BY_TICKET);
      Print("Magic:" +OrderMagicNumber());
      int magic=OrderMagicNumber();
      Print("OpenRate: "+OrderOpenPrice());
      Print("Point: "+Point);
      Print("OrderType: "+OrderType());

      }
}