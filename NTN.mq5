//+------------------------------------------------------------------+
//|                                                             NTN  |
//|                                      Copyright 2025, ----------- |
//|                                       ---------------------------|
//+------------------------------------------------------------------+
#property copyright "Y"
#property link      ""
#property version   "1.00"
#property strict // おまじない


#include <ChartObjects\ChartObjectsTxtControls.mqh>
#include <Trade\Trade.mqh>


// --- グローバル変数 ---

//-- Trading --
CTrade trade;

//-- Order Button --
CChartObjectButton OrderButton; //Order button
//-- MTP --
CChartObjectButton MTPButton; //MTP Button
CChartObjectEdit MTPEdit; //MTP Edit
//-- MTP Line --
string MTP_Line_Name = "MTP_Line"; // MTPラインのオブジェクト名
bool MtpEnabled = false; // MTP機能が有効かどうかのフラグ
double MtpTargetPips = 10.0; // MTPの目標PIP数 (初期値: 10 pips)
//-- Close All Button --
CChartObjectButton CloseAllButton; //CloseAllButton
//--　Virtual Trailing Stop --
CChartObjectButton  VTrailingStopButton; //Virtual TrailingStop Button
CChartObjectEdit VTrailingStopEdit; //Virtual TrailingStop Edit
string VTS_Line_BaseName = "VTS_Line_"; // VTSライン名の接頭辞
//-- Cancel All Order --
CChartObjectButton CancelAllOrderButton; //Cancel All Order Button
//-- "Current PIP/POINT:" --
CChartObjectLabel Current_PIP_POINT_Label; //"Current PIP/POINT:" Label
CChartObjectLabel PIP_POINT_COUNTER; //カウンター
//-- UI Margin --
CChartObjectLabel Margin_Label; //ラベル
CChartObjectEdit Margin_Edit; //edit
//-- UI Lot --
CChartObjectLabel Lot_Label; //ラベル
CChartObjectEdit Lot_Edit; //edit
//-- UI StopLoss --
CChartObjectLabel SL_Label; //ラベル
CChartObjectEdit SL_Edit; //edit
//-- UI TP --
CChartObjectLabel TP_Label; //ラベル
CChartObjectEdit TP_Edit; //edit
//-- UI VTS Min --
CChartObjectLabel VTS_Min_Label; //ラベル
CChartObjectEdit VTS_Min_Edit; //edit
double VTS_Min_Value = 3; //TS起動最小PIP
bool VtsEnabled = false;            // VTS機能が有効かどうかのフラグ
double VtsTrailingPips = 5.0;       // VTSのトレーリング幅 (初期値: 5 pips)


// 各ポジションのVTS状態を追跡するための配列
long   VtsTrackedTickets[];      // 追跡中のポジションチケット番号
double VtsPeakPrice[];           // 各ポジションが到達した最高値(Buy)または最安値(Sell)
bool   VtsActivated[];           // 各ポジションでVTSが有効化されたか (Min PIPを超えたか)
int    VtsDigits[];              // 各ポジションのシンボルの桁数（通貨ペアごとに異なる可能性があるため）
double VtsPipSize[];             // 各ポジションのシンボルのPIPサイズ（同様）



//--- INPUT --
input int MagicNum = 839656396;

double PIP;

//+------------------------------------------------------------------+
//|global value　                |
//+------------------------------------------------------------------+
double extLotSize = 0.01;       // ロット数 (初期値)
double extMargin = 25;   // Margin (Point単位、初期値)
double extStopLoss = 25;  // StopLoss (Point単位、初期値)
double extTakeProfit = 100; // TakeProfit (Point単位、初期値)


//+------------------------------------------------------------------+
//| OnInit  |
//+------------------------------------------------------------------+
int OnInit()
   {
    EventSetMillisecondTimer(5);

    PIP = GetPipSize();
//--- MagicNumSet
    trade.SetExpertMagicNumber(MagicNum);


//--　チャートシフトをONにして、20%に設定する
    ChartSetInteger(0, CHART_SHIFT, true);
    ChartSetDouble(0, CHART_SHIFT_SIZE, 20);



//-- Button初期値 ---
//- Button A Size -
    int ButtonA_X1 = 50; //X座標
    int ButtonA_Y1 = 50; //Y座標
    int ButtonA_X2 = 112; //幅
    int ButtonA_Y2 = 35; //高さ
//- Button B Size -
    int ButtonB_X1 = 50;
    int ButtonB_Y1 = 50;
    int ButtonB_X2 = 40;
    int ButtonB_Y2 = 30;

//-- Edit初期値 ---
//- Edit A Size -
    int EditBoxA_X1 = 50;
    int EditBoxA_Y1 = 50;
    int EditBoxA_X2 = 53;
    int EditBoxA_Y2 = 25;
//- Edit B Size -
    int EditBoxB_X1 = 50;
    int EditBoxB_Y1 = 50;
    int EditBoxB_X2 = 67;
    int EditBoxB_Y2 = 30;

//-- UI初期位置 -- (order buton基準)
    int AX_Distance = 115;
    int AY_Distance =120;



//-- Order Button 作成--
    if(!OrderButton.Create(0,"OrderButton",0,ButtonA_X1,ButtonA_Y1,ButtonA_X2,ButtonA_Y2))
       {
        Print("Order ボタンの作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
//OrderButton.Anchor(ANCHOR_RIGHT_UPPER); //なんか機能しない
    ObjectSetInteger(0, "OrderButton", OBJPROP_CORNER, CORNER_RIGHT_UPPER); //こっちで代用
    OrderButton.X_Distance(AX_Distance);
    OrderButton.Y_Distance(AY_Distance);
    if(!OrderButton.Description("Order")) //このライブラリではテキストをdescriptionでいれる。
       {
        Print("ボタンテキストの設定に失敗しました！ Error code: ", GetLastError());
        return(INIT_FAILED);
       }

//-- MTP Button 作成--
    if(!MTPButton.Create(0,"MTPButton",0,ButtonB_X1,ButtonB_Y1,ButtonB_X2,ButtonB_Y2))
       {
        Print("MTP ボタンの作成に失敗しました！ Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, "MTPButton", OBJPROP_CORNER, CORNER_RIGHT_UPPER); //右上基準に変更
    MTPButton.X_Distance(AX_Distance);
    MTPButton.Y_Distance(AY_Distance+50);
    MTPButton.BackColor(C'0x90,0x90,0x90');
    if(!MTPButton.Description("MTP")) //このライブラリではテキストをdescriptionでいれる。
       {
        Print("ボタンテキストの設定に失敗しました！ Error code: ", GetLastError());
        return(INIT_FAILED);
       }
//-- MTP Edit 作成 --
    if(!MTPEdit.Create(0,"MTPEdit",0,EditBoxB_X1,EditBoxB_Y1,EditBoxB_X2,EditBoxB_Y2))
       {
        Print("MTPEdit の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, "MTPEdit", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    MTPEdit.X_Distance(AX_Distance-45);
    MTPEdit.Y_Distance(AY_Distance+50);
    MTPEdit.Color(clrBlack);
    MTPEdit.BackColor(clrWhiteSmoke);
//ObjectSetInteger(0, MTPEdit.Name(), OBJPROP_ALIGN, ALIGN_RIGHT); // 入力欄の文字揃えを右揃えにする
    if(!MTPEdit.Description(DoubleToString(MtpTargetPips,1)))
       {
        Print("MTPEdit テキストの設定に失敗しました！ Error code: ", GetLastError());
       }

//-- Close All Button 作成--
    if(!CloseAllButton.Create(0,"CloseAllButton",0,ButtonA_X1,ButtonA_Y1,ButtonA_X2,ButtonA_Y2))
       {
        Print("CloseAllButton の作成に失敗しました！ Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, "CloseAllButton", OBJPROP_CORNER, CORNER_RIGHT_UPPER); //右上基準に変更
    CloseAllButton.X_Distance(AX_Distance);
    CloseAllButton.Y_Distance(AY_Distance+95);
    CloseAllButton.BackColor(C'0xFF,0x66,0x66');
    ObjectSetInteger(0, CloseAllButton.Name(), OBJPROP_FONTSIZE, 9);
    if(!CloseAllButton.Description("CloseAllPosition")) //このライブラリではテキストをdescriptionでいれる。
       {
        Print("ボタンテキストの設定に失敗しました！ Error code: ", GetLastError());
        return(INIT_FAILED);
       }

//-- VTrailingStop Button 作成--
    if(!VTrailingStopButton.Create(0,"VTrailingStop",0,ButtonB_X1,ButtonB_Y1,ButtonB_X2,ButtonB_Y2))
       {
        Print("VTrailingStop ボタンの作成に失敗しました！ Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, VTrailingStopButton.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER); //右上基準に変更
    VTrailingStopButton.X_Distance(AX_Distance);
    VTrailingStopButton.Y_Distance(AY_Distance+145);
    VTrailingStopButton.BackColor(C'0x90,0x90,0x90');
//ObjectSetInteger(0, VTrailingStop.Name(), OBJPROP_FONTSIZE, 9);
    if(!VTrailingStopButton.Description("VTS")) //このライブラリではテキストをdescriptionでいれる。
       {
        Print("ボタンテキストの設定に失敗しました！ Error code: ", GetLastError());
        return(INIT_FAILED);
       }
//-- VTrailingStop Edit 作成 --
    if(!VTrailingStopEdit.Create(0,"VTrailingStopEdit",0,EditBoxB_X1,EditBoxA_Y1,EditBoxB_X2,EditBoxB_Y2))
       {
        Print("VTrailingStopEdit の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, VTrailingStopEdit.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    VTrailingStopEdit.X_Distance(AX_Distance-45);
    VTrailingStopEdit.Y_Distance(AY_Distance+145);
    VTrailingStopEdit.Color(clrBlack);
    VTrailingStopEdit.BackColor(clrWhiteSmoke);
//ObjectSetInteger(0, MTPEdit.Name(), OBJPROP_ALIGN, ALIGN_RIGHT); // 入力欄の文字揃えを右揃えにする
    if(!VTrailingStopEdit.Description(DoubleToString(VtsTrailingPips, 1)))
       {
        Print("VTrailingStopEdit テキストの設定に失敗しました！ Error code: ", GetLastError());
       }

//-- Close All Button 作成--
    if(!CancelAllOrderButton.Create(0,"CancelAllOrderButton",0,ButtonA_X1,ButtonA_Y1,ButtonA_X2,ButtonA_Y2))
       {
        Print("CancelAllOrderButton の作成に失敗しました！ Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, CancelAllOrderButton.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER); //右上基準に変更
    CancelAllOrderButton.X_Distance(AX_Distance);
    CancelAllOrderButton.Y_Distance(AY_Distance+190);
    CancelAllOrderButton.BackColor(C'0xFD,0xDB,0xDB');
    ObjectSetInteger(0, CancelAllOrderButton.Name(), OBJPROP_FONTSIZE, 10);
    if(!CancelAllOrderButton.Description("CancelAllOrder")) //このライブラリではテキストをdescriptionでいれる。
       {
        Print("ボタンテキストの設定に失敗しました！ Error code: ", GetLastError());
        return(INIT_FAILED);
       }

//-- Current Pip Point: Label 作成 --
    if(!Current_PIP_POINT_Label.Create(0,"Current_PIP_POINT_Label",0,EditBoxA_X1,EditBoxA_Y1))
       {
        Print("Current_PIP_POINT_Label の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, Current_PIP_POINT_Label.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    Current_PIP_POINT_Label.X_Distance(AX_Distance+1);
    Current_PIP_POINT_Label.Y_Distance(AY_Distance+240);
    Current_PIP_POINT_Label.Color(clrWhiteSmoke);
    Current_PIP_POINT_Label.FontSize(10);
    if(!Current_PIP_POINT_Label.Description("Current PIP/POINT:"))
       {
        Print("Current_PIP_POINT_Label テキストの設定に失敗しました！ Error code: ", GetLastError());
       }
//-- Current Pip Point:　COUNTER　カウンター 作成 --
    if(!PIP_POINT_COUNTER.Create(0,"PIP_POINT_COUNTER",0,EditBoxA_X1,EditBoxA_Y1))
       {
        Print("PIP_POINT_COUNTER の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, PIP_POINT_COUNTER.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    PIP_POINT_COUNTER.X_Distance(AX_Distance);
    PIP_POINT_COUNTER.Y_Distance(AY_Distance+256);
    PIP_POINT_COUNTER.Color(clrRed);
    PIP_POINT_COUNTER.FontSize(19);
    if(!PIP_POINT_COUNTER.Description("0.0"))
       {
        Print("PIP_POINT_COUNTER テキストの設定に失敗しました！ Error code: ", GetLastError());
       }


//-- Margin Label 作成 --
    if(!Margin_Label.Create(0,"Margin_Label",0,EditBoxA_X1,EditBoxA_Y1))
       {
        Print("Margin_Label の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, Margin_Label.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    Margin_Label.X_Distance(AX_Distance);
    Margin_Label.Y_Distance(AY_Distance+295);
    Margin_Label.Color(clrWhiteSmoke);
    Margin_Label.FontSize(10);
    if(!Margin_Label.Description("Margin:"))
       {
        Print("Margin_Label テキストの設定に失敗しました！ Error code: ", GetLastError());
       }
//-- Margin Edit 作成 --
    if(!Margin_Edit.Create(0,"Margin_Edit",0,EditBoxA_X1,EditBoxA_Y1,EditBoxA_X2,EditBoxA_Y2))
       {
        Print("Margin_Edit の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, Margin_Edit.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    Margin_Edit.X_Distance(AX_Distance);
    Margin_Edit.Y_Distance(AY_Distance+312);
    Margin_Edit.Color(clrBlack);
    Margin_Edit.FontSize(10);
    Margin_Edit.BackColor(clrWhiteSmoke);
    if(!Margin_Edit.Description(DoubleToString(extMargin, 1)))
       {
        Print("Margin_Edit テキストの設定に失敗しました！ Error code: ", GetLastError());
       }

//-- Lot Label 作成 --
    if(!Lot_Label.Create(0,"Lot_Label",0,EditBoxA_X1,EditBoxA_Y1))
       {
        Print("Lot_Label の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, Lot_Label.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    Lot_Label.X_Distance(AX_Distance-60);
    Lot_Label.Y_Distance(AY_Distance+295);
    Lot_Label.Color(clrWhiteSmoke);
    Lot_Label.FontSize(10);
    if(!Lot_Label.Description("Lot:"))
       {
        Print("Lot_Label テキストの設定に失敗しました！ Error code: ", GetLastError());
       }
//-- Lot Edit 作成 --
    if(!Lot_Edit.Create(0,"Lot_Edit",0,EditBoxA_X1,EditBoxA_Y1,EditBoxA_X2,EditBoxA_Y2))
       {
        Print("Lot_Edit の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, Lot_Edit.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    Lot_Edit.X_Distance(AX_Distance-60);
    Lot_Edit.Y_Distance(AY_Distance+312);
    Lot_Edit.Color(clrBlack);
    Lot_Edit.FontSize(10);
    Lot_Edit.BackColor(clrWhiteSmoke);
    if(!Lot_Edit.Description(DoubleToString(extLotSize, 2)))
       {
        Print("Lot_Edit テキストの設定に失敗しました！ Error code: ", GetLastError());
       }

//-- SL Label 作成 --
    if(!SL_Label.Create(0,"SL_Label",0,EditBoxA_X1,EditBoxA_Y1))
       {
        Print("SL_Label の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, SL_Label.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    SL_Label.X_Distance(AX_Distance);
    SL_Label.Y_Distance(AY_Distance+345);
    SL_Label.Color(clrWhiteSmoke);
    SL_Label.FontSize(10);
    if(!SL_Label.Description("SL:"))
       {
        Print("SL_Label テキストの設定に失敗しました！ Error code: ", GetLastError());
       }
//-- SL Edit 作成 --
    if(!SL_Edit.Create(0,"SL_Edit",0,EditBoxA_X1,EditBoxA_Y1,EditBoxA_X2,EditBoxA_Y2))
       {
        Print("SL_Edit の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, SL_Edit.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    SL_Edit.X_Distance(AX_Distance);
    SL_Edit.Y_Distance(AY_Distance+362);
    SL_Edit.Color(clrBlack);
    SL_Edit.FontSize(10);
    SL_Edit.BackColor(clrWhiteSmoke);
    if(!SL_Edit.Description(DoubleToString(extStopLoss, 1)))
       {
        Print("SL_Edit テキストの設定に失敗しました！ Error code: ", GetLastError());
       }

//-- TP Label 作成 --
    if(!TP_Label.Create(0,"TP_Label",0,EditBoxA_X1,EditBoxA_Y1))
       {
        Print("TP_Label の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, TP_Label.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    TP_Label.X_Distance(AX_Distance-60);
    TP_Label.Y_Distance(AY_Distance+345);
    TP_Label.Color(clrWhiteSmoke);
    TP_Label.FontSize(10);
    if(!TP_Label.Description("TP:"))
       {
        Print("TP_Label テキストの設定に失敗しました！ Error code: ", GetLastError());
       }
//-- TP Edit 作成 --
    if(!TP_Edit.Create(0,"TP_Edit",0,EditBoxA_X1,EditBoxA_Y1,EditBoxA_X2,EditBoxA_Y2))
       {
        Print("TP_Edit の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, TP_Edit.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    TP_Edit.X_Distance(AX_Distance-60);
    TP_Edit.Y_Distance(AY_Distance+362);
    TP_Edit.Color(clrBlack);
    TP_Edit.FontSize(10);
    TP_Edit.BackColor(clrWhiteSmoke);
    if(!TP_Edit.Description(DoubleToString(extTakeProfit, 1)))
       {
        Print("TP_Edit テキストの設定に失敗しました！ Error code: ", GetLastError());
       }

//-- VTS Min Label 作成 --
    if(!VTS_Min_Label.Create(0,"VTS_Min_Label",0,EditBoxA_X1,EditBoxA_Y1))
       {
        Print("VTS_Min_Label の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, VTS_Min_Label.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    VTS_Min_Label.X_Distance(AX_Distance-60);
    VTS_Min_Label.Y_Distance(AY_Distance+395);
    VTS_Min_Label.Color(clrWhiteSmoke);
    VTS_Min_Label.FontSize(9);
    if(!VTS_Min_Label.Description("VTS_Min:"))
       {
        Print("VTS_Min_Label テキストの設定に失敗しました！ Error code: ", GetLastError());
       }
//-- VTS Min 作成 --
    if(!VTS_Min_Edit.Create(0,"VTS_Min_Edit",0,EditBoxA_X1,EditBoxA_Y1,EditBoxA_X2,EditBoxA_Y2))
       {
        Print("VTS_Min_Edit の作成に失敗しました Error code: ",GetLastError());
        return(INIT_FAILED);
       }
    ObjectSetInteger(0, VTS_Min_Edit.Name(), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    VTS_Min_Edit.X_Distance(AX_Distance-60);
    VTS_Min_Edit.Y_Distance(AY_Distance+412);
    VTS_Min_Edit.Color(clrBlack);
    VTS_Min_Edit.FontSize(10);
    VTS_Min_Edit.BackColor(clrWhiteSmoke);
    if(!VTS_Min_Edit.Description(DoubleToString(VTS_Min_Value, 1)))
       {
        Print("VTS_Min_Edit テキストの設定に失敗しました！ Error code: ", GetLastError());
       }

// --- VTS追跡用配列の初期化 ---
    ArrayResize(VtsTrackedTickets, 0);
    ArrayResize(VtsPeakPrice, 0);
    ArrayResize(VtsActivated, 0);
    ArrayResize(VtsDigits, 0);
    ArrayResize(VtsPipSize, 0);

// --- EA起動時に存在するポジションを追跡対象に追加 ---
    InitializeVtsTracking();



    ChartRedraw();
    return(INIT_SUCCEEDED);
   }



//+------------------------------------------------------------------+
//| OnDeinit      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
   {

    OrderButton.Delete();
    MTPButton.Delete();
    MTPEdit.Delete();
    CloseAllButton.Delete();
    VTrailingStopButton.Delete();
    VTrailingStopEdit.Delete();
    CancelAllOrderButton.Delete();
    Current_PIP_POINT_Label.Delete();
    PIP_POINT_COUNTER.Delete();
    Margin_Label.Delete();
    Margin_Edit.Delete();
    Lot_Label.Delete();
    Lot_Edit.Delete();
    SL_Label.Delete();
    SL_Edit.Delete();
    TP_Label.Delete();
    TP_Edit.Delete();
    VTS_Min_Label.Delete();
    VTS_Min_Edit.Delete();
    DeleteAllVtsLines();

// --- MTPライン削除 ---
    ObjectDelete(0, MTP_Line_Name);

    ChartRedraw(); // チャートを再描画
   }

//+------------------------------------------------------------------+
//| OnChartEvent                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
   {

    if(id==CHARTEVENT_OBJECT_CLICK)
       {

        // CLICK Order Button
        if(sparam==OrderButton.Name())
           {
            //Print("Order ボタンがクリックされました！");

            OrderPlace(); //発注関数呼び出し

            OrderButton.State(false); //へこんだ状態をもどす
            ChartRedraw();
           }

        // CLICK MTP Button
        if(sparam==MTPButton.Name())
           {
            //Print("MTP button click");

            MtpEnabled = MTPButton.State() ? true : false ;

            if(MtpEnabled)
               {
                // MTPを有効にする
                MTPButton.BackColor(C'0x00,0xF0,0x00'); // ボタンの色を緑に
                MTPEdit.Description(DoubleToString(MtpTargetPips, 1)); // 保存していた価格を表示
                DrawMtpLine();                   // ラインを描画
                //Print("MTP Enabled. Target: ", MtpTargetPips);
               }
            else
               {
                // MTPを無効にする
                MTPButton.BackColor(C'0x90,0x90,0x90'); // ボタンの色を元に戻す
                DeleteMtpLine();                   // ラインを削除
                //Print("MTP Disabled.");
               }

            //MTPButton.State(false);
            ChartRedraw();
           }


        // CLICK CLOSE ALL Button
        if(sparam==CloseAllButton.Name())
           {
            CloseAllPositions();
            CloseAllButton.State(false);
            ChartRedraw();
           }

        // CLICK VTS Button
        if(sparam==VTrailingStopButton.Name())
           {
            VtsEnabled = !VtsEnabled; // フラグを反転

            if(VtsEnabled)
               {
                VTrailingStopButton.BackColor(C'0x00,0xF0,0x00'); // 緑色に
                Print("VTS Enabled. Trailing: ", VtsTrailingPips, " pips, Min Activation: ", VTS_Min_Value, " pips");
                // 有効化時に既存ポジションの状態を再チェックする（任意）
                // InitializeVtsTracking(); // または CheckVtsTrailing() を直接呼んでも良い
               }
            else
               {
                VTrailingStopButton.BackColor(C'0x90,0x90,0x90'); // 元の色に
                Print("VTS Disabled.");
                DeleteAllVtsLines();
                // 無効化時に追跡配列をクリアする必要はない（OnTickで処理されなくなるだけ）
               }
            //VTrailingStopButton.State(false);
            ChartRedraw();
           }

        // CLICK CANCEL ALL ORDER Button
        if(sparam==CancelAllOrderButton.Name())
           {
            CancelAllPendingOrders();
            CancelAllOrderButton.State(false);
            ChartRedraw();
           }
       }


    if(id==CHARTEVENT_OBJECT_ENDEDIT)
       {

        double pipSize = GetPipSize(); // Pipサイズ取得
        string entered_text = ""; // 一時的に入力テキストを格納する変数
        /*

        bool isForex = IsForexSymbol(); // FXシンボルか判定
        double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

        double pipSize = GetPipSize(); // Pipサイズ取得
        if(pipSize <= 0 || point <= 0)
           {
            Print("Event Error: Could not get valid Point or PipSize.");
            pipSize = point > 0 ? point : 0.00001; // エラー回避
           }
        */

        // どのEditボックスが編集されたか判定し、対応するグローバル変数に値を格納
        if(sparam==Lot_Edit.Name())
           {
            extLotSize = StringToDouble(Lot_Edit.Description());
            //Print("Lot size updated: ", extLotSize);
            if(extLotSize <= 0)
               {
                Print("ロット数が不正です。");
                // エラー表示やデフォルト値に戻す等の処理
                extLotSize = 0.01;
                Lot_Edit.Description(DoubleToString(extLotSize,2)); // デフォルトに戻す
                ChartRedraw();
               }
            else
               {
                Lot_Edit.Description(DoubleToString(extLotSize,2)); // デフォルトに戻す
                ChartRedraw();
               }
           }

        if(sparam==Margin_Edit.Name())
           {
            entered_text = Margin_Edit.Description();
            double value = StringToDouble(entered_text);
            if(value <= 0)
               {
                extMargin = 100.0;
                Print("Margin値が不正です。");
                Margin_Edit.Description(DoubleToString(extMargin,1));
                ChartRedraw();
               }
            else
               {
                extMargin = NormalizeDouble(value,1);
                Margin_Edit.Description(DoubleToString(value,1));
                ChartRedraw();
               }
           }

        if(sparam==SL_Edit.Name())
           {
            entered_text = SL_Edit.Description();
            double value = StringToDouble(entered_text);
            if(value < 0)   // SLは0以上
               {
                Print("SL値が不正です。");
                SL_Edit.Description(DoubleToString(extStopLoss,1));
                ChartRedraw();
               }
            else
               {
                extStopLoss = NormalizeDouble(value,1);
                SL_Edit.Description(DoubleToString(value,1));
                ChartRedraw();
               }
           }

        if(sparam==TP_Edit.Name())
           {
            entered_text = TP_Edit.Description();
            double value = StringToDouble(entered_text);
            if(value < 0)   // TPは0以上
               {
                Print("TP値が不正です。");
                TP_Edit.Description(DoubleToString(extTakeProfit, 1));
                ChartRedraw();
               }
            else
               {
                extTakeProfit = NormalizeDouble(value,1);
                TP_Edit.Description(DoubleToString(value, 1));
                ChartRedraw();
               }
           }


        if(sparam==MTPEdit.Name())
           {
            if(MtpEnabled || !MtpEnabled) // MTPが有効なときだけ処理
               {
                string entered_text = MTPEdit.Description();
                double value = StringToDouble(entered_text);
                //int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

                // 簡単なバリデーション（価格が0より大きいか）
                if(value > 0)
                   {
                    MtpTargetPips = NormalizeDouble(value, 1); // 有効な価格を保存
                    MTPEdit.Description(DoubleToString(MtpTargetPips, 1)); // 正規化した値を表示
                    DrawMtpLine(); // ラインを描画/更新
                    Print("MTP Target Price updated: ", MtpTargetPips);

                    // MTPが有効な場合のみ、ラインを更新する
                    if(MtpEnabled)
                       {
                        DrawMtpLine();
                       }
                   }
                else
                   {
                    Print("MTP Target Price is invalid. Please enter a positive value.");
                    // 不正な値の場合、以前の値に戻すか、0.0を表示
                    MTPEdit.Description(DoubleToString(MtpTargetPips, 1));
                   }
               }
            ChartRedraw();
           }

        if(sparam==VTrailingStopEdit.Name())
           {
            string entered_text = VTrailingStopEdit.Description();
            double value = StringToDouble(entered_text);

            // バリデーション (0より大きい値か)
            if(value > 0)
               {
                VtsTrailingPips = NormalizeDouble(value, 1); // 値を保存
                VTrailingStopEdit.Description(DoubleToString(VtsTrailingPips, 1)); // 表示を更新
                Print("VTS Trailing Pips updated: ", VtsTrailingPips);
               }
            else
               {
                Print("VTS Trailing Pips must be greater than 0.");
                // 不正な値の場合は元の値に戻す
                VTrailingStopEdit.Description(DoubleToString(VtsTrailingPips, 1));
               }
            ChartRedraw();
           }

        if(sparam==VTS_Min_Edit.Name())
           {
            string entered_text = VTS_Min_Edit.Description();
            double value = StringToDouble(entered_text);

            // バリデーション (0以上の値か。0も許可)
            if(value >= 0)
               {
                VTS_Min_Value = NormalizeDouble(value, 1); // 値を保存
                VTS_Min_Edit.Description(DoubleToString(VTS_Min_Value, 1)); // 表示を更新
                Print("VTS Min Activation Pips updated: ", VTS_Min_Value);
               }
            else
               {
                Print("VTS Min Activation Pips must be 0 or greater.");
                // 不正な値の場合は元の値に戻す
                VTS_Min_Edit.Description(DoubleToString(VTS_Min_Value, 1));
               }
            ChartRedraw();
           }

       }
   }

//+------------------------------------------------------------------+
//| OnTick                        |
//+------------------------------------------------------------------+
void OnTick()
   {
    UpdatePipPointCounter();

// --- MTPが有効な場合のみ実行 ---
    if(MtpEnabled)
       {
        // 決済チェック (ポジションが存在する場合)
        if(MtpTargetPips > 0 && PositionsTotal() > 0)
           {
            CheckMtpClose();
           }

        // ラインの描画/更新/削除 (ポジション状況に合わせて)
        // (MtpEnabledがtrueの場合のみ DrawMtpLine 内で処理される)
        DrawMtpLine();
       }

    if(VtsEnabled && PositionsTotal() > 0) // VTSが有効でポジションが存在する場合
       {
        CheckVtsTrailing(); // VTSチェック関数を呼び出す
       }
   }

//+------------------------------------------------------------------+
//|OnTimer                                             |
//+------------------------------------------------------------------+
void OnTimer()
   {
//UpdatePipPointCounter();
   }

//+------------------------------------------------------------------+
//| TradeTransaction function                                   |
//+------------------------------------------------------------------+
void OnTradeTransaction(
    const MqlTradeTransaction& trans, // 取引トランザクション情報
    const MqlTradeRequest& request,   // 元の取引リクエスト情報
    const MqlTradeResult& result     // 取引リクエストの結果
)
   {
    long magic_number = 0; //取得したマジックナンバーを保管する変数
    ulong deal_position_id = 0; // 約定に関連するポジションIDを格納する変数 (ulong型で宣言)
    long deal_magic = 0;        // マジックナンバー用
    long deal_entry = 0;        // エントリータイプ用

    if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
       {

        //--- 約定情報を取得 ---
        // trans.deal には約定チケット番号が格納されています
        // HistoryDealSelect で約定情報を選択します
        if(HistoryDealSelect(trans.deal))
           {
            long deal_entry = HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
            deal_position_id = (ulong)HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
            if(deal_entry == DEAL_ENTRY_IN)
               {
                //Print("aaaaa");
                CancelAllPendingOrders();

                if(MtpEnabled)
                   {
                    Print("MTPが有効なため、ラインを再描画します。");
                    DrawMtpLine(); // 新規約定を受けてラインを描画/更新
                   }

                if(VtsEnabled)
                   {
                    Print("VTSが有効なため、ポジション ", deal_position_id, " を追跡開始します。");
                    AddTrackedPosition(deal_position_id); // 正しいポジションIDを渡す
                   }

               }
           }
       }

// --- ポジション決済 (取引タイプで判断) ---
// TRADE_TRANSACTION_DEAL_ADD 以外にも決済を示すタイプがある
// TRADE_TRANSACTION_POSITION (SL/TPヒット時など) や
// TRADE_TRANSACTION_DEAL (手動決済、部分決済など) でもポジションが閉じる可能性がある
// ここではシンプルに、取引後のポジション数をチェックする方法も考えられるが、
// より確実なのは、決済ディールを検出すること。
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD || trans.type == TRADE_TRANSACTION_DEAL_UPDATE) // 決済に関連するディール
       {
        if(HistoryDealSelect(trans.deal))
           {
            long deal_magic = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
            long deal_entry = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
            ulong deal_position_id = HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);

            // このEAのポジションに関する決済ディールか？
            // DEAL_ENTRY_OUT: 通常の決済
            // DEAL_ENTRY_INOUT: 部分決済後のポジション更新 or ドテン
            // DEAL_ENTRY_OUT_BY: 反対ポジションによる決済
            if(deal_magic == MagicNum &&
               (deal_entry == DEAL_ENTRY_OUT || deal_entry == DEAL_ENTRY_INOUT || deal_entry == DEAL_ENTRY_OUT_BY))
               {
                // ポジションが完全に閉じられたかを確認する必要がある
                // PositionSelectByTicket(deal_position_id) で確認するのが確実
                bool position_closed = !PositionSelectByTicket(deal_position_id);

                if(position_closed)
                   {
                    Print("ポジション決済 (DEAL_ENTRY %d) を検知。 Position ID: %d", deal_entry, deal_position_id);
                    // --- ★ここから追加: VTS追跡終了 ---
                    RemoveTrackedPosition(deal_position_id); // 決済されたポジションを追跡リストから削除
                    // --- ★追加ここまで ---
                   }
                else
                   {
                    // 部分決済などでポジションがまだ残っている場合
                    Print("ポジション部分決済または更新 (DEAL_ENTRY %d) を検知。 Position ID: %d", deal_entry, deal_position_id);
                    // 必要であれば追跡情報を更新する処理を追加 (例: VtsPeakPriceリセットなど)
                   }
               }
           }
       }




   }

//+------------------------------------------------------------------+
//| Order Send function                               |
//+------------------------------------------------------------------+
void OrderPlace()
   {
    double Pip = GetPipSize(); //pipサイズを取得。Pointの商品はpointで

// --- 1. 入力値の最終確認 (グローバル変数から読み込み) ---
// OnChartEventで入力チェック済みだが、念のためここでも確認可能
    if(extLotSize <= 0 || extMargin <= 0 || extStopLoss < 0 || extTakeProfit < 0)
       {
        Print("注文パラメータが不正です。Lot:", extLotSize, " Margin:", extMargin, " SL:", extStopLoss, " TP:", extTakeProfit);
        MessageBox("注文パラメータが不正です。\nUIの入力値を確認してください。", "注文エラー", MB_OK | MB_ICONWARNING);
        return; // 処理中断
       }

// --- 2. シンボル情報の取得 ---
    string symbol = _Symbol; // 現在のチャートのシンボル
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT); // 1 Point の価格変動幅
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS); // 価格の小数点以下の桁数
    int stopsLevel = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL); // ストップレベル(Point)

// Marginがストップレベルより小さい場合は警告して中断
    if(extMargin <= stopsLevel)
       {
        Print("Margin値(", extMargin, ")がストップレベル(", stopsLevel, ")以下です。注文できません。");
        MessageBox("Margin (Point)の値が小さすぎます。\nストップレベル: " + (string)stopsLevel + " Point以上必要です。", "注文エラー", MB_OK | MB_ICONWARNING);
        return;
       }

// --- 3. 現在価格の取得 ---
    MqlTick currentTick;
    if(!SymbolInfoTick(symbol, currentTick))
       {
        Print("Tick情報の取得に失敗しました。 Error: ", GetLastError());
        MessageBox("最新価格の取得に失敗しました。", "注文エラー", MB_OK | MB_ICONERROR);
        return;
       }
    double ask = currentTick.ask; // 現在のAsk価格
    double bid = currentTick.bid; // 現在のBid価格

// --- 4. 注文価格・SL/TP価格の計算 ---
// BuyStop注文用
    double buyStopPrice = ask + extMargin * Pip;
    double buySL = (extStopLoss > 0) ? buyStopPrice - extStopLoss * Pip : 0.0;
    double buyTP = (extTakeProfit > 0) ? buyStopPrice + extTakeProfit * Pip : 0.0;

// SellStop注文用
    double sellStopPrice = bid - extMargin * Pip;
    double sellSL = (extStopLoss > 0) ? sellStopPrice + extStopLoss * Pip : 0.0;
    double sellTP = (extTakeProfit > 0) ? sellStopPrice - extTakeProfit * Pip : 0.0;

// --- 5. 価格の正規化 ---
// ブローカーが受け付ける桁数に価格を丸める
    buyStopPrice = NormalizeDouble(buyStopPrice, digits);
    sellStopPrice = NormalizeDouble(sellStopPrice, digits);
    if(buySL > 0)
        buySL = NormalizeDouble(buySL, digits);
    if(buyTP > 0)
        buyTP = NormalizeDouble(buyTP, digits);
    if(sellSL > 0)
        sellSL = NormalizeDouble(sellSL, digits);
    if(sellTP > 0)
        sellTP = NormalizeDouble(sellTP, digits);


// --- 6. 注文コメントの作成 ---
//string comment = "EA Order (" + symbol + ") " + oco_comment_tag;

// --- 7. BuyStop注文の発行 ---
    Print("--- BuyStop注文発行試行 ");
    Print("Lot:", extLotSize, " Price:", DoubleToString(buyStopPrice, digits),
          " SL:", (buySL > 0 ? DoubleToString(buySL, digits) : "N/A"),
          " TP:", (buyTP > 0 ? DoubleToString(buyTP, digits) : "N/A"));

    bool buyResult = trade.BuyStop(extLotSize, buyStopPrice, _Symbol, buySL, buyTP, ORDER_TIME_GTC, 0);
    ulong buyTicket = 0; // 発注した注文のチケット番号を保存
    if(buyResult)
       {
        buyTicket = trade.ResultOrder();
        Print("BuyStop注文が正常に送信されました。 Ticket: ", trade.ResultOrder());
       }
    else
       {
        Print("BuyStop注文の送信に失敗しました。 Retcode: ", trade.ResultRetcode(), ", Comment: ", trade.ResultComment());
        MessageBox("BuyStop注文に失敗しました。\n理由: " + trade.ResultComment(), "注文エラー", MB_OK | MB_ICONERROR);
        // 片方失敗したらもう片方も送らない場合はここで return する
        return;
       }

// --- 8. SellStop注文の発行 ---
// 短時間に連続注文する場合、少し待機を入れると安定することがあります
//Sleep(5); // 200ミリ秒待機 (必要に応じて調整)

    Print("--- SellStop注文発行試行");
    Print("Lot:", extLotSize, " Price:", DoubleToString(sellStopPrice, digits),
          " SL:", (sellSL > 0 ? DoubleToString(sellSL, digits) : "N/A"),
          " TP:", (sellTP > 0 ? DoubleToString(sellTP, digits) : "N/A"));

    bool sellResult = trade.SellStop(extLotSize, sellStopPrice, _Symbol, sellSL, sellTP, ORDER_TIME_GTC, 0);
    ulong sellTicket = 0; // 発注した注文のチケット番号を保存
    if(sellResult)
       {
        sellTicket = trade.ResultOrder();
        Print("SellStop注文が正常に送信されました。 Ticket: ", trade.ResultOrder());
       }
    else
       {
        Print("SellStop注文の送信に失敗しました。 Retcode: ", trade.ResultRetcode(), ", Comment: ", trade.ResultComment());
        MessageBox("SellStop注文に失敗しました。\n理由: " + trade.ResultComment(), "注文エラー", MB_OK | MB_ICONERROR);
        // SellStopが失敗した場合、先に成功したBuyStopをキャンセルする (任意)
        if(buyTicket > 0)
           {
            Print("先に送信したBuyStop注文 (Ticket: ", buyTicket, ") をキャンセルします。");
            trade.OrderDelete(buyTicket);
           }
       }
    ChartRedraw();
   }

//+------------------------------------------------------------------+
//| Pip size取得関数                                            |
//+------------------------------------------------------------------+
double GetPipSize()
   {
// シンボル情報を取得
    int calc_mode = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
    double pointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

// Pointサイズが無効な場合は基本的なチェック
    if(pointSize <= 0)
       {
        PrintFormat("Warning: Invalid SYMBOL_POINT (%.*f) for %s. Returning 0.", digits, pointSize, _Symbol);
        return 0.0;
       }

    double pipSize = 0.0;

// --- Code B の CALC_MODE による分岐を採用 ---
    if(calc_mode == SYMBOL_CALC_MODE_FOREX || calc_mode == SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE)
       {
        // --- FX系の処理: Code A の正しいロジックを採用 ---
        if(digits == 3 || digits == 5)  // JPY系3桁 (123.456) または 非JPY系5桁 (1.23456)
           {
            pipSize = pointSize * 10.0;
           }
        else
            if(digits == 2 || digits == 4)  // JPY系2桁 (123.45) または 非JPY系4桁 (1.2345)
               {
                pipSize = pointSize;
               }
            else // FXカテゴリだが標準外の桁数の場合 (念のためPointを返す)
               {
                pipSize = pointSize;
                // 必要なら警告メッセージを表示
                // PrintFormat("Warning: Unusual digits (%d) for Forex symbol %s. Using PointSize as PipSize.", digits, _Symbol);
               }
       }
// --- それ以外の計算モード (CFD, Futures, Stock, etc.) ---
    else
       {
        // --- Code B の TickSize を返すロジックを基本とするが、Code A の堅牢性を加える ---
        // TickSizeが有効であればそれを採用
        if(tickSize > 0)
           {
            pipSize = tickSize;
           }
        // TickSizeが無効ならPointをフォールバック (安全策)
        else
           {
            pipSize = pointSize;
            // 必要なら警告メッセージを表示
            // PrintFormat("Warning: Invalid SYMBOL_TRADE_TICK_SIZE (%.*f) for non-Forex symbol %s. Using PointSize as fallback.", digits, tickSize, _Symbol);
           }
       }

// 念のため、計算されたPipSizeがPointSizeより小さくならないようにする
// (TickSize が PointSize より小さい特殊ケースへの対応)
    if(pipSize < pointSize)
       {
        // TickSize が有効で PointSize より小さい場合は、TickSize を優先すべきか検討
        // ここでは安全策として、PointSize を下回らないように調整する
        // PrintFormat("Warning: Calculated PipSize (%.*f) was smaller than PointSize (%.*f) for %s. Adjusted to PointSize.", digits, pipSize, digits, pointSize, _Symbol);
        pipSize = pointSize;
       }


// --- Code A 同様、最後に NormalizeDouble を適用 (重要!) ---
    return NormalizeDouble(pipSize, digits);
   }

//+------------------------------------------------------------------+
//|  PIP/POINTカウンター更新関数                                  |
//+------------------------------------------------------------------+
void UpdatePipPointCounter()
   {
// ここに PIP_POINT_COUNTER ラベルを更新する処理を実装
// 例: 現在の保有ポジションの合計損益(Point)を計算して表示するなど
    double totalProfitPoints = 0;
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    if(point <= 0)
        point = 0.00001; // ゼロ除算回避

    for(int i = PositionsTotal() - 1; i >= 0; i--)
       {

        //この１．２を飛ばしたせいで、なかなかてこずった。明示的にしっかり書くことの大切さ。。。。

        // 1. ループ内でポジションのチケット番号を取得
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) // チケット番号が取得できなければスキップ
            continue;
        // 2. チケット番号でポジションを選択
        if(!PositionSelectByTicket(ticket))
            continue; // ポジション選択に失敗したらスキップ

        if(PositionGetInteger(POSITION_MAGIC) == MagicNum && PositionGetString(POSITION_SYMBOL) == _Symbol)
           {
            double openPrice = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),_Digits);
            //Print(openPrice);
            double currentPrice = 0;
            long type = PositionGetInteger(POSITION_TYPE); // 0:BUY, 1:SELL
            MqlTick tick;
            if(SymbolInfoTick(_Symbol, tick))
               {
                currentPrice = (type == POSITION_TYPE_BUY) ? tick.bid : tick.ask;
                double CurrentPrice = NormalizeDouble(currentPrice,_Digits);
                if(CurrentPrice > 0 && openPrice > 0)
                   {
                    totalProfitPoints += ((type == POSITION_TYPE_BUY ? 1 : -1) * (CurrentPrice - openPrice)) / PIP;
                    //totalProfitPoints = (currentPrice - openPrice) / PIP;
                   }
               }
           }
       }

// カウンターラベル更新
    string profitStr = DoubleToString(totalProfitPoints, 1); // 小数点以下1桁で表示
    PIP_POINT_COUNTER.Description(profitStr);
// 損益に応じて色を変えるなど
    if(totalProfitPoints > 0)
        PIP_POINT_COUNTER.Color(clrLime);
    else
        if(totalProfitPoints < 0)
            PIP_POINT_COUNTER.Color(clrRed);
        else
            PIP_POINT_COUNTER.Color(clrWhite);

//ChartRedraw(); // OnTick内で毎回ChartRedrawは重いので必要な時だけ呼ぶか、OnTimerを使う。
   }

//+------------------------------------------------------------------+
//| すべての未約定オーダーをキャンセルする関数                          |
//+------------------------------------------------------------------+
void CancelAllPendingOrders()
   {
// 未約定のオーダー数を取得します
    int totalOrders = OrdersTotal();

// オーダーがなければ何もしません
    if(totalOrders <= 0)
       {
        //Print("キャンセルする未約定オーダーはありません。");
        return; // 関数を終了します
       }

//PrintFormat("未約定オーダー数: %d。全キャンセルを開始します...", totalOrders);

// 未約定オーダーを一つずつ確認していきます
// 後ろからループするのが安全です（キャンセルするとオーダーの順番が変わることがあるため）
    for(int i = totalOrders - 1; i >= 0; i--)
       {
        // i番目のオーダーのチケット番号（固有ID）を取得します
        // PositionGetTicketではなく、OrderGetTicketを使います
        ulong ticket = OrderGetTicket(i);
        if(ticket > 0) // チケット番号が取得できたら
           {
            if(OrderSelect(ticket))
               {
                long magic = OrderGetInteger(ORDER_MAGIC);
                if(magic == MagicNum)
                   {
                    // チケット番号を使って、そのオーダーをキャンセルします
                    // trade.OrderDelete(チケット番号) でキャンセルを実行します
                    if(!trade.OrderDelete(ticket))
                       {
                        Print("ticket",ticket);
                        // キャンセルに失敗した場合の処理
                        PrintFormat("オーダーキャンセル失敗: チケット %d, エラーコード %d - %s",
                                    ticket,
                                    trade.ResultRetcode(), // 直前の取引操作の結果コード
                                    trade.ResultComment()  // 直前の取引操作の結果コメント
                                   );
                       }
                    else
                       {
                        // キャンセルに成功した場合の処理
                        PrintFormat("オーダーキャンセル成功: チケット %d, 結果: %s",
                                    ticket,
                                    trade.ResultComment()
                                   );
                       }
                   }
                //Sleep(10); // 100ミリ秒待機
               }
           }
       }
    ChartRedraw();
    Print("全未約定オーダーのキャンセル処理が完了しました。");
   }

//+------------------------------------------------------------------+
//| すべてのポジションを決済する関数                                     |
//+------------------------------------------------------------------+
void CloseAllPositions()
   {
// 保유しているポジションの数を取得します
    int totalPositions = PositionsTotal();

// ポジションがなければ何もしません
    if(totalPositions <= 0)
       {
        Print("決済するポジションはありません。");
        return; // 関数を終了します
       }

//PrintFormat("保有ポジション数: %d。全決済を開始します...", totalPositions);


// 保有ポジションを一つずつ確認していきます
// 後ろからループするのが安全です（決済するとポジションの順番が変わることがあるため）
    for(int i = totalPositions - 1; i >= 0; i--)
       {
        // i番目のポジションのチケット番号（固有ID）を取得します
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0) // チケット番号が取得できたら
           {
            if(PositionSelectByTicket(ticket))
               {
                long magic = PositionGetInteger(POSITION_MAGIC);
                if(magic == MagicNum)
                   {
                    // チケット番号を使って、そのポジションを決済します
                    // trade.PositionClose(チケット番号) で決済を実行します
                    if(!trade.PositionClose(ticket))
                       {
                        // 決済に失敗した場合の処理
                        PrintFormat("ポジション決済失敗: チケット %d, エラーコード %d - %s",
                                    ticket,
                                    trade.ResultRetcode(), // 直前の取引操作の結果コード
                                    trade.ResultComment()  // 直前の取引操作の結果コメント
                                   );
                        // 必要であれば、ここでリトライ処理などを追加できます
                       }
                    else
                       {
                        // 決済に成功した場合の処理
                        PrintFormat("ポジション決済成功: チケット %d, 結果: %s",
                                    ticket,
                                    trade.ResultComment()
                                   );
                       }
                    // 少し待機して、サーバーへの負荷を軽減します
                    //Sleep(100); // 100ミリ秒待機
                   }
               }
           }
       }
    Print("全ポジションの決済処理が完了しました。");
   }


//+------------------------------------------------------------------+
//| MTPラインを描画/更新する関数                                     |
//+------------------------------------------------------------------+
void DrawMtpLine()
   {
// MTPが無効、または目標PIP数が0以下、またはPIPサイズが取得できない場合はラインを消す
    if(!MtpEnabled)
       {
        DeleteMtpLine();
        return;
       }

// 目標PIP数が0以下、またはPIPサイズが取得できない場合はラインを消す
    if(MtpTargetPips <= 0 || PIP <= 0)
       {
        DeleteMtpLine();
        return;
       }

// --- 基準となるポジションを探す ---
    ulong latest_ticket = 0;
    double base_price = 0.0;
    long base_type = -1; // 0:BUY, 1:SELL
    int total_positions = PositionsTotal();
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

    for(int i = total_positions - 1; i >= 0; i--)
       {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0)
            continue;

        if(PositionSelectByTicket(ticket) &&
           PositionGetInteger(POSITION_MAGIC) == MagicNum &&
           PositionGetString(POSITION_SYMBOL) == _Symbol)
           {
            // 最後のポジション（ループの最初に見つかる）を基準とする
            latest_ticket = ticket;
            base_price = PositionGetDouble(POSITION_PRICE_OPEN);
            base_type = PositionGetInteger(POSITION_TYPE);
            break; // 基準ポジションが見つかったらループを抜ける
           }
       }

// 基準となるポジションが見つからない場合はラインを消す
    if(latest_ticket == 0)
       {
        DeleteMtpLine();
        return;
       }
// --- ポジション検索ここまで ---

// --- 目標価格を計算 ---
    double target_price = 0.0;
    if(base_type == POSITION_TYPE_BUY)
       {
        target_price = base_price + MtpTargetPips * PIP;
       }
    else
        if(base_type == POSITION_TYPE_SELL)
           {
            target_price = base_price - MtpTargetPips * PIP;
           }
        else
           {
            // 万が一タイプが不正ならラインを消す
            DeleteMtpLine();
            return;
           }
    target_price = NormalizeDouble(target_price, digits); // 価格を正規化


// --- ライン描画/更新 ---
    if(ObjectFind(0, MTP_Line_Name) < 0)
       {
        // 新規作成
        if(!ObjectCreate(0, MTP_Line_Name, OBJ_HLINE, 0, 0, target_price))
           {
            Print("Failed to create MTP line. Error: ", GetLastError());
            return;
           }
        ObjectSetInteger(0, MTP_Line_Name, OBJPROP_COLOR, clrViolet);
        ObjectSetInteger(0, MTP_Line_Name, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, MTP_Line_Name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, MTP_Line_Name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, MTP_Line_Name, OBJPROP_BACK, true);
        ObjectSetString(0, MTP_Line_Name, OBJPROP_TOOLTIP, "Manual TP (" + DoubleToString(MtpTargetPips, 1) + " pips)"); // ツールチップにPIP数表示
       }
    else
       {
        // 移動
        if(!ObjectMove(0, MTP_Line_Name, 0, 0, target_price))
           {
            Print("Failed to move MTP line. Error: ", GetLastError());
           }
        // ツールチップも更新 (PIP数が変わる可能性があるため)
        ObjectSetString(0, MTP_Line_Name, OBJPROP_TOOLTIP, "Manual TP (" + DoubleToString(MtpTargetPips, 1) + " pips)");
       }
    ChartRedraw();
   }

//+------------------------------------------------------------------+
//| MTPラインを削除する関数                                        |
//+------------------------------------------------------------------+
void DeleteMtpLine()
   {
    if(ObjectFind(0, MTP_Line_Name) >= 0) // ラインが存在する場合のみ削除
       {
        ObjectDelete(0, MTP_Line_Name);
        ChartRedraw(); // 削除後にチャートを更新
       }
   }

//+------------------------------------------------------------------+
//| MTP決済条件をチェックし、該当すれば決済する関数                     |
//+------------------------------------------------------------------+
void CheckMtpClose()
   {
// MTPが無効、または目標PIP数が0以下、またはPIPサイズが取得できない場合は何もしない
    if(!MtpEnabled || MtpTargetPips <= 0 || PIP <= 0)
       {
        return;
       }

    string currentSymbol = _Symbol;
    int digits = (int)SymbolInfoInteger(currentSymbol, SYMBOL_DIGITS);
    if(digits <= 0)
        return;

    MqlTick currentTick;
    if(!SymbolInfoTick(currentSymbol, currentTick))
       {
        return;
       }
    double ask = NormalizeDouble(currentTick.ask, digits);
    double bid = NormalizeDouble(currentTick.bid, digits);

    for(int i = PositionsTotal() - 1; i >= 0; i--)
       {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0)
            continue;

        if(PositionSelectByTicket(ticket) &&
           PositionGetInteger(POSITION_MAGIC) == MagicNum &&
           PositionGetString(POSITION_SYMBOL) == currentSymbol)
           {
            long positionType = PositionGetInteger(POSITION_TYPE);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);

            // --- 各ポジションの目標決済価格を計算 ---
            double targetClosePrice = 0.0;
            if(positionType == POSITION_TYPE_BUY)
               {
                targetClosePrice = openPrice + MtpTargetPips * PIP;
               }
            else
                if(positionType == POSITION_TYPE_SELL)
                   {
                    targetClosePrice = openPrice - MtpTargetPips * PIP;
                   }
                else
                    continue; // 不正なタイプはスキップ

            targetClosePrice = NormalizeDouble(targetClosePrice, digits); // 正規化
            // --- 計算ここまで ---

            // --- 決済条件のチェック ---
            bool closeCondition = false;
            if(positionType == POSITION_TYPE_BUY && bid >= targetClosePrice) // 買い: Bidが目標価格以上
               {
                closeCondition = true;
               }
            else
                if(positionType == POSITION_TYPE_SELL && ask <= targetClosePrice) // 売り: Askが目標価格以下
                   {
                    closeCondition = true;
                   }
            // --- チェックここまで ---

            if(closeCondition)
               {
                PrintFormat("MTP Triggered: Closing position #%d (%s). Target Pips: %.1f. Open: %s, Target: %s, Current: %s",
                            ticket,
                            (positionType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                            MtpTargetPips,
                            DoubleToString(openPrice, digits),
                            DoubleToString(targetClosePrice, digits),
                            (positionType == POSITION_TYPE_BUY ? DoubleToString(bid, digits) : DoubleToString(ask, digits))
                           );

                if(!trade.PositionClose(ticket))
                   {
                    PrintFormat("MTP Close Failed: Ticket %d, Error %d - %s",
                                ticket, trade.ResultRetcode(), trade.ResultComment());
                   }
                else
                   {
                    PrintFormat("MTP Close Success: Ticket %d, Result: %s",
                                ticket, trade.ResultComment());
                    // 必要なら決済後にMTPを無効化する処理などをここに追加
                    // 決済したらラインも消す場合など
                    DeleteMtpLine(); // 決済したらラインも消す
                    // DrawMtpLine(); // 決済後、残りのポジション基準でラインを再描画する場合
                   }
                Sleep(100);
               }
           }
       }
   }

//+------------------------------------------------------------------+
//| VTS追跡用配列と既存ポジションの初期化関数                         |
//+------------------------------------------------------------------+
void InitializeVtsTracking()
   {
// 配列をクリア
    ArrayResize(VtsTrackedTickets, 0);
    ArrayResize(VtsPeakPrice, 0);
    ArrayResize(VtsActivated, 0);
    ArrayResize(VtsDigits, 0);
    ArrayResize(VtsPipSize, 0);

// 現在保有しているポジションをループ
    for(int i = PositionsTotal() - 1; i >= 0; i--)
       {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0)
            continue;

        // マジックナンバーとシンボルでフィルタリング (シンボルは AddTrackedPosition 内で取得)
        if(PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == MagicNum)
           {
            AddTrackedPosition(ticket); // 既存ポジションを追跡対象に追加
           }
       }
    Print("VTS Tracking Initialized. Tracking ", ArraySize(VtsTrackedTickets), " positions.");
   }

//+------------------------------------------------------------------+
//| VTS追跡対象にポジションを追加する関数                             |
//+------------------------------------------------------------------+
void AddTrackedPosition(ulong ticket)
   {
// すでに追加されていないかチェック
    for(int i = 0; i < ArraySize(VtsTrackedTickets); i++)
       {
        if(VtsTrackedTickets[i] == ticket)
           {
            // Print("Position ", ticket, " is already tracked for VTS.");
            return; // すでに追加済み
           }
       }

// ポジション情報を取得
    if(!PositionSelectByTicket(ticket))
       {
        Print("Failed to select position ", ticket, " in AddTrackedPosition.");
        return;
       }

    string symbol = PositionGetString(POSITION_SYMBOL);
    long positionType = PositionGetInteger(POSITION_TYPE);
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double pipSize = GetPipSizeSymbol(symbol); // シンボル指定版のGetPipSize

    if(pipSize <= 0)
       {
        Print("Failed to get PipSize for symbol ", symbol, " in AddTrackedPosition.");
        return;
       }

// 配列サイズを拡張
    int newSize = ArraySize(VtsTrackedTickets) + 1;
    ArrayResize(VtsTrackedTickets, newSize);
    ArrayResize(VtsPeakPrice, newSize);
    ArrayResize(VtsActivated, newSize);
    ArrayResize(VtsDigits, newSize);
    ArrayResize(VtsPipSize, newSize);

// 新しい要素に情報を格納
    int index = newSize - 1;
    VtsTrackedTickets[index] = (long)ticket;
    VtsPeakPrice[index] = openPrice; // 初期値として約定価格を設定
    VtsActivated[index] = false;    // 最初はVTS未発動
    VtsDigits[index] = digits;
    VtsPipSize[index] = pipSize;

    Print("Added position ", ticket, " (", symbol, ") to VTS tracking. Type: ", (positionType == POSITION_TYPE_BUY ? "BUY" : "SELL"));
   }


//+------------------------------------------------------------------+
//| VTS追跡対象からポジションを削除する関数                           |
//+------------------------------------------------------------------+
void RemoveTrackedPosition(ulong ticket)
   {
    int indexToRemove = -1;
    int currentSize = ArraySize(VtsTrackedTickets);

// 削除対象のインデックスを探す
    for(int i = 0; i < currentSize; i++)
       {
        if(VtsTrackedTickets[i] == ticket)
           {
            indexToRemove = i;
            break;
           }
       }

// 見つからなかったら終了
    if(indexToRemove == -1)
       {
        // Print("Position ", ticket, " not found in VTS tracking for removal.");
        return;
       }

    DeleteVtsLine(ticket);

// 配列から要素を削除 (最後の要素を削除位置に移動し、サイズを縮小)
    if(currentSize > 1 && indexToRemove < currentSize - 1)
       {
        VtsTrackedTickets[indexToRemove] = VtsTrackedTickets[currentSize - 1];
        VtsPeakPrice[indexToRemove] = VtsPeakPrice[currentSize - 1];
        VtsActivated[indexToRemove] = VtsActivated[currentSize - 1];
        VtsDigits[indexToRemove] = VtsDigits[currentSize - 1];
        VtsPipSize[indexToRemove] = VtsPipSize[currentSize - 1];
       }

// 配列サイズを縮小
    int newSize = currentSize - 1;
    ArrayResize(VtsTrackedTickets, newSize);
    ArrayResize(VtsPeakPrice, newSize);
    ArrayResize(VtsActivated, newSize);
    ArrayResize(VtsDigits, newSize);
    ArrayResize(VtsPipSize, newSize);

    Print("Removed position ", ticket, " from VTS tracking.");
   }

//+------------------------------------------------------------------+
//| 指定シンボルのPipサイズ取得関数                                   |
//+------------------------------------------------------------------+
double GetPipSizeSymbol(string sym)
   {
    int calc_mode = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_CALC_MODE);
    double pointSize = SymbolInfoDouble(sym, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
    double tickSize = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);

    if(pointSize <= 0)
        return 0.0;

    double pipSize = 0.0;

    if(calc_mode == SYMBOL_CALC_MODE_FOREX || calc_mode == SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE)
       {
        if(digits == 3 || digits == 5)
            pipSize = pointSize * 10.0;
        else
            if(digits == 2 || digits == 4)
                pipSize = pointSize;
            else
                pipSize = pointSize;
       }
    else
       {
        if(tickSize > 0)
            pipSize = tickSize;
        else
            pipSize = pointSize;
       }

    if(pipSize < pointSize)
        pipSize = pointSize;

    return NormalizeDouble(pipSize, digits);
   }

//+------------------------------------------------------------------+
//| VTSトレーリングストップを実行する関数                             |
//+------------------------------------------------------------------+
void CheckVtsTrailing()
   {
// VTSが無効なら何もしない
    if(!VtsEnabled)
        return;

// 追跡中のポジションをループ
    int trackedCount = ArraySize(VtsTrackedTickets);
    for(int i = trackedCount - 1; i >= 0; i--) // 後ろから回す（削除時のインデックスずれを防ぐ）
       {
        ulong ticket = VtsTrackedTickets[i];

        // ポジションが存在するか再確認 (決済直後などでリストに残っている場合があるため)
        if(!PositionSelectByTicket(ticket))
           {
            // ポジションがないのにリストに残っている -> 削除
            Print("Position ", ticket, " not found, removing from VTS tracking (sync).");
            DeleteVtsLine(ticket);
            RemoveTrackedPosition(ticket);
            continue; // 次の追跡対象へ
           }

        // ポジション情報を取得 (マジックナンバーはOnInit/Addでチェック済みのはずだが念のため)
        if(PositionGetInteger(POSITION_MAGIC) != MagicNum)
            continue;

        long positionType = PositionGetInteger(POSITION_TYPE);
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        string symbol = PositionGetString(POSITION_SYMBOL);

        // 配列から必要な情報を取得
        double peakPrice = VtsPeakPrice[i];
        bool activated = VtsActivated[i];
        int digits = VtsDigits[i];
        double pipSize = VtsPipSize[i];

        if(pipSize <= 0) // Pipサイズが無効ならスキップ
           {
            Print("Invalid PipSize for position ", ticket, " symbol ", symbol, ". Skipping VTS check.");
            DeleteVtsLine(ticket);
            continue;
           }


        // 現在価格を取得
        MqlTick currentTick;
        if(!SymbolInfoTick(symbol, currentTick))
            continue; // Tick取得失敗ならスキップ
        double currentAsk = NormalizeDouble(currentTick.ask, digits);
        double currentBid = NormalizeDouble(currentTick.bid, digits);
        double currentClosePrice = (positionType == POSITION_TYPE_BUY) ? currentBid : currentAsk; // 決済に使われる価格
        double currentTrailPrice = (positionType == POSITION_TYPE_BUY) ? currentBid : currentAsk; // トレーリング基準価格

        // --- 1. VTS発動チェック (まだ発動していない場合) ---
        if(!activated)
           {
            double currentProfitPips = 0;
            if(positionType == POSITION_TYPE_BUY)
               {
                currentProfitPips = (currentClosePrice - openPrice) / pipSize;
               }
            else // SELL
               {
                currentProfitPips = (openPrice - currentClosePrice) / pipSize;
               }

            // 最低利益PIP数を超えたか？
            if(currentProfitPips >= VTS_Min_Value)
               {
                VtsActivated[i] = true; // 発動フラグを立てる
                VtsPeakPrice[i] = currentTrailPrice; // 発動時の価格を最初のピーク価格とする
                activated = true; // ローカル変数も更新
                peakPrice = VtsPeakPrice[i]; // ローカル変数も更新
                Print("VTS Activated for position ", ticket, ". Profit: ", DoubleToString(currentProfitPips, 1), " pips >= Min: ", VTS_Min_Value, " pips. Initial Peak: ", DoubleToString(peakPrice, digits));
                double initialStopLossPrice = (positionType == POSITION_TYPE_BUY) ? peakPrice - VtsTrailingPips * pipSize : peakPrice + VtsTrailingPips * pipSize;
                DrawVtsLine(ticket, NormalizeDouble(initialStopLossPrice, digits), digits);
               }
            else
               {
                DeleteVtsLine(ticket);
                // まだ最低利益に達していない -> このポジションの処理は終了
                continue;
               }
           }

        // --- 2. 最高値/最安値の更新 (VTS発動済みの場合) ---
        if(activated)
           {
            bool peakUpdated = false;
            if(positionType == POSITION_TYPE_BUY && currentTrailPrice > peakPrice)
               {
                VtsPeakPrice[i] = currentTrailPrice;
                peakPrice = currentTrailPrice; // ローカル変数も更新
                peakUpdated = true;
               }
            else
                if(positionType == POSITION_TYPE_SELL && currentTrailPrice < peakPrice)
                   {
                    VtsPeakPrice[i] = currentTrailPrice;
                    peakPrice = currentTrailPrice; // ローカル変数も更新
                    peakUpdated = true;
                   }
            if(peakUpdated)
               {
                double updatedStopLossPrice = (positionType == POSITION_TYPE_BUY) ? peakPrice - VtsTrailingPips * pipSize : peakPrice + VtsTrailingPips * pipSize;
                DrawVtsLine(ticket, NormalizeDouble(updatedStopLossPrice, digits), digits);
                // Print("VTS Peak updated for position ", ticket, " to ", DoubleToString(peakPrice, digits), ". New SL: ", DoubleToString(updatedStopLossPrice, digits));
               }

           }

        // --- 3. 決済チェック (VTS発動済みの場合) ---
        if(activated)
           {
            double stopLossPrice = 0;
            bool closeCondition = false;

            // トレーリングストップ価格を計算
            if(positionType == POSITION_TYPE_BUY)
               {
                stopLossPrice = peakPrice - VtsTrailingPips * pipSize;
                stopLossPrice = NormalizeDouble(stopLossPrice, digits);
                if(currentClosePrice <= stopLossPrice) // 現在のBidがSL価格以下になったら決済
                   {
                    closeCondition = true;
                   }
               }
            else // SELL
               {
                stopLossPrice = peakPrice + VtsTrailingPips * pipSize;
                stopLossPrice = NormalizeDouble(stopLossPrice, digits);
                if(currentClosePrice >= stopLossPrice) // 現在のAskがSL価格以上になったら決済
                   {
                    closeCondition = true;
                   }
               }

            // 決済条件を満たしたら決済実行
            if(closeCondition)
               {
                PrintFormat("VTS Triggered: Closing position #%d (%s). Peak: %s, Trail: %.1f pips, SL Price: %s, Current: %s",
                            ticket,
                            (positionType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                            DoubleToString(peakPrice, digits),
                            VtsTrailingPips,
                            DoubleToString(stopLossPrice, digits),
                            DoubleToString(currentClosePrice, digits)
                           );

                DeleteVtsLine(ticket);

                if(!trade.PositionClose(ticket))
                   {
                    PrintFormat("VTS Close Failed: Ticket %d, Error %d - %s",
                                ticket, trade.ResultRetcode(), trade.ResultComment());
                   }
                else
                   {
                    PrintFormat("VTS Close Success: Ticket %d, Result: %s",
                                ticket, trade.ResultComment());
                    // 決済成功したら追跡リストから削除 (ループ中で削除するので注意が必要だが、後ろからループしているので安全)
                    RemoveTrackedPosition(ticket);
                    // 決済したらこのループの今回の処理は終了 (continueは不要、ループは続く)
                   }
                Sleep(100); // 連続決済を防ぐための短い待機（任意）
               }
           }
       } // end for loop tracking positions
   }

//+------------------------------------------------------------------+
//| 指定チケット番号のVTSラインを描画/更新する関数                    |
//+------------------------------------------------------------------+
void DrawVtsLine(ulong ticket, double price, int digits)
   {
// VTSが無効なら描画しない
    if(!VtsEnabled)
       {
        DeleteVtsLine(ticket); // 念のため削除
        return;
       }

    string line_name = VTS_Line_BaseName + (string)ticket;

    if(ObjectFind(0, line_name) < 0)
       {
        // 新規作成
        if(!ObjectCreate(0, line_name, OBJ_HLINE, 0, 0, price))
           {
            Print("Failed to create VTS line for ticket ", ticket, ". Error: ", GetLastError());
            return;
           }
        ObjectSetInteger(0, line_name, OBJPROP_COLOR, clrOrange);    // オレンジ色
        ObjectSetInteger(0, line_name, OBJPROP_STYLE, STYLE_DASH);   // 破線
        ObjectSetInteger(0, line_name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, line_name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, line_name, OBJPROP_BACK, true);
        ObjectSetString(0, line_name, OBJPROP_TOOLTIP, "VTS SL (" + (string)ticket + ")");
       }
    else
       {
        // 移動
        if(!ObjectMove(0, line_name, 0, 0, price))
           {
            Print("Failed to move VTS line for ticket ", ticket, ". Error: ", GetLastError());
           }
       }
// ChartRedraw(); // OnTick内で頻繁に呼ばれるため、ここでのChartRedrawは避ける
   }

//+------------------------------------------------------------------+
//| 指定チケット番号のVTSラインを削除する関数                         |
//+------------------------------------------------------------------+
void DeleteVtsLine(ulong ticket)
   {
    string line_name = VTS_Line_BaseName + (string)ticket;
    if(ObjectFind(0, line_name) >= 0)
       {
        ObjectDelete(0, line_name);
        // ChartRedraw(); // 個別削除ではChartRedrawしない（まとめて行う）
       }
   }

//+------------------------------------------------------------------+
//| 表示されている全てのVTSラインを削除する関数                       |
//+------------------------------------------------------------------+
void DeleteAllVtsLines()
   {
// 追跡中のチケットに基づいて削除
    int trackedCount = ArraySize(VtsTrackedTickets);
    for(int i = 0; i < trackedCount; i++)
       {
        DeleteVtsLine(VtsTrackedTickets[i]);
       }
// または、オブジェクト名で検索して削除する方法もある
// for(int i = ObjectsTotal(0, -1, OBJ_HLINE) - 1; i >= 0; i--) {
//     string name = ObjectName(0, i, -1, OBJ_HLINE);
//     if (StringFind(name, VTS_Line_BaseName) == 0) {
//         ObjectDelete(0, name);
//     }
// }
    ChartRedraw(); // まとめて削除した後に再描画
   }
//+------------------------------------------------------------------+
