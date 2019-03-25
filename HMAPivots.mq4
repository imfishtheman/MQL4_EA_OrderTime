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

enum CalculationMethod{
  Simple=0,
  Exponential=1,
  Smoothed=2,
  LinearWeighted=3
};
  
enum HMAPriceType{
  CloseRate=0,
  OpenRate=1,
  HighRate=2,
  LowRate=3,
  Median=4,
  Typical=5,
  Weighted=6
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

input int HMAPeriods = 21; //HMAPeriods
input CalculationMethod HMAMethod = Simple; 
input HMAPriceType HMAPrice=CloseRate;

input int PivotsGMTShift = 0;
input int PivotRange = 10;
input int PivotLevel = Pivot;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  
      
//--- create timer
   EventSetTimer(60);
   
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
     
      double s3Rate = iCustom(NULL, 0, "Mike\\gStdPivots", PivotsGMTShift, clrGreen,clrRed, 10,20,S3,0);
      Print("OnTick S3Rate: "+s3Rate);      

      double pivotRate = iCustom(NULL, 0, "Mike\\gStdPivots", PivotsGMTShift, clrGreen,clrRed, 10,20,Pivot,0);
      Print("OnTick pivotRate: "+pivotRate);

      double r3Rate = iCustom(NULL, 0, "Mike\\gStdPivots", PivotsGMTShift, clrGreen,clrRed, 10,20,R3,0);
      Print("OnTick R3Rate: "+r3Rate);


  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
