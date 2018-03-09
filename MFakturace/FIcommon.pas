unit FIcommon;
// 27.1.17 vyèlenìna procedura AktualizaceView jen pro DES

interface

uses
  Windows, SysUtils, Classes, Forms, Controls, DateUtils, Math, Registry, AdvGrid;

type
  TdmCommon = class(TDataModule)
  public
    function UserName: AnsiString;
    function CompName: AnsiString;
    function IndexByName(DataObject: variant; Name: ShortString): integer;
    procedure Zprava(TextZpravy: string);
    procedure AktualizaceView;
    procedure Plneni_asgMain;
  end;

const
  Ap = chr(39);
  ApC = Ap + ',';
  ApZ = Ap + ')';

  MyAddress_Id: string[10] = '7000000101';
  MyUser_Id: string[10] = '2200000101';          // automatická fakturace
  MyAccount_Id: string[10] = '1400000101';       // Fio
  MyPayment_Id: string[10] = '1000000101';       // typ platby: na bankovní úèet
  DRCTag_Id = 50;


var
  dmCommon: TdmCommon;

implementation

{$R *.dfm}

uses FIMain, FILogin;

// ------------------------------------------------------------------------------------------------

function TdmCommon.UserName: AnsiString;
// pøívìtivìjší GetUserName
var
  dwSize : DWord;
begin
  SetLength(Result, 32);
  dwSize := 31;
  GetUserName(PChar(Result), dwSize);
  SetLength(Result, dwSize);
end;

// ------------------------------------------------------------------------------------------------

function TdmCommon.CompName: AnsiString;
// pøívìtivìjší GetComputerName
var
  dwSize : DWord;
begin
  SetLength(Result, 32);
  dwSize := 31;
  GetComputerName(PChar(Result), dwSize);
  SetLength(Result, dwSize);
end;

// ------------------------------------------------------------------------------------------------

function TdmCommon.IndexByName(DataObject: variant; Name: ShortString): integer;
// náhrada za nefunkèní DataObject.ValuByName(Name)
var
  i: integer;
begin
  Result := -1;
  i := 0;
  while i < DataObject.Count do begin
    if DataObject.Names[i] = Name then begin
      Result := i;
      Break;
    end;
    Inc(i);
  end;
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCommon.Zprava(TextZpravy: string);
// do listboxu a logfile uloží èas a text zprávy
// 30.11.17 úprava pro konkurenèní ukládání
var
  TimeOut: integer;
begin
  TimeOut := 0;
  with fmMain do begin
    lbxLog.Items.Add(FormatDateTime('dd.mm.yy hh:nn:ss  ', Now) + TextZpravy);
    lbxLog.ItemIndex := lbxLog.Count - 1;
    Application.ProcessMessages;
    while TimeOut < 1000 do try         // 30.11.17 zkouší to 100x po 10 ms  //TODO je to takhle dobøe?
      Append(F);
      Writeln (F, Format('(%s - %s) ', [Trim(CompName), Trim(UserName)]) + FormatDateTime('dd.mm.yy hh:nn:ss  ', Now) + TextZpravy);
      CloseFile(F);
    except
      Sleep(10);
      Inc(TimeOut, 10);
    end;  
  end;
end;

// ------------------------------------------------------------------------------------------------

{$IFDEF ABAK}
procedure TdmCommon.AktualizaceView;
// aktualizuje view pro fakturaci databázi zákazníkù
var
  SQLStr: AnsiString;
begin
  with fmMain, fmMain.qrMain do begin
    Close;
{$IFNDEF ABAK}
// view s variabilními symboly smluv s EP-Home nebo EP-Profi
    SQLStr := 'CREATE OR REPLACE VIEW ' + VoIP_customers
    + ' AS SELECT DISTINCT Variable_symbol FROM customers Cu, contracts C'
    + ' WHERE Cu.Id = C.Customer_Id'
    + ' AND (C.Tariff_Id = 1 OR C.Tariff_Id = 3)'
    + ' AND C.State = ''active'' '
    + ' AND Variable_symbol IS NOT NULL';
    SQL.Text := SQLStr;
    ExecSQL;
// pro testování
    SQLStr := 'CREATE OR REPLACE VIEW VoIP_customers'
    + ' AS SELECT DISTINCT Variable_symbol FROM customers Cu, contracts C'
    + ' WHERE Cu.Id = C.Customer_Id'
    + ' AND (C.Tariff_Id = 1 OR C.Tariff_Id = 3)'
    + ' AND C.State = ''active'' '
    + ' AND Variable_symbol IS NOT NULL';
    SQL.Text := SQLStr;
    ExecSQL;
{$ENDIF}
// aktuální data z billing_batches
    SQLStr := 'CREATE OR REPLACE VIEW ' + BBmax
    + ' AS SELECT Id, Contract_Id, From_date, Period FROM billing_batches B1'
    + ' WHERE From_date = (SELECT MAX(From_date) FROM billing_batches B2'
      + ' WHERE B2.From_date <= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + Ap
      + ' AND B1.Contract_Id = B2.Contract_Id)';
    SQL.Text := SQLStr;
    ExecSQL;
// pro testování
    SQLStr := 'CREATE OR REPLACE VIEW BBmax'
    + ' AS SELECT Id, Contract_Id, From_date, Period FROM billing_batches B1'
    + ' WHERE From_date = (SELECT MAX(From_date) FROM billing_batches B2'
      + ' WHERE B2.From_date <= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + Ap
      + ' AND B1.Contract_Id = B2.Contract_Id)';
    SQL.Text := SQLStr;
    ExecSQL;
// billing view k datu fakturace
    SQLStr := 'CREATE OR REPLACE VIEW ' + BillingView
{$IFDEF ABAK}
    + ' AS SELECT C.Customer_Id, C.Number, C.Type, C.Tariff_Id, C.Activated_at, C.Canceled_at, C.Invoice_from,'
{$ELSE}
    + ' AS SELECT C.Customer_Id, C.Number, C.Type, C.Tariff_Id, C.Activated_at, C.Canceled_at, C.Invoice_from, C.CTU_category,'
{$ENDIF}
    + ' BB.Period, BI.Description, BI.Price, BI.VAT_Id, BI.Tariff'
    + ' FROM ' + BBmax + ' BB, billing_items BI, contracts C'
    + ' WHERE BB.Id = BI.Billing_batch_Id'
    + ' AND C.Id = BB.Contract_Id'
    + ' AND (C.Invoice = 1 OR (C.State = ''canceled'' AND C.Canceled_at IS NOT NULL'
//    + ' AND C.Canceled_at >= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + Ap + '))'   1.7.2016
      + ' AND C.Canceled_at >= ' + Ap + FormatDateTime('yyyy-mm-dd', StartOfTheMonth(deDatumPlneni.Date)) + Ap + '))'
    + ' AND (C.Invoice_from IS NULL OR C.Invoice_from <= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + ApZ
{$IFDEF ABAK}
    + ' AND C.Activated_at <= ' + Ap + FormatDateTime('yyyy-mm-dd', IncMonth(deDatumPlneni.Date, 1)) + Ap;
    if aseMesic.Value = 1 then SQLStr := SQLStr + ' AND (BB.Period = 1 OR BB.Period = 3 OR BB.Period = 6 OR BB.Period = 12)'
    else if aseMesic.Value = 7 then SQLStr := SQLStr + ' AND (BB.Period = 1 OR BB.Period = 3 OR BB.Period = 6)'
    else if aseMesic.Value in [4, 10] then SQLStr := SQLStr + ' AND (BB.Period = 1 OR BB.Period = 3)'
    else
{$ELSE}
    + ' AND C.Activated_at <= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + Ap;
{$ENDIF}
    SQLStr := SQLStr + ' AND BB.Period = 1';
    SQL.Text := SQLStr;
    ExecSQL;
// pro testování
    SQLStr := 'CREATE OR REPLACE VIEW BillingView'
{$IFDEF ABAK}
    + ' AS SELECT C.Customer_Id, C.Number, C.Type, C.Tariff_Id, C.Activated_at, C.Canceled_at, C.Invoice_from,'
{$ELSE}
    + ' AS SELECT C.Customer_Id, C.Number, C.Type, C.Tariff_Id, C.Activated_at, C.Canceled_at, C.Invoice_from, C.CTU_category,'
{$ENDIF}
    + ' BB.Period, BI.Description, BI.Price, BI.VAT_Id, BI.Tariff'
    + ' FROM BBmax BB, billing_items BI, contracts C'
    + ' WHERE BB.Id = BI.Billing_batch_Id'
    + ' AND C.Id = BB.Contract_Id'
    + ' AND (C.Invoice = 1 OR (C.State = ''canceled'' AND C.Canceled_at IS NOT NULL'
//    + ' AND C.Canceled_at >= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + Ap + '))'   1.7.2016
      + ' AND C.Canceled_at >= ' + Ap + FormatDateTime('yyyy-mm-dd', StartOfTheMonth(deDatumPlneni.Date)) + Ap + '))'
    + ' AND (C.Invoice_from IS NULL OR C.Invoice_from <= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + ApZ
{$IFDEF ABAK}
    + ' AND C.Activated_at <= ' + Ap + FormatDateTime('yyyy-mm-dd', IncMonth(deDatumPlneni.Date, 1)) + Ap;
    if aseMesic.Value = 1 then SQLStr := SQLStr + ' AND (BB.Period = 1 OR BB.Period = 3 OR BB.Period = 6 OR BB.Period = 12)'
    else if aseMesic.Value = 7 then SQLStr := SQLStr + ' AND (BB.Period = 1 OR BB.Period = 3 OR BB.Period = 6)'
    else if aseMesic.Value in [4, 10] then SQLStr := SQLStr + ' AND (BB.Period = 1 OR BB.Period = 3)'
    else
{$ELSE}
    + ' AND C.Activated_at <= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + Ap;
{$ENDIF}
    SQLStr := SQLStr + ' AND BB.Period = 1';
    SQL.Text := SQLStr;
    ExecSQL;
// view k datu fakturace
    SQLStr := 'CREATE OR REPLACE VIEW ' + InvoiceView
{$IFDEF ABAK}
    + ' (VS, Typ, Posilani, Mail, AbraKod, Smlouva, Tarif, AktivniOd, AktivniDo, FakturovatOd, Perioda, Text, Cena, DPH, Tarifni, Reklama)'
{$ELSE}
    + ' (VS, Typ, Posilani, Mail, AbraKod, Smlouva, Tarif, AktivniOd, AktivniDo, FakturovatOd, Perioda, Text, Cena, DPH, Tarifni, Reklama, CTU)'
{$ENDIF}
    + ' AS SELECT Variable_symbol, BV.Type, CB1.Name, Postal_mail, Abra_Code, Number, T.Name, Activated_at, Canceled_at, Invoice_from, Period,'
{$IFDEF ABAK}
    + ' BV.Description, BV.Price, CB2.Name, Tariff, Disable_mailings'
{$ELSE}
    + ' BV.Description, BV.Price, CB2.Name, Tariff, Disable_mailings, CTU_category'
{$ENDIF}
    + ' FROM customers Cu'
    + ' JOIN ' + BillingView + ' BV ON Cu.Id = BV.Customer_Id'
    + ' LEFT JOIN codebooks CB1 ON Cu.Invoice_sending_method_Id = CB1.Id'
    + ' LEFT JOIN codebooks CB2 ON BV.VAT_Id = CB2.Id'
    + ' LEFT JOIN tariffs T ON BV.Tariff_Id = T.Id';
    SQL.Text := SQLStr;
    ExecSQL;
// pro testování
    SQLStr := 'CREATE OR REPLACE VIEW InvoiceView'
{$IFDEF ABAK}
    + ' (VS, Typ, Posilani, Mail, AbraKod, Smlouva, Tarif, AktivniOd, AktivniDo, FakturovatOd, Perioda, Text, Cena, DPH, Tarifni, Reklama)'
{$ELSE}
    + ' (VS, Typ, Posilani, Mail, AbraKod, Smlouva, Tarif, AktivniOd, AktivniDo, FakturovatOd, Perioda, Text, Cena, DPH, Tarifni, Reklama, CTU)'
{$ENDIF}
    + ' AS SELECT Variable_symbol, BV.Type, CB1.Name, Postal_mail, Abra_Code, Number, T.Name, Activated_at, Canceled_at, Invoice_from, Period,'
{$IFDEF ABAK}
    + ' BV.Description, BV.Price, CB2.Name, Tariff, Disable_mailings'
{$ELSE}
    + ' BV.Description, BV.Price, CB2.Name, Tariff, Disable_mailings, CTU_category'
{$ENDIF}
    + ' FROM customers Cu'
    + ' JOIN BillingView BV ON Cu.Id = BV.Customer_Id'
    + ' LEFT JOIN codebooks CB1 ON Cu.Invoice_sending_method_Id = CB1.Id'
    + ' LEFT JOIN codebooks CB2 ON BV.VAT_Id = CB2.Id'
    + ' LEFT JOIN tariffs T ON BV.Tariff_Id = T.Id';
    SQL.Text := SQLStr;
    ExecSQL;
  end;
end;
{$ENDIF}

// ------------------------------------------------------------------------------------------------

{$IFNDEF ABAK}
procedure TdmCommon.AktualizaceView;
// aktualizuje view pro fakturaci databázi zákazníkù
// 27.1.17 celé pøehlednìji
var
  SQLStr: AnsiString;
begin
  with fmMain, fmMain.qrMain do begin
    Close;
// view s variabilními symboly smluv s EP-Home nebo EP-Profi
    SQLStr := 'CREATE OR REPLACE VIEW ' + VoIP_customers
    + ' AS SELECT DISTINCT Variable_symbol FROM customers Cu, contracts C'
    + ' WHERE Cu.Id = C.Customer_Id'
    + ' AND (C.Tariff_Id = 1 OR C.Tariff_Id = 3)'
    + ' AND C.State = ''active'' '
    + ' AND Variable_symbol IS NOT NULL';
    SQL.Text := SQLStr;
    ExecSQL;
// pro testování
    SQLStr := 'CREATE OR REPLACE VIEW VoIP_customers'
    + ' AS SELECT DISTINCT Variable_symbol FROM customers Cu, contracts C'
    + ' WHERE Cu.Id = C.Customer_Id'
    + ' AND (C.Tariff_Id = 1 OR C.Tariff_Id = 3)'
    + ' AND C.State = ''active'' '
    + ' AND Variable_symbol IS NOT NULL';
    SQL.Text := SQLStr;
    ExecSQL;
// aktuální data z billing_batches
    SQLStr := 'CREATE OR REPLACE VIEW ' + BBmax
    + ' AS SELECT Id, Contract_Id, From_date, Period FROM billing_batches B1'
    + ' WHERE From_date = (SELECT MAX(From_date) FROM billing_batches B2'
      + ' WHERE B2.From_date <= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + Ap
      + ' AND B1.Contract_Id = B2.Contract_Id)';
    SQL.Text := SQLStr;
    ExecSQL;
// pro testování
    SQLStr := 'CREATE OR REPLACE VIEW BBmax'
    + ' AS SELECT Id, Contract_Id, From_date, Period FROM billing_batches B1'
    + ' WHERE From_date = (SELECT MAX(From_date) FROM billing_batches B2'
      + ' WHERE B2.From_date <= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + Ap
      + ' AND B1.Contract_Id = B2.Contract_Id)';
    SQL.Text := SQLStr;
    ExecSQL;
// billing view k datu fakturace
    SQLStr := 'CREATE OR REPLACE VIEW ' + BillingView
    + ' AS SELECT C.Customer_Id, C.Number, C.Type, C.Tariff_Id, C.Activated_at, C.Canceled_at, C.Invoice_from, C.CTU_category,'
    + ' BB.Period, BI.Description, BI.Price, BI.VAT_Id, BI.Tariff'
    + ' FROM ' + BBmax + ' BB, billing_items BI, contracts C'
    + ' WHERE BB.Id = BI.Billing_batch_Id'
    + ' AND C.Id = BB.Contract_Id'
    + ' AND (C.Invoice = 1 OR (C.State = ''canceled'' AND C.Canceled_at IS NOT NULL'
      + ' AND C.Canceled_at >= ' + Ap + FormatDateTime('yyyy-mm-dd', StartOfTheMonth(deDatumPlneni.Date)) + Ap + '))'
    + ' AND (C.Invoice_from IS NULL OR C.Invoice_from <= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + ApZ
    + ' AND C.Activated_at <= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + Ap
    + ' AND BB.Period = 1';
    SQL.Text := SQLStr;
    ExecSQL;
// pro testování
    SQLStr := 'CREATE OR REPLACE VIEW BillingView'
    + ' AS SELECT C.Customer_Id, C.Number, C.Type, C.Tariff_Id, C.Activated_at, C.Canceled_at, C.Invoice_from, C.CTU_category,'
    + ' BB.Period, BI.Description, BI.Price, BI.VAT_Id, BI.Tariff'
    + ' FROM BBmax BB, billing_items BI, contracts C'
    + ' WHERE BB.Id = BI.Billing_batch_Id'
    + ' AND C.Id = BB.Contract_Id'
    + ' AND (C.Invoice = 1 OR (C.State = ''canceled'' AND C.Canceled_at IS NOT NULL'
      + ' AND C.Canceled_at >= ' + Ap + FormatDateTime('yyyy-mm-dd', StartOfTheMonth(deDatumPlneni.Date)) + Ap + '))'
    + ' AND (C.Invoice_from IS NULL OR C.Invoice_from <= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + ApZ
    + ' AND C.Activated_at <= ' + Ap + FormatDateTime('yyyy-mm-dd', deDatumPlneni.Date) + Ap
    + ' AND BB.Period = 1';
    SQL.Text := SQLStr;
    ExecSQL;
// view k datu fakturace
    SQLStr := 'CREATE OR REPLACE VIEW ' + InvoiceView
    + ' (VS, Typ, Posilani, Mail, AbraKod, Smlouva, Tarif, AktivniOd, AktivniDo, FakturovatOd, Perioda, Text, Cena, DPH, Tarifni, Reklama, CTU)'
    + ' AS SELECT Variable_symbol, BV.Type, CB1.Name, Postal_mail, Abra_Code, Number, T.Name, Activated_at, Canceled_at, Invoice_from, Period,'
    + ' BV.Description, BV.Price, CB2.Name, Tariff, Disable_mailings, CTU_category'
    + ' FROM customers Cu'
    + ' JOIN ' + BillingView + ' BV ON Cu.Id = BV.Customer_Id'
    + ' LEFT JOIN codebooks CB1 ON Cu.Invoice_sending_method_Id = CB1.Id'
    + ' LEFT JOIN codebooks CB2 ON BV.VAT_Id = CB2.Id'
    + ' LEFT JOIN tariffs T ON BV.Tariff_Id = T.Id';
    SQL.Text := SQLStr;
    ExecSQL;
// pro testování
    SQLStr := 'CREATE OR REPLACE VIEW InvoiceView'
    + ' (VS, Typ, Posilani, Mail, AbraKod, Smlouva, Tarif, AktivniOd, AktivniDo, FakturovatOd, Perioda, Text, Cena, DPH, Tarifni, Reklama, CTU)'
    + ' AS SELECT Variable_symbol, BV.Type, CB1.Name, Postal_mail, Abra_Code, Number, T.Name, Activated_at, Canceled_at, Invoice_from, Period,'
    + ' BV.Description, BV.Price, CB2.Name, Tariff, Disable_mailings, CTU_category'
    + ' FROM customers Cu'
    + ' JOIN BillingView BV ON Cu.Id = BV.Customer_Id'
    + ' LEFT JOIN codebooks CB1 ON Cu.Invoice_sending_method_Id = CB1.Id'
    + ' LEFT JOIN codebooks CB2 ON BV.VAT_Id = CB2.Id'
    + ' LEFT JOIN tariffs T ON BV.Tariff_Id = T.Id';
    SQL.Text := SQLStr;
    ExecSQL;
  end;
end;
{$ENDIF}
// ------------------------------------------------------------------------------------------------

procedure TdmCommon.Plneni_asgMain;
var
  Dotaz,
  Radek: integer;
  VarSymbol,
  FId: string[10];
  Zakaznik,
  SQLStr: AnsiString;
begin
  with fmMain do try
    asgMain.Visible := True;
    lbxLog.Visible := False;
    apnPrevod.Visible := False;
    apnTisk.Visible := False;
    apnMail.Visible := False;
    Screen.Cursor := crHourGlass;
    with qrMain, asgMain do try
      ClearNormalCells;
      RowCount := 2;
      Close;
// ***
// ***  výbìr zákazníkù/smluv podle VS/smlouvy  ***
// ***
      if rbPodleSmlouvy.Checked then begin
// Fakturace
        if rbFakturace.Checked then begin          // 7.10.14 výbìr zákazníkù/smluv k fakturaci
// kontrola mìsíce a roku fakturace
          if (aseRok.Value * 12 + aseMesic.Value > YearOf(Date) * 12 + MonthOf(Date) + 1)     // vìtší než pøíští mìsíc, èi menší
           or (aseRok.Value * 12 + aseMesic.Value < YearOf(Date) * 12 + MonthOf(Date) - 1) then begin       // než minulý mìsíc
            SQLStr := Format('Opravdu fakturovat %d. mìsíc roku %d ?', [aseMesic.Value, aseRok.Value]);
            if Application.MessageBox(PChar(SQLStr), 'Pozor', MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON1) = IDNO then begin
              btVytvorit.Enabled := True;
              btKonec.Caption := '&Konec';
              Exit;
            end;
          end;
// view pro fakturaci
          dmCommon.AktualizaceView;
          dmCommon.Zprava(Format('Naètení zákazníkù k fakturaci na období %s.%s od VS %s do %s.', [aseMesic.Text, aseRok.Text, aedOd.Text, aedDo.Text]));
{$IFDEF ABAK}
          if rbInternet.Checked then dmCommon.Zprava('      - internetové smlouvy')
          else dmCommon.Zprava('      - smlouvy VoIP');
{$ELSE}
          if cbBezVoIP.Checked then dmCommon.Zprava('      - zákazníci bez VoIP');
          if cbSVoIP.Checked then dmCommon.Zprava('      - zákazníci s VoIP');
{$ENDIF}
// ne Fakturace
        end else begin              // if rbFakturace.Checked
          dmCommon.Zprava(Format('Naètení faktur na období %s.%s od VS %s do %s.', [aseMesic.Text, aseRok.Text, aedOd.Text, aedDo.Text]));
{$IFDEF ABAK}
          if rbInternet.Checked then dmCommon.Zprava('      - internetové smlouvy')
          else dmCommon.Zprava('      - smlouvy VoIP');
{$ELSE}
          if cbBezVoIP.Checked then dmCommon.Zprava('      - zákazníci bez VoIP');
          if cbSVoIP.Checked then dmCommon.Zprava('      - zákazníci s VoIP');
{$ENDIF}
        end;      // if rbFakturace.Checked else ...
        SQLStr := 'SELECT DISTINCT VS, Abrakod, Mail, Reklama FROM ' + InvoiceView
        + ' WHERE VS >= ' + Ap + aedOd.Text + Ap
        + ' AND VS <= ' + Ap + aedDo.Text + Ap;
{$IFDEF ABAK}
        if rbInternet.Checked then SQLStr := SQLStr + ' AND (Typ = ''InternetContract'' OR Typ = ''StoryContract'')'
        else SQLStr := SQLStr + ' AND Typ = ''VoipContract''';
{$ELSE}
        if cbBezVoIP.Checked and not cbSVoIP.Checked then
          SQLStr := SQLStr + ' AND NOT EXISTS (SELECT Variable_symbol FROM ' + VoIP_customers
          + ' WHERE Variable_symbol = ' + InvoiceView + '.VS)';
        if cbSVoIP.Checked and not cbBezVoIP.Checked then
          SQLStr := SQLStr + ' AND EXISTS (SELECT Variable_symbol FROM ' + VoIP_customers
          + ' WHERE Variable_symbol = ' + InvoiceView + '.VS)';
        if rbMail.Checked then SQLStr := SQLStr + ' AND Posilani LIKE ''M%''';
        if rbTisk.Checked then begin
          if rbBezSlozenky.Checked then SQLStr := SQLStr + ' AND Posilani LIKE ''P%'''
          else if rbSeSlozenkou.Checked then SQLStr := SQLStr + ' AND Posilani LIKE ''S%'''
          else if rbKuryr.Checked then SQLStr := SQLStr + ' AND Posilani LIKE ''K%''';
        end;
{$ENDIF}
        Close;
        SQL.Text := SQLStr;
        Open;
        Radek := 0;
        apbProgress.Position := 0;
        apbProgress.Visible := True;
        while not EOF do begin
          VarSymbol := FieldByName('VS').AsString;
          apbProgress.Position := Round(100 * RecNo / RecordCount);
          Application.ProcessMessages;
          if Prerusit then begin
            Prerusit := False;
            apbProgress.Position := 0;
            apbProgress.Visible := False;
            btVytvorit.Enabled := True;
            btKonec.Caption := '&Konec';
            Break;
          end;
          with qrAbra do begin
// ne Fakturace
            if not rbFakturace.Checked then begin
              Close;
              dbAbra.Reconnect;
// faktura(y) v Abøe v mìsíci aseMesic
              SQLStr := 'SELECT DISTINCT F.Id AS FId, Name FROM Firms F, IssuedInvoices II'
              + ' WHERE F.ID = II.Firm_ID'
              + ' AND F.Firm_ID IS NULL'
              + ' AND F.Hidden = ''N'''
              + ' AND VarSymbol = ' + Ap + VarSymbol + Ap;
              SQL.Text := SQLStr;
              Open;
              if RecordCount = 0 then begin       // žádná faktura v Abøe
                Zprava(Format('Zákazník s VS %s nemá ještì vystavenou žádnou fakturu.', [VarSymbol]));
                Dotaz := Application.MessageBox(PChar(Format('Zákazník s VS %s nemá ještì vystavenou žádnou fakturu. Je to v poøádku ?',
                [VarSymbol])), 'Pozor', MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON1);
                if Dotaz = IDYES then begin
                  Zprava('Ruèní zásah - faktura pøeskoèena.');
                  qrMain.Next;
                  Continue;
                end else if Dotaz = IDNO then begin
                  Zprava('Ruèní zásah - generování ukonèeno.');
                  Screen.Cursor := crDefault;
                  Exit;
                end;
              end;
              FId := FieldByName('FId').AsString;
              Zakaznik := FieldByName('Name').AsString;
              Close;
              SQLStr := 'SELECT OrdNumber, Amount FROM IssuedInvoices II'
              + ' WHERE Firm_ID = ' + Ap + FId + Ap
              + ' AND VATDate$DATE >= ' + FloatToStr(Trunc(StartOfAMonth(aseRok.Value, aseMesic.Value)))
              + ' AND VATDate$DATE <= ' + FloatToStr(Trunc(EndOfAMonth(aseRok.Value, aseMesic.Value)));
{$IFDEF ABAK}
              if rbInternet.Checked then SQLStr := SQLStr + ' AND DocQueue_ID = ' + Ap + IDocQueue_Id + Ap
              else SQLStr := SQLStr + ' AND DocQueue_ID = ' + Ap + VDocQueue_Id + Ap;
{$ELSE}
              SQLStr := SQLStr + ' AND DocQueue_ID = ' + Ap + IDocQueue_Id + Ap;
{$ENDIF}
              SQL.Text := SQLStr;
              Open;
              if RecordCount = 0 then begin       // faktura v Abøe neexistuje
                Zprava(Format('%s: Faktura na období %s.%s neexistuje.', [Zakaznik, aseMesic.Text, aseRok.Text]));
                Dotaz := Application.MessageBox(PChar(Format('%s: Faktura na období %s.%s neexistuje. Je to v poøádku ?',
                [Zakaznik, aseMesic.Text, aseRok.Text])), 'Pozor', MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON1);
                if Dotaz = IDYES then begin
                  Zprava('Ruèní zásah - faktura pøeskoèena.');
                  qrMain.Next;
                  Continue;
                end else if Dotaz = IDNO then begin
                  Zprava('Ruèní zásah - generování ukonèeno.');
                  Screen.Cursor := crDefault;
                  Exit;
                end;
              end else if RecordCount > 1 then begin      // více faktur s jedním datem
                Zprava(Format('%s: Více faktur na období %s.%s.', [Zakaznik, aseMesic.Text, aseRok.Text]));
                Dotaz := Application.MessageBox(PChar(Format('%s: Více faktur na období %s.%s. Je to v poøádku ?',
                [Zakaznik, aseMesic.Text, aseRok.Text])), 'Pozor', MB_ICONQUESTION + MB_YESNOCANCEL + MB_DEFBUTTON1);
                if Dotaz = IDNO then begin
                  Zprava('Ruèní zásah - faktura pøeskoèena.');
                  qrMain.Next;
                 Continue;
                end else if Dotaz = IDCANCEL then begin
                  Zprava('Ruèní zásah - generování ukonèeno.');
                  Screen.Cursor := crDefault;
                  Exit;
                end;
              end;  // if RecordCount
            end;  // if not rbFakturace.Checked
// uložení do asgMain
            Inc(Radek);
            RowCount := Radek + 1;
            AddCheckBox(0, Radek, True, True);
            Ints[0, Radek] := 1;                                                   // fajfka
            Cells[1, Radek] := VarSymbol;                                          // VS
            if rbFakturace.Checked then begin
              Cells[2, Radek] := '';                                                 // faktura
              Cells[3, Radek] := '';                                                 // èástka
              Cells[4, Radek] := qrMain.FieldByName('Abrakod').AsString;             // jméno
            end else begin
              Cells[2, Radek] := Format('%5.5d', [FieldByName('OrdNumber').AsInteger]);     // faktura
              Floats[3, Radek] := FieldByName('Amount').AsFloat;;                    // èástka
              Cells[4, Radek] := Zakaznik;                                           // jméno
            end;  // if rbFakturace.Checked else...
            Cells[5, Radek] := qrMain.FieldByName('Mail').AsString;                // mail
            Ints[6, Radek] := qrMain.FieldByName('Reklama').AsInteger;             // reklama
            Application.ProcessMessages;
          end;  // with qrAbra
          Next;
        end;  // while not EOF
// ***
// ***  výbìr zákazníkù podle faktury  ***
// ***
      end else if rbPodleFaktury.Checked then with qrAbra do begin
        Close;
        dmCommon.Zprava(Format('Naètení faktur od %s do %s.', [aedOd.Text, aedDo.Text]));
// faktura(y) v Abøe v mìsíci aseMesic
        SQLStr := 'SELECT Name, OrdNumber, VarSymbol, Amount FROM Firms F, IssuedInvoices II'
        + ' WHERE II.Firm_ID = F.ID'
        + ' AND OrdNumber >= ' + aedOd.Text
        + ' AND OrdNumber <= ' + aedDo.Text
        + ' AND VATDate$DATE >= ' + FloatToStr(Trunc(StartOfAMonth(aseRok.Value, aseMesic.Value)))
        + ' AND VATDate$DATE <= ' + FloatToStr(Trunc(EndOfAMonth(aseRok.Value, aseMesic.Value)));
        if rbMail.Checked then SQLStr := SQLStr + ' AND F.Firm_ID IS NULL';
{$IFDEF ABAK}
        if rbInternet.Checked then SQLStr := SQLStr + ' AND DocQueue_ID = ' + Ap + IDocQueue_Id + Ap       // 1N00000101
        else SQLStr := SQLStr + ' AND DocQueue_ID = ' + Ap + VDocQueue_Id + Ap;                            // 1P00000101
{$ELSE}
        SQLStr := SQLStr + ' AND DocQueue_ID = ' + Ap + IDocQueue_Id + Ap;
{$ENDIF}
        SQL.Text := SQLStr;
        Open;
        Radek := 0;
        apbProgress.Position := 0;
        apbProgress.Visible := True;
        while not EOF do begin
          VarSymbol := FieldByName('VarSymbol').AsString;
          Zakaznik := FieldByName('Name').AsString;
          apbProgress.Position := Round(100 * RecNo / RecordCount);
          Application.ProcessMessages;
          if Prerusit then begin
            Prerusit := False;
            apbProgress.Position := 0;
            apbProgress.Visible := False;
            btVytvorit.Enabled := True;
            btKonec.Caption := '&Konec';
            Break;
          end;
          with qrMain do begin
            Close;
// nekontroluje se v InvoiceView
//            SQLStr := 'SELECT DISTINCT Mail, Reklama FROM ' + InvoiceView
//            + ' WHERE VS = ' + VarSymbol;
            SQLStr := 'SELECT DISTINCT Postal_mail AS Mail, Disable_mailings AS Reklama FROM customers Cu'
            + ' WHERE Variable_symbol = ' + VarSymbol;
{$IFNDEF ABAK}
            if cbBezVoIP.Checked and not cbSVoIP.Checked then
              SQLStr := SQLStr + ' AND NOT EXISTS (SELECT Variable_symbol FROM ' + VoIP_customers
              + ' WHERE Variable_symbol = ' + Ap + VarSymbol + ApZ;
            if cbSVoIP.Checked and not cbBezVoIP.Checked then
              SQLStr := SQLStr + ' AND EXISTS (SELECT Variable_symbol FROM ' + VoIP_customers
              + ' WHERE Variable_symbol = ' + Ap + VarSymbol + ApZ;
            if rbMail.Checked then SQLStr := SQLStr + ' AND Invoice_sending_method_id = 9';
            if rbTisk.Checked then begin
              if rbBezSlozenky.Checked then SQLStr := SQLStr + ' AND Invoice_sending_method_id = 10'
              else if rbSeSlozenkou.Checked then SQLStr := SQLStr + ' AND Invoice_sending_method_id = 11'
              else if rbKuryr.Checked then SQLStr := SQLStr + ' AND Invoice_sending_method_id = 12';
            end;
{$ENDIF}
            SQL.Text := SQLStr;
            Open;
            while not EOF do begin
              Inc(Radek);
              RowCount := Radek + 1;
              AddCheckBox(0, Radek, True, True);
              Ints[0, Radek] := 1;                                                   // fajfka tisk - mail
              Cells[1, Radek] := VarSymbol;                                          // smlouva
              Cells[2, Radek] := Format('%5.5d', [qrAbra.FieldByName('OrdNumber').AsInteger]);     // faktura
              Floats[3, Radek] := qrAbra.FieldByName('Amount').AsFloat;;             // èástka
              Cells[4, Radek] := Zakaznik;                                           // jméno
              Cells[5, Radek] := FieldByName('Mail').AsString;                       // mail
              Ints[6, Radek] := FieldByName('Reklama').AsInteger;                    // reklama
              Next;
            end;  // while not EOF
          end; //with qrMain
          Application.ProcessMessages;
          Next;
        end;  // while not EOF
        if Check then dmCommon.Zprava('Vyhledány fakturované smlouvy');
      end;  // if rbPodleFaktury.Checked with qrAbra
//      AutoSize := True;
      if not rbFakturace.Checked then begin
        SortSettings.Column := 2;
        SortSettings.Full := True;
//      SortSettings.AutoFormat := False;
        SortSettings.Direction := sdAscending;
        QSort;
      end;
      dmCommon.Zprava(Format('Poèet faktur: %d', [RowCount-1]));
      if rbFakturace.Checked then btVytvorit.Caption := '&Vytvoøit'
      else if rbPrevod.Checked then btVytvorit.Caption := '&Pøevést'
      else if rbTisk.Checked then btVytvorit.Caption := '&Vytisknout'
      else if rbMail.Checked then btVytvorit.Caption := '&Odeslat';
    except on E: Exception do
      Zprava('Neošetøená chyba: ' + E.Message);
    end;  // with qrMain
  finally
    qrMain.Close;
    apbProgress.Position := 0;
    apbProgress.Visible := False;
    if rbPrevod.Checked then apnPrevod.Visible := True;
    if rbTisk.Checked then apnTisk.Visible := True;
    if rbMail.Checked then apnMail.Visible := True;
    Screen.Cursor := crDefault;
    btVytvorit.Enabled := True;
    btVytvorit.SetFocus;
  end;
end;

end.
