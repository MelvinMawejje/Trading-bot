

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots 1

#include <Trade\Trade.mqh>
#include <Tools\DateTime.mqh>
CTrade      trade;


// Define external parameters for the robot
input double LotSize = 0.01;  
input int    MaxPositions = 5;
input int    ProfitablePositionTime = 6000;

  
// Define variables for trading logic
int trendDir;  // Variable to store the current trend direction
datetime lastProfitableTime;  // Variable to store the time of the last profitable position
double pos_profit;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   
  
   lastProfitableTime = 0;  // Initialize the last profitable time
   return(INIT_SUCCEEDED);
}



void ExecuteBuyOrder(){
                     MqlTradeRequest request = {}; // Initialize request structure
                     MqlTradeResult result = {};   // Initialize result structure
                     
                     double Ask = SYMBOL_ASK;
                     
                     request.action = TRADE_ACTION_DEAL; // Set the trade action to deal
                     request.symbol = _Symbol;           // Set the symbol to the current symbol
                     request.volume = LotSize;           // Set the volume to the lot size
                     request.type = ORDER_TYPE_BUY;      // Set the order type to buy
                     request.price = Ask;                // Set the price to the current ask price
                     request.deviation = 3;               // Set the slippage
                     request.comment = "Buy Order";      // Set a comment for the order
                     request.magic = 0;                  // Set the magic number (if needed)
                     request.type_filling = ORDER_FILLING_FOK; // Set the order filling type
                     
                     // Send the trading request
                     if (OrderSend(request, result))
                     {
                         // Order sent successfully
                         Print("Buy order sent successfully. Order ticket: ", result.order);
                         
                         // Buy order executed successfully
                            lastProfitableTime = TimeCurrent();  // Update the last profitable time
                
                     }
                     else
                     {
                         // Failed to send order
                         Print("Failed to send buy order. Error code: ", result.retcode);
                     }

}

void ExecuteSellOrder()
{
                     MqlTradeRequest request = {}; // Initialize request structure
                     MqlTradeResult result = {};   // Initialize result structure
                     
                     double Bid = SYMBOL_BID;
                     
                     request.action = TRADE_ACTION_DEAL; // Set the trade action to deal
                     request.symbol = _Symbol;           // Set the symbol to the current symbol
                     request.volume = LotSize;           // Set the volume to the lot size
                     request.type = ORDER_TYPE_SELL;     // Set the order type to sell
                     request.price = Bid;                // Set the price to the current bid price
                     request.deviation = 3;               // Set the slippage
                     request.comment = "Sell Order";     // Set a comment for the order
                     request.magic = 0;                  // Set the magic number (if needed)
                     request.type_filling = ORDER_FILLING_FOK; // Set the order filling type
                  
                     // Send the trading request
                     if (OrderSend(request, result))
                     {
                        // Sell order executed successfully
                        lastProfitableTime = TimeCurrent();  // Update the last profitable time
                        Print("Sell order sent successfully. Order ticket: ", result.order);
                     }
                     else
                     {
                        // Failed to send sell order
                        Print("Failed to send sell order. Error code: ", result.retcode);
                     }
}

// Function to close all open positions
void CloseAllPositions()
{

   for (int i = 0; i < PositionsTotal(); i++)
   {
   int all_pos = PositionGetTicket(i);
      trade.PositionClose(all_pos);
   }
  
   //CloseAllBuyPositions();
   //CloseAllSellPositions();
  }
  
 void CloseAllBuyPositions(){
   for (int i = PositionsTotal(); i>=0; i--)
   {
      ulong buy_pos = PositionGetTicket(i);
      
      int position_direction = PositionGetInteger(POSITION_TYPE);
      
      if(position_direction == POSITION_TYPE_BUY){
         trade.PositionClose(buy_pos);
      }
      
   }
 }
 
 
 void CloseAllSellPositions(){
   for (int i = PositionsTotal(); i>=0; i--)
   {
      ulong sell_pos = PositionGetTicket(i);
      
      int position_direction = PositionGetInteger(POSITION_TYPE);
      
      if(position_direction == POSITION_TYPE_SELL){
         trade.PositionClose(sell_pos);
      }
      
   }
 }
   
 /*
 void clear(){
   lastProfitableTime =0;
   CloseAllPositions();
   int i = 0;
 }
 */
 
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Get the current server time
      datetime serverTime = TimeCurrent();
      datetime local = TimeLocal();
   
      //create a datatime structure
      MqlDateTime DateTimeStructure;
      
      //convert server time to date-time structure
      TimeToStruct(serverTime,DateTimeStructure);

   //create DayofWeek
    int DayOfWeek = DateTimeStructure.day_of_week;
    
   // Check if current day is between Monday and Friday
   if (DayOfWeek >= 1 && DayOfWeek <= 5)
   {
      
      
      
      // Convert the server time to a readable string
      string timeString = TimeToString(serverTime,TIME_MINUTES);
      string time = TimeToString(local,TIME_MINUTES);
      
      int serverHour = StringToInteger(StringSubstr(timeString, 0, 2)); // Extract substring "HH"
      // Check if current time is between 12:00 and 19:00 server time
      
      if (serverHour >= 13 && serverHour < 18)
      {
         //create a handle with the indicator
         int handle = iCustom(_Symbol, _Period, "Supertrend");
         
         double currentST[];
         CopyBuffer(handle,0,0,3,currentST);
         
            Comment("This is the time: ",time);

    //============= Check for a bullish trend================================
         if (currentST[1] < iClose(_Symbol, _Period, 1))
         {
            CloseAllSellPositions();
             
          if (PositionsTotal() < MaxPositions)
            {
               //clear();
            
            if (PositionsTotal() < MaxPositions && PositionsTotal()< 1)
            {
               ExecuteBuyOrder();
            }
             else if((PositionsTotal() < MaxPositions) && (PositionsTotal()> 0))
            {
              
                 // Check for new position entry after 2 minutes
                  if (TimeCurrent() - lastProfitableTime >= ProfitablePositionTime)
                           {
                             int i = PositionsTotal() - 1; // Access the last position
                                 if (i >= 0) { // Check if any open positions exist
                                     ulong ticket = PositionGetTicket(i);
                                     if (ticket > 0) {
                                         PositionSelectByTicket(ticket);
                                 
                                         // Check for profit
                                         double profit = PositionGetDouble(POSITION_PROFIT);
                                         if (profit > 0) {
                                             // Position is in profit, execute sell order
                                             ExecuteBuyOrder();
                                         } 
                                     }
                                 }
                           }       
                  }
            }
                
            
         }
    //========================= Check for a bearish trend=====================================
         else if (currentST[1] > iClose(_Symbol, _Period, 1))
         {
            CloseAllBuyPositions();
            //clear();
            
            if (PositionsTotal() < MaxPositions && PositionsTotal()< 1)
            {
               ExecuteSellOrder();
            }
            else if((PositionsTotal() < MaxPositions) && (PositionsTotal()> 0))
            {
               
                 // Check for new position entry after 2 minutes
                  if (TimeCurrent() - lastProfitableTime >= ProfitablePositionTime)
                           {
                             int i = PositionsTotal() - 1; // Access the last position
                                 if (i >= 0) { // Check if any open positions exist
                                     ulong ticket = PositionGetTicket(i);
                                     if (ticket > 0) {
                                         PositionSelectByTicket(ticket);
                                 
                                         // Check for profit
                                         double profit = PositionGetDouble(POSITION_PROFIT);
                                         if (profit > 0) {
                                             // Position is in profit, execute sell order
                                             ExecuteSellOrder();
                                         } 
                                     }
                                 }

                                       
                           }       
               
            }
            

         
           
         }
        if(timeString == "17:59")
        {
        CloseAllPositions();
        } 
         
      }
         
   }
}

void OnDeinit(const int reason)
  {

   
  }
