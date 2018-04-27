unit Code;

interface

uses
  Windows, SysUtils, Classes, Forms, Types, Controls, Variants, Math, Dialogs, ComObj, F1;

type
  TdmCode = class(TDataModule)
  public
    procedure Zprava(TextZpravy: string);
    function FillasgMain: integer;
    procedure FillAddress(aRadek: integer);
    procedure FillItemsZRowsDL;
    procedure FillItemsZRowsPR;
    procedure FillItems(aRadek: integer);
    procedure FillasgItems(aRadek: integer);
    procedure ConnectAbra;
    procedure MakeAddress(aRadek: integer);
    procedure RepairRecord(aRadek: integer);
    procedure MakePP(aRadek: integer);
    procedure MakeFO(aRadek: integer);
    procedure MakeDL(aRadek: integer);
    procedure MakePR(aRadek: integer);
    procedure UpdateTechniciXLS(aRadek: integer);
    procedure ClearRequest(aRadek: integer);
  end;

var
  dmCode: TdmCode;

implementation

uses Login, DesUtils;

{$R *.dfm}

// ------------------------------------------------------------------------------------------------

function UserName: string;
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

function CompName: string;
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

function IndexByName(DataObject: variant; Name: string): integer;
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

procedure TdmCode.Zprava(TextZpravy: string);
begin
  with fmMain do begin
    lbxLog.Items.Add(FormatDateTime('dd.mm.yy hh:nn  ', Now) + TextZpravy);
    lbxLog.ItemIndex := lbxLog.Count - 1;
    Application.ProcessMessages;
    Sleep(10);
    Append(F);
    Writeln (F, Format('(%s - %s) ', [Trim(CompName), Trim(UserName)]) + FormatDateTime('dd.mm.yy hh:nn  ', Now) + TextZpravy);
    CloseFile(F);
  end;
end;

// ------------------------------------------------------------------------------------------------

function TdmCode.FillasgMain: integer;
// naète zákazníky ze všech nevyøízených žádostí v tabulce simple_billings do asgMain
var
  Radek: integer;
  Zakaznik,
  SQLStr: string;
begin
  with fmMain, qrMain, asgMain do begin
    ClearNormalCells;
    Cells[1, 0] := ' kód Abra';
    Cells[2, 0] := 'var. symbol';
    Cells[3, 0] := ' jméno';
    Cells[4, 0] := ' doklad';
    Cells[5, 0] := ' DL';
    Cells[6, 0] := 'technik';
    Cells[7, 0] := ' Cu.Id';
    Cells[8, 0] := ' C.Id';
    Cells[9, 0] := ' F.Id';
    Cells[10, 0] := ' FO.Id';
// výbìr a uložení zákazníkù do asgMain
    SQLStr := 'SELECT DISTINCT Cu.Abra_code, Cu.Variable_symbol, Cu.Title, Cu.First_name, Cu.Surname, Cu.Business_name, Cu.Id,'
    + ' U.Abra_sklad, U.Login, SB.Contract_Id'
    + ' FROM customers Cu, simple_billings SB, users U'
    + ' WHERE Cu.Id = SB.Customer_Id'
    + ' AND U.Id = SB.User_Id'
    + ' AND Past = 0';
//    + ' ORDER BY SB.Created_at, Doc DESC';
    SQL.Text := SQLStr;
    Open;
    Radek := 0;
    while not EOF do begin
      Inc(Radek);
      RowCount := Radek + 1;
      AddCheckBox(0, Radek, True, True);
      if FieldByName('Business_name').AsString <> '' then Zakaznik := FieldByName('Business_name').AsString
      else begin
        Zakaznik := FieldByName('Surname').AsString;
{$IFDEF ABAK}
        if FieldByName('First_name').AsString <> '' then Zakaznik := Zakaznik + ' ' + FieldByName('First_name').AsString;
        if FieldByName('Title').AsString <> '' then Zakaznik := Zakaznik + ', ' +  FieldByName('Title').AsString;
        aedTechnik.Text := Trim(FieldByName('Login').AsString);
{$ELSE}
        if FieldByName('First_name').AsString <> '' then Zakaznik := FieldByName('First_name').AsString + ' ' + Zakaznik;
        if FieldByName('Title').AsString <> '' then Zakaznik := FieldByName('Title').AsString + ' ' + Zakaznik;
        aedTechnik.Text := Trim(FieldByName('Abra_sklad').AsString);
{$ENDIF}
      end;
      Ints[0, Radek] := 0;
      Cells[1, Radek] := FieldByName('Abra_code').AsString;
      Cells[2, Radek] := FieldByName('Variable_symbol').AsString;
      Cells[3, Radek] := Trim(Zakaznik);
//      Cells[4, Radek] := FieldByName('Doc').AsString;
//      Cells[5, Radek] := FieldByName('DL').AsString;
{$IFDEF ABAK}
      Cells[6, Radek] := Trim(FieldByName('Login').AsString);
{$ELSE}
      Cells[6, Radek] := Trim(FieldByName('Abra_sklad').AsString);
{$ENDIF}
      Cells[7, Radek] := FieldByName('Id').AsString;;
      Cells[8, Radek] := FieldByName('Contract_Id').AsString;
// když je Abrakód, bude zákazník v Abøe
      if (Cells[1, Radek] <> '') then with qrAbra do begin
// Id firmy
        Close;
        SQLStr := 'SELECT Id FROM Firms'
        + ' WHERE Code = ' + Ap + Cells[1, Radek] + Ap
        + ' AND Firm_ID IS NULL'
        + ' AND Hidden = ''N''';
        SQL.Text := SQLStr;
        Open;
        if RecordCount = 0 then begin
          Zprava(Format('Zákazník %s s kódem %s není v adresáøi Abry.', [Cells[3, Radek], Cells[1, Radek]]));
          Close;
        end else begin
          Cells[9, Radek] := Fields[0].AsString;
// adresa firmy
          Close;
          SQLStr := 'SELECT Id FROM FirmOffices'
          + ' WHERE Parent_Id = ' + Ap + Cells[9, Radek] + Ap;
          SQL.Text := SQLStr;
          Open;
          Cells[10, Radek] := Fields[0].AsString;
          Close;
        end;
      end;  // if .. with qrAbra
// doklady a DL
      with qrItems do begin
        SQLStr := 'SELECT DISTINCT Doc FROM simple_billings'
        + ' WHERE Customer_Id = ' + Ap + Cells[7, Radek] + Ap
        + ' AND Doc IS NOT NULL'
        + ' AND Doc <> '''''
        + ' AND Past = 0';
        if Cells[8, Radek] <> '' then
          SQLStr := SQLStr + ' AND Contract_Id = ' + Ap + Cells[8, Radek] + Ap;
        SQL.Text := SQLStr;
        Open;
        if (RecordCount = 1) then Cells[4, Radek] := FieldByName('Doc').AsString
        else if (RecordCount > 1) then Ints[4, Radek] := RecordCount;
        Close;
        SQLStr := 'SELECT DISTINCT DL FROM simple_billings'
        + ' WHERE Customer_Id = ' + Ap + Cells[7, Radek] + Ap
        + ' AND DL IS NOT NULL'
        + ' AND DL <> '''''
        + ' AND Past = 0';
        if Cells[8, Radek] <> '' then
          SQLStr := SQLStr + ' AND Contract_Id = ' + Ap + Cells[8, Radek] + Ap;
        SQL.Text := SQLStr;
        Open;
        if (RecordCount = 1) then Cells[5, Radek] := FieldByName('DL').AsString
        else if (RecordCount > 1) then Ints[5, Radek] := RecordCount;
        Close;
      end;  // with qrItems
      Next;
    end;
    AutoSize := True;
    ColWidths[0] := 20;         // fajfka
    ColWidths[7] := 0;          // Cu.Id
    ColWidths[8] := 0;          // C.Id
    ColWidths[9] := 0;          // F.Id
    ColWidths[10] := 0;         // FO.Id'
    Result := RecordCount;
    Close;
  end;  // with
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.FillAddress(aRadek: integer);
// nový zákazník nemá kód v Abøe - mùže se jen importovat do Abry a opravit v tabulce customers
var
  Zakaznik,
  CuId,
  SQLStr: string;
begin
  Zakaznik := fmMain.asgMain.Cells[3, aRadek];
  CuId := fmMain.asgMain.Cells[7, aRadek];
  fmMain.asgItems.Clear;
  with fmMain, qrItems, asgItems do begin
    with qrAbra do begin
// kontrola duplictního jména
      SQLStr := 'SELECT Code FROM Firms'
      + ' WHERE Name = ' + Ap + Zakaznik + Ap
      + ' AND Hidden = ''N''';
      SQL.Text := SQLStr;
      Open;
      if RecordCount > 0 then
        if Application.MessageBox(PChar('Zákazník ' + Zakaznik + ' už v Abøe existuje. Je to v poøádku?'),
         'Abra', MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) = IDNO then Exit;
      Close;
    end;  // with qrAbra
// pøíprava položek fmMain
    cbImport.Checked := True;
    cbImport.Enabled := True;
    cbOprava.Checked := False;
    cbOprava.Enabled := True;
    cbDoklad.Checked := False;
    cbDoklad.Enabled := False;
    cbDL.Checked := False;
    cbDL.Enabled := False;
    cbXLS.Checked := False;
    cbXLS.Enabled := False;
    cbClear.Checked := False;
    cbClear.Enabled := False;
// asgItems
    ColCount := 2;
    RowCount := 15;
    FixedCols := 1;
    FixedRows := 0;
    RowHeights[13] := 0;
    RowHeights[14] := 0;
    ColWidths[0] := 80;
    ColWidths[1] := 200;
    Cells[0, 0] := 'kód Abra';
    Cells[0, 1] := 'var. symbol';
    Cells[0, 2] := 'titul';
    Cells[0, 3] := 'jméno';
    Cells[0, 4] := 'pøíjmení';
    Cells[0, 5] := 'firma';
    Cells[0, 6] := 'IÈ';
    Cells[0, 7] := 'DIÈ';
    Cells[0, 8] := 'ulice';
    Cells[0, 9] := 'PSÈ';
    Cells[0, 10] := 'obec';
    Cells[0, 11] := 'telefon';
    Cells[0, 12] := 'mail';
    SQLStr := 'SELECT DISTINCT Cu.Abra_code, Cu.Variable_symbol, Cu.Title, Cu.First_name, Cu.Surname, Cu.Business_name, Cu.IC, Cu.DIC,'
    + ' U.Abra_sklad, U.Login, Billing_street, Billing_PSC, Billing_city, Phone, Postal_mail, Cu.Email, Invoice_sending_method_Id, T.Price'
    + ' FROM customers Cu, simple_billings SB, users U, contracts C'
    + ' LEFT JOIN tariffs T ON T.Id = C.Tariff_Id'                         // kvùli smlouvám s pøíbìhem
    + ' WHERE Cu.Id = ' + CuId
    + ' AND SB.Customer_Id = ' + CuId
    + ' AND U.Id = SB.User_Id'
    + ' AND Cu.Id = C.Customer_Id';
    SQL.Text := SQLStr;
    Open;
    Cells[1, 0] := Trim(FieldByName('Abra_code').AsString);
    Cells[1, 1] := Trim(FieldByName('Variable_symbol').AsString);
    Cells[1, 2] := Trim(FieldByName('Title').AsString);
    Cells[1, 3] := Trim(FieldByName('First_name').AsString);
    Cells[1, 4] := Trim(FieldByName('Surname').AsString);
    Cells[1, 5] := Trim(FieldByName('Business_name').AsString);
    Cells[1, 6] := Trim(FieldByName('IC').AsString);
    Cells[1, 7] := Trim(FieldByName('DIC').AsString);
    Cells[1, 8] :=  Trim(FieldByName('Billing_street').AsString);
    Cells[1, 9]  := Trim(FieldByName('Billing_PSC').AsString);
    Cells[1, 10] := Trim(FieldByName('Billing_city').AsString);
    Cells[1, 11] := Trim(FieldByName('Phone').AsString);
    Cells[1, 12] := Trim(FieldByName('Postal_mail').AsString);
    if (Cells[1, 12] = '') and (FieldByName('Email').AsString <> '') then  // pokud není Postal_mail, zkopíruje se Email
      Cells[1, 12] := Trim(FieldByName('Email').AsString);
    Cells[1, 13] := Trim(FieldByName('Invoice_sending_method_Id').AsString);
    Cells[1, 14] := Trim(FieldByName('Price').AsString);
// pøíprava Abra kódu
    if Cells[1, 0] = '' then
{$IFDEF ABAK}
      Cells[1, 0] := Cells[1, 1];
{$ELSE}
    begin
      case Ints[1, 13] of
        9: Cells[1, 0] := 'M';
        10: Cells[1, 0] := 'P';
        11: Cells[1, 0] := 'S';
        12: Cells[1, 0] := 'R';
        13: Cells[1, 0] := 'N';
        14: Cells[1, 0] := 'T';
      end;
      Cells[1, 0] := Cells[1, 0] + Format('%4.4d', [Trunc(Floats[1, 14])]) + Copy(Cells[1, 1], 3, Length(Cells[1, 1])-2);
    end;
{$ENDIF}
// kontrola duplictního kódu
    with qrAbra do begin
      Close;
      SQLStr := 'SELECT COUNT(*) FROM Firms'
      + ' WHERE Code = ' + Ap + Cells[1, 0] + Ap
      + ' AND Hidden = ''N''';
      SQL.Text := SQLStr;
      Open;
      if Fields[0].AsInteger > 0 then begin
        Application.MessageBox(PChar('Kód ' + Cells[1, 0] + ' už v Abøe existuje.'), 'Abra', MB_ICONERROR + MB_OK);
        Exit;
      end;
      Close;
    end;  // with qrAbra
// úprava výšky asgItems
    pnTop.Height := pnTop.Constraints.MinHeight + 198;                     // 18 * 11 øádkù
    fmMain.ClientHeight := Min(fmMain.Constraints.MinHeight + (RowCount-1) * 18  + lbxLog.Items.Count * 13, Screen.Height - 40);
  end;
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.FillItemsZRowsDL;
// k øádkùm s vydávaným zbožím dohledá chybìjící údaje (musí být vyplnìný asgItems)
var
  Radek: integer;
  SQLStr: string;
begin
  with fmMain, qrAbra, asgItems do
// øádky asgItems musí obsahovat Store_ID, StoreCard_ID a pro výrobní èíslo StoreBatch_ID
    for Radek := 1 to RowCount-1 do begin
// dál jen zboží vydávané ze skladu
      if (Ints[0, Radek] <> 1) or (Cells[3, Radek] <> 'Z') or (Floats[9, Radek] <= 0) then Continue;
// -----  v simple_billings je SN
      if (Cells[5, Radek] <> '') then begin
// je SN v Abøe ?
        Close;
// v simple_billings je kód skladové karty
        if (Cells[11, Radek] <> '') then
          SQLStr := 'SELECT SB.Id AS SBId, SC.Id AS SCId, SC.Name FROM StoreBatches SB, StoreCards SC'
          + ' WHERE SB.Name = ' + Ap + Cells[5, Radek] + Ap
          + ' AND SB.StoreCard_ID = ' + Ap + Cells[11, Radek] + Ap
          + ' AND SB.Hidden = ''N'''
          + ' AND SB.SerialNumber = ''A'''
          + ' AND SC.ID = ' + Ap + Cells[11, Radek] + Ap
// v simple_billings není kód skladové karty
        else begin
// z názvu se odstraní kód karty (je-li)
          if (Pos('- ', Cells[1, Radek]) > 0) then
            Cells[7, Radek] := Copy(Cells[1, Radek], Pos('- ', Cells[1, Radek])+1, Length(Cells[1, Radek]))
          else Cells[7, Radek] := Cells[1, Radek];
          SQLStr := 'SELECT SB.Id AS SBId, SC.Id AS SCId, SC.Name FROM StoreBatches SB, StoreCards SC'
          + ' WHERE SB.Name = ' + Ap + Cells[5, Radek] + Ap
          + ' AND SB.Hidden = ''N'''
          + ' AND SB.SerialNumber = ''A'''
          + ' AND SC.ID = SB.StoreCard_ID'
          + ' AND SC.Name = ' + Ap + Cells[7, Radek] + Ap
          + ' AND SC.Hidden = ''N''';
        end;
        SQL.Text := SQLStr;
        Open;
// když se nic nenajde, zùstane to na ruèní zpracování
        if (RecordCount = 0) then begin
          Zprava(Format('%s se SN %s v Abøe není.', [Cells[1, Radek], Cells[5, Radek]]));
          Ints[0, Radek] := 0;
          Close;
          Continue;
        end;
// jinak se Id uloží
        Cells[7, Radek] := FieldByName('Name').AsString;
        Cells[11, Radek] := FieldByName('SCId').AsString;
        Cells[12, Radek] := FieldByName('SBId').AsString;
        Close;
// pokud ještì není DL, najde se sklad  pomocí výrobního èísla
        if (Cells[15, Radek] = '') then begin
          SQLStr := 'SELECT SSB.Store_ID, SSB.Quantity, S.Code'
          + ' FROM StoreSubBatches SSB, Stores S'
          + ' WHERE SSB.StoreBatch_ID = ' + Ap + Cells[12, Radek] + Ap
          + ' AND SSB.Quantity > 0'
          + ' AND S.ID = SSB.Store_ID';
          SQL.Text := SQLStr;
          Open;
// když se nic nenajde, zùstane to na ruèní zpracování
          if (RecordCount = 0) or (FieldByName('Quantity').AsFloat <= 0) then begin
            Ints[0, Radek] := 0;
            Zprava(Format('%s se SN %s není v žádném skladu.', [Cells[1, Radek], Cells[5, Radek]]));
            Close;
            Continue;
          end;
// není-li chyba, uloží se do asgItems
          Cells[8, Radek] := FieldByName('Code').AsString;                     // technik (sklad)
          Cells[9, Radek] := FieldByName('Quantity').AsString;
          Cells[10, Radek] := FieldByName('Store_ID').AsString;
          Close;
        end;  // není DL
// ----- v simple_billings není SN
      end else begin  // if (Cells[5, Radek] <> '')
// Id skladu technika
        Close;
        SQLStr := 'SELECT Id FROM Stores'
        + ' WHERE Code = ' + Ap + Cells[8, Radek] + Ap;          // kód skladu
        SQL.Text := SQLStr;
        Open;
// sklad neexistuje, tak nic
        if (RecordCount = 0) then begin
          Ints[0, Radek] := 0;
          Zprava(Format('Sklad s kódem %s v Abøe neexistuje.', [Cells[8, Radek]]));
          Close;
          Continue;
        end;
// jinak se S.Id uloží
        Cells[10, Radek] := FieldByName('Id').AsString;
// když v simple_billings není kód skladové karty, bude se hledat pøes název
        if (Cells[11, Radek] = '') then begin
// z názvu se odstraní kód karty (je-li)
          if (Pos('- ', Cells[1, Radek]) > 0) then
            Cells[7, Radek] := Copy(Cells[1, Radek], Pos('- ', Cells[1, Radek])+1, Length(Cells[1, Radek]))
          else Cells[7, Radek] := Cells[1, Radek];
          Close;
          SQLStr := 'SELECT Id FROM StoreCards'
          + ' WHERE Name = ' + Ap + Cells[7, Radek] + Ap;
          SQL.Text := SQLStr;
          Open;
          if (RecordCount = 0) then begin                  // název nevyšel, tak nic
            Ints[0, Radek] := 0;
            Zprava(Format('%s nemá v Abøe skladovou kartu.', [Cells[7, Radek]]));
            Close;
            Continue;
          end;
// najde se, uloží se
          Cells[11, Radek] := FieldByName('Id').AsString;          // SC.Id
          Close;
// v simple_billings je kód skladové karty
        end else begin   // if (Cells[11, Radek] = '')
          Close;
          SQLStr := 'SELECT Name FROM StoreCards'
          + ' WHERE Id = ' + Ap + Cells[11, Radek] + Ap;
          SQL.Text := SQLStr;
          Open;
          Cells[7, Radek] := FieldByName('Name').AsString;
          Close;
        end;
// pokud ještì není DL,zkontroluje se, zda je díl na skladì technika
// poèet kusù je v tabulce STORESUBCARDS v poli QUANTITY
        if (Cells[15, Radek] = '') then begin
          SQLStr := 'SELECT Quantity FROM StoreSubCards'
          + ' WHERE Store_Id = ' + Ap + Cells[10, Radek] + Ap
          + ' AND StoreCard_Id = ' + Ap + Cells[11, Radek] + Ap;
          SQL.Text := SQLStr;
          Open;
// na skladì technika není dostateèné množství, zùstane to na ruèní zpracování
          if FieldByName('Quantity').AsFloat < Floats[9, Radek] then begin
            Ints[0, Radek] := 0;
            if FieldByName('Quantity').AsFloat <= 0 then
              Zprava(Format('%s není ve skladu %s.', [Cells[1, Radek], Cells[8, Radek]]))
            else Zprava(Format('%s - ve skladu %s není dostateèné množství.', [Cells[1, Radek], Cells[8,  Radek]]));
          end;
        end;  // není DL
      end;  // není SN
    end;  // for
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.FillItemsZRowsPR;
// k øádkùm s pøijímaným zbožím dohledá chybìjící údaje (musí být vyplnìný asgItems)
var
  Radek: integer;
  SQLStr: string;
begin
  with fmMain, qrAbra, asgItems do
// øádky asgItems musí obsahovat Store_ID, StoreCard_ID a pro výrobní èíslo (je-li v Abøe) StoreBatch_ID
    for Radek := 1 to RowCount-1 do begin
// dál jen zboží pøijímané do skladu
      if (Ints[0, Radek] <> 1) or (Cells[3, Radek] <> 'Z') or (Floats[9, Radek] >= 0) then Continue;
// Id skladu technika
      Close;
      SQLStr := 'SELECT Id FROM Stores'
      + ' WHERE Code = ' + Ap + Cells[8, Radek] + Ap;          // kód skladu
      SQL.Text := SQLStr;
      Open;
// sklad neexistuje, tak nic
      if (RecordCount = 0) then begin
        Ints[0, Radek] := 0;
        Zprava(Format('Sklad s kódem %s v Abøe neexistuje.', [Cells[8, Radek]]));
        Close;
        Continue;
      end;
// jinak se S.Id uloží
      Cells[10, Radek] := FieldByName('Id').AsString;
// -----  v simple_billings je SN
      if (Cells[5, Radek] <> '') then begin
// je SN v Abøe ?
        Close;
// v simple_billings je kód skladové karty
        if (Cells[11, Radek] <> '') then
          SQLStr := 'SELECT SB.Id AS SBId, SC.Id AS SCId, SC.Name FROM StoreBatches SB, StoreCards SC'
          + ' WHERE SB.Name = ' + Ap + Cells[5, Radek] + Ap
          + ' AND SB.StoreCard_ID = ' + Ap + Cells[11, Radek] + Ap
          + ' AND SB.Hidden = ''N'''
          + ' AND SB.SerialNumber = ''A'''
          + ' AND SC.ID = ' + Ap + Cells[11, Radek] + Ap
// v simple_billings není kód skladové karty
        else begin
// z názvu se odstraní kód karty (je-li)
          if (Pos('- ', Cells[1, Radek]) > 0) then
            Cells[7, Radek] := Copy(Cells[1, Radek], Pos('- ', Cells[1, Radek])+1, Length(Cells[1, Radek]))
          else Cells[7, Radek] := Cells[1, Radek];
          SQLStr := 'SELECT SB.Id AS SBId, SC.Id AS SCId, SC.Name FROM StoreBatches SB, StoreCards SC'
          + ' WHERE SB.Name = ' + Ap + Cells[5, Radek] + Ap
          + ' AND SB.Hidden = ''N'''
          + ' AND SB.SerialNumber = ''A'''
          + ' AND SC.ID = SB.StoreCard_ID'
          + ' AND SC.Name = ' + Ap + Cells[7, Radek] + Ap
          + ' AND SC.Hidden = ''N''';
        end;
        SQL.Text := SQLStr;
        Open;
// když se nic nenajde, zùstane to na ruèní zpracování !!! mìlo by se pøijmout na sklad jako nové SN !!!
        if (RecordCount = 0) then begin
          Zprava(Format('%s se SN %s v Abøe není.', [Cells[1, Radek], Cells[5, Radek]]));
          Ints[0, Radek] := 0;
          Close;
          Continue;
        end;
// jinak se Id uloží
        Cells[7, Radek] := FieldByName('Name').AsString;
        Cells[11, Radek] := FieldByName('SCId').AsString;
        Cells[12, Radek] := FieldByName('SBId').AsString;
        Close;
// ----- v simple_billings není SN
      end else begin  // if (Cells[5, Radek] <> '')
// když v simple_billings není kód skladové karty, bude se hledat pøes název
        if (Cells[11, Radek] = '') then begin
// z názvu se odstraní kód karty (je-li)
          if (Pos('- ', Cells[1, Radek]) > 0) then
            Cells[7, Radek] := Copy(Cells[1, Radek], Pos('- ', Cells[1, Radek])+1, Length(Cells[1, Radek]))
          else Cells[7, Radek] := Cells[1, Radek];
          Close;
          SQLStr := 'SELECT Id FROM StoreCards'
          + ' WHERE Name = ' + Ap + Cells[7, Radek] + Ap;
          SQL.Text := SQLStr;
          Open;
          if (RecordCount = 0) then begin                  // název nevyšel, tak nic
            Ints[0, Radek] := 0;
            Zprava(Format('%s nemá v Abøe skladovou kartu.', [Cells[7, Radek]]));
            Close;
            Continue;
          end;
// najde se, uloží se
          Cells[11, Radek] := FieldByName('Id').AsString;          // SC.Id
          Close;
// v simple_billings je kód skladové karty
        end else begin   // if (Cells[11, Radek] = '')
          Close;
          SQLStr := 'SELECT Name FROM StoreCards'
          + ' WHERE Id = ' + Ap + Cells[11, Radek] + Ap;
          SQL.Text := SQLStr;
          Open;
          Cells[7, Radek] := FieldByName('Name').AsString;
          Close;
        end;  // není SC.Id
      end;   // není SN
    end;  // for
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.FillItems(aRadek: integer);
// existující zákazník - vytváøí se doklady
var
  Radek: integer;
  Zakaznik,
  Abrakod,
  CId,
  CuId,
  SQLStr: string;
begin
  Abrakod := fmMain.asgMain.Cells[1, aRadek];
  Zakaznik := fmMain.asgMain.Cells[3, aRadek];
  CuId := fmMain.asgMain.Cells[7, aRadek];
  CId := fmMain.asgMain.Cells[8, aRadek];
  fmMain.asgItems.Clear;
  with fmMain, qrAbra, asgItems do begin
// kontrola kódu firmy, pøi chybì konec
    Close;
    SQLStr := 'SELECT COUNT(*) FROM Firms'
    + ' WHERE Code = ' + Ap + Abrakod + Ap
    + ' AND Firm_ID IS NULL'
    + ' AND Hidden = ''N''';
    SQL.Text := SQLStr;
    Open;
    if Fields[0].AsInteger = 0 then begin
      dmCode.Zprava(Format('Zákazník %s s kódem %s není v adresáøi Abry.', [Zakaznik, Abrakod]));
      Close;
      Exit;
    end;
    Close;
// pøíprava položek fmMain
    cbImport.Checked := False;
    cbImport.Enabled := False;
    cbOprava.Checked := False;
    cbOprava.Enabled := False;
    cbDoklad.Enabled := True;
    cbDL.Enabled := True;
    cbXLS.Enabled := True;
    cbClear.Enabled := True;
// asgItems
    ColCount := 16;
    RowCount := 2;
    FixedCols := 0;
    FixedRows := 1;
    Cells[1, 0] := ' položka';
    Cells[2, 0] := ' èástka';
    Cells[3, 0] := 'druh';
    Cells[4, 0] := 'cash';
    Cells[5, 0] := ' SN';
    Cells[6, 0] := ' MAC';
    Cells[7, 0] := 'název';
    Cells[8, 0] := 'sklad';
    Cells[9, 0] := 'ks';
    Cells[10, 0] := 'S.Id';
    Cells[11, 0] := 'SC.Id';
    Cells[12, 0] := 'SB.Id';
    Cells[13, 0] := 'sb.Id';
    Cells[14, 0] := 'Doc';
    Cells[15, 0] := 'DL';
    with qrItems do begin
// asgItems se vyplní položkami získanými ze simple_billings
      SQLStr := 'SELECT Description, Price, Cash, Quantity, Doc, DL, Storage_card AS SCId, SB.Id, Abra_sklad, Serial_number, MAC_address, Device'
      + ' FROM simple_billings SB, users U'
      + ' WHERE U.Id = User_Id'
      + ' AND SB.Customer_Id = ' + CuId
      + ' AND Past = 0';
      if CId <> '' then SQLStr := SQLStr + ' AND SB.Contract_Id = ' + CId;
      Close;
      SQL.Text := SQLStr;
      Open;
      Radek := 0;
      while not EOF do begin
        Inc(Radek);
        RowCount := Radek + 1;
        AddCheckBox(0, Radek, True, True);
        Ints[0, Radek] := 1;
        Cells[1, Radek] := Trim(FieldByName('Description').AsString);
        Cells[2, Radek] := Trim(FieldByName('Price').AsString);
        if Pos('kauc', Lowercase(Cells[1, Radek])) > 0 then
          Cells[3, Radek] := 'K'
        else if (Pos('pomìr', Lowercase(Cells[1, Radek])) > 0)
         or (Pos('aktiv', Lowercase(Cells[1, Radek])) > 0)
           or (Pos('práce', Lowercase(Cells[1, Radek])) > 0)
             or (Pos('doprava', Lowercase(Cells[1, Radek])) > 0)
              or (Pos('poplat', Lowercase(Cells[1, Radek])) > 0)
               or (Pos('výjezd', Lowercase(Cells[1, Radek])) > 0)
                or (Pos('služ', Lowercase(Cells[1, Radek])) > 0) then
                  Cells[3, Radek] := 'S';
        if FieldByName('Device').AsInteger = 1 then Cells[3, Radek] := 'Z';
        if (Cells[3, Radek] <> '') then Cells[3, Radek] := UpperCase(char(Cells[3, Radek][1]));
        Ints[4, Radek] := FieldByName('Cash').AsInteger;
        Cells[5, Radek] := FieldByName('Serial_number').AsString;
        Cells[6, Radek] := FieldByName('MAC_address').AsString;
        Cells[8, Radek] := Trim(FieldByName('Abra_sklad').AsString);
        if (Pos(',', Cells[8, Radek]) > 0) then Cells[8, Radek] := Copy(Cells[8, Radek], 1, Pos(',', Cells[8, Radek])-1);
        Cells[9, Radek] := Trim(FieldByName('Quantity').AsString);
        Cells[11, Radek] := Trim(FieldByName('SCId').AsString);
        Ints[13, Radek] := FieldByName('Id').AsInteger;
        Cells[14, Radek] := Trim(FieldByName('Doc').AsString);
        Cells[15, Radek] := Trim(FieldByName('DL').AsString);
        Next;
      end;  // while
      aedHotovost.Text := FloatToStr(ColumnSum(2, 1, RowCount-1));
    end;  // with qrItems
// pro DL a PR doplní se informace o zboží ze skladu
    FillItemsZRowsDL;
    FillItemsZRowsPR;
    AutoSize := True;
    ColWidths[0] := 20;
    ColWidths[10] := 0;
    ColWidths[11] := 0;
    ColWidths[12] := 0;
    ColWidths[13] := 0;
// úprava výšky asgItems
    pnTop.Height := pnTop.Constraints.MinHeight + (RowCount-1) * 18;
    fmMain.ClientHeight := Min(fmMain.Constraints.MinHeight + (RowCount-1) * 18  + lbxLog.Items.Count * 13, Screen.Height - 40);
  end;  // with fmMain
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.FillasgItems(aRadek: integer);
// pokud zákazník ještì nemá kód v Abøe, importujë se adresa do Abry,
// v opaèném pøípadì se vystaví PP/FO, pøípadnì DL
begin
  with fmMain, fmMain.asgMain, fmMain.qrAbra do begin
    aedDoklad.Text := Cells[4, aRadek];
    aedDL.Text := Cells[5, aRadek];
    aedTechnik.Text := Cells[6, aRadek];
    aedHotovost.Clear;
    asgItems.Clear;
// nový zákazník nemá kód v Abøe - mùže se jen importovat do Abry a opravit v tabulce customers
    if (asgMain.Cells[1, aRadek] = '') then FillAddress(aRadek)
// existující zákazník - vytváøí se doklady
    else begin
// kontrola jména zákazníka v obou databázích
      Close;
      SQL.Text := 'SELECT Name FROM Firms WHERE Id = ' + Ap + Cells[9, aRadek] + Ap;
      Open;
      if (FieldByName('Name').AsString <> Cells[3, aRadek]) then begin
        Application.MessageBox(PChar(Format('Zákazník v je Abøe %s, v aplikaci %s.', [FieldByName('Name').AsString, Cells[3, aRadek]])),
         'Zákazník', MB_ICONERROR + MB_OK);
        Zprava(Format('Zákazník v je Abøe %s, v aplikaci %s.',  [FieldByName('Name').AsString, Cells[3, aRadek]]));
      end;
      Close;
// položky dokladu
      FillItems(aRadek);
    end;
  end;  // with fmMain
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.ConnectAbra;
// pøipojení k Abøe, pokud je potøeba
begin
  Screen.Cursor := crHourGlass;
  with fmMain do try
    if VarIsEmpty(AbraOLE) then begin
      Screen.Cursor := crHourGlass;
      dmCode.Zprava('Pøipojení k Abøe ...');
      try
        AbraOLE := CreateOLEObject('AbraOLE.Application');
        if not AbraOLE.Connect('@' + AbraConnection) then begin
          dmCode.Zprava('Problém s Abrou (connect  "' + AbraConnection + '").');
          Screen.Cursor := crDefault;
          Exit;
        end;
        dmCode.Zprava('OK');
        dmCode.Zprava('Login ...');
        fmLogin.ShowModal;
        if not AbraOLE.Login(fmLogin.acbJmeno.Text, fmLogin.aedHeslo.Text) then begin
          dmCode.Zprava('Problém s Abrou (jméno, heslo).');
          Screen.Cursor := crDefault;
          Exit;
        end;
        dmCode.Zprava('OK');
      except on E: exception do
        begin
          Application.MessageBox(PChar('Problém s Abrou.' + ^M + E.Message), 'Abra', MB_ICONERROR + MB_OK);
          dmCode.Zprava('Problém s Abrou.' + #13#10 + E.Message);
          Screen.Cursor := crDefault;
          Exit;
        end;
      end;
      Screen.Cursor := crDefault;
    end;  // if VarIsEmpty(AbraOLE)
  finally
    Screen.Cursor := crDefault;
  end;  // with fmMain
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.MakeAddress(aRadek: integer);
// vytvoøení firmy v Abøe
var
  FirmObject,
  FirmData,
  AddressData: variant;
  Zakaznik,
  CuId,
  SQLStr: string;
begin
  Zakaznik := fmMain.asgMain.Cells[3, aRadek];
  CuId := fmMain.asgMain.Cells[7, aRadek];
  Screen.Cursor := crHourGlass;
  with fmMain, fmMain.asgItems do try
    FirmObject := AbraOLE.CreateObject('@Firm');
    FirmData := AbraOLE.CreateValues('@Firm');
    FirmObject.PrefillValues(FirmData);
    FirmData.ValueByName('Code') := Cells[1, 0];
    FirmData.ValueByName('Name') := Zakaznik;
    if (Length(Cells[1, 6]) = 8) and (Pos('.', Cells[1, 6]) = 0) and (Pos('/', Cells[1, 6]) = 0) then  // v IÈO není datum narození
      FirmData.ValueByName('OrgIdentNumber') := Cells[1, 6];
    FirmData.ValueByName('VATIdentNumber') := Cells[1, 7];
    AddressData:= FirmData.Value[IndexByName(FirmData, 'ResidenceAddress_ID')];
    AddressData.ValueByName('Street') := Cells[1, 8];
    AddressData.ValueByName('PostCode') := Cells[1, 9];
    AddressData.ValueByName('City') := Cells[1, 10];
    AddressData.ValueByName('PhoneNumber1') := Cells[1, 11];
    AddressData.ValueByName('Email') := Cells[1, 12];
    try
      FirmObject.CreateNewFromValues(FirmData);
      Zprava(Format('Zákazník %s s kódem %s byl uložen do adresáøe Abry.', [Zakaznik, Cells[1, 0]]));
// Abrakód do databáze
      with qrMain do try
        SQLStr := 'UPDATE customers SET'
        + ' Abra_code = ' + Ap + Cells[1, 0] + Ap
        + ' WHERE Id = ' + CuId;
        SQL.Text := SQLStr;
        ExecSQL;
        Zprava(Format('%s - Abrakód vložen do databáze.', [Zakaznik]));            // zákazník
      except
        on E: Exception do Application.MessageBox(PChar('Chyba pøi ukládání Abrakódu do databáze.' + ^M + E.Message), 'mySQL', MB_ICONERROR + MB_OK);
      end;  // with qrMain try
    except
      on E: Exception do begin
        Application.MessageBox(PChar('Chyba pøi ukládání do adresáøe Abry.' + ^M + E.Message), 'Abra', MB_ICONERROR + MB_OK);
        Zprava('Chyba pøi ukládání do adresáøe Abry.' + #13#10 + E.Message);
        Exit;
      end;
    end;  // try
  finally
    Screen.Cursor := crDefault;
  end;  // with fmMain
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.RepairRecord(aRadek: integer);
// oprava zákazníka v databázi
var
  Zakaznik,
  CuId,
  SQLStr: string;
begin
  Zakaznik := fmMain.asgMain.Cells[3, aRadek];
  CuId := fmMain.asgMain.Cells[7, aRadek];
  with fmMain, fmMain.qrMain, fmMain.asgItems do try
    SQLStr := 'UPDATE customers SET'
    + ' Abra_code = ' + Ap + Cells[1, 0] + ApC
    + ' Variable_symbol = ' + Ap + Cells[1, 1] + ApC
    + ' Title = ' + Ap + Cells[1, 2] + ApC
    + ' First_name = ' + Ap + Cells[1, 3] + ApC
    + ' Surname = ' + Ap + Cells[1, 4] + ApC
    + ' Business_name = ' + Ap + Cells[1, 5] + ApC
    + ' IC = ' + Ap + Cells[1, 6] + ApC
    + ' DIC = ' + Ap + Cells[1, 7] + ApC
    + ' Billing_street = ' + Ap + Cells[1, 8] + ApC
    + ' Billing_PSC = ' + Ap + Cells[1, 9] + ApC
    + ' Billing_city = ' + Ap + Cells[1, 10] + ApC
    + ' Phone = ' + Ap + Cells[1, 11] + ApC
    + ' Postal_mail = ' + Ap + Cells[1, 12] + Ap
    + ' WHERE Id = ' + CuId;
    SQL.Text := SQLStr;
    ExecSQL;
// pøenos oprav do asgMain
    if (Cells[1, 5] <> '') then Zakaznik := Cells[1, 5]
    else begin
      Zakaznik := Cells[1, 4];
{$IFDEF ABAK}
      if (Cells[1, 3] <> '') then Zakaznik := Zakaznik + ' ' + Cells[1, 3];
      if (Cells[1, 2] <> '') then Zakaznik := Zakaznik + ', ' +  Cells[1, 2];
{$ELSE}
      if (Cells[1, 3]<> '') then Zakaznik := Cells[1, 3] + ' ' + Zakaznik;
      if (Cells[1, 2] <> '') then Zakaznik := Cells[1, 2] + ' ' + Zakaznik;
{$ENDIF}
    end;
    asgMain.Cells[1, aRadek] := Cells[1, 0];
    asgMain.Cells[2, aRadek] := Cells[1, 1];
    asgMain.Cells[3, aRadek] := Zakaznik;
    Zprava(Format('%s - záznam v databázi opraven.', [Zakaznik]));
  except
    on E: Exception do Application.MessageBox(PChar('Chyba v pøi opravì v databázi.' + ^M + E.Message), 'mySQL', MB_ICONERROR + MB_OK);
  end;  // with fmMain
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.MakePP(aRadek: integer);
// vytvoøení PP
var
  Period_Id,
  Firm_Id,
  FirmOffice_Id,
  VATRate_Id,
  VATIndex_Id,
  ID: string[10];
  Nevyplneno,
  K, S, Z: boolean;
  VATRate,
  Radek: integer;
  PPObject,
  PPData,
  RadkyPP,
  RadekPP: variant;
  Druh,
  DruhStr,
  Doklad,
  VS,
  CId,
  SQLStr: string;
begin
  Screen.Cursor := crHourGlass;
  with fmMain, qrMain, asgItems do try
    VS := asgMain.Cells[2, aRadek];
    CId := asgMain.Cells[8, aRadek];
    Firm_Id := asgMain.Cells[9, aRadek];
    FirmOffice_Id := asgMain.Cells[10, aRadek];
// kontrola vyplnìní asgItems
    Nevyplneno := False;
    for Radek := 1 to RowCount-1 do
      if (Ints[0, Radek] = 1) and (Ints[4, Radek] = 0) then begin       // øádek se má zpracovat
        if (Cells[3, Radek] = '') then begin                            // druh není vyplnìn
          Nevyplneno := True;
          Application.MessageBox(PChar(Cells[1, Radek] + ' - druh pøíjmu není vyplnìn.'), 'Druh pøíjmu', MB_ICONERROR + MB_OK);
        end else begin                                                  // druh je vyplnìn
          DruhStr := UpperCase(Cells[3, Radek]);
          Druh := DruhStr[1];
          if (Druh = 'S') or (Druh = 'K') or (Druh = 'Z') then Cells[3, Radek] := Druh
          else begin
{$IFDEF ABAK}
            Application.MessageBox(PChar(Cells[1, Radek] + ' - druh pøíjmu je S nebo Z.'), 'Druh pøíjmu', MB_ICONERROR + MB_OK);
{$ELSE}
           Application.MessageBox(PChar(Cells[1, Radek] + ' - druh pøíjmu je S, K nebo Z.'), 'Druh pøíjmu', MB_ICONERROR + MB_OK);
{$ENDIF}
            Nevyplneno := True;
          end;
        end;  // if (Cells[3, Radek] = '') ... else ...
// kontrola øádkù s nulovou cenou
        if (Floats[2, Radek] = 0) then
          if Application.MessageBox(PChar(Cells[1, Radek] + ' má nulovou cenu. Ponechat v dokladu ?'),
           'Nulová cena', MB_ICONQUESTION + MB_YESNO) = IDNO then Ints[0, Radek] := 0;
      end;  // if (Ints[0, Radek] = 1)...
    if Nevyplneno then begin
      cbXLS.Checked := False;
      cbClear.Checked := False;
      Exit;
    end;
// konstanty z Abry
    with qrAbra do begin
// Id období
      SQL.Text := 'SELECT Id FROM Periods WHERE Code = ' + Ap + FormatDateTime('yyyy', adeDatumDokladu.Date) + Ap;
      Open;
      Period_Id := FieldByName('Id').AsString;
      Close;
// DPH
      SQL.Text := 'SELECT Id, VATRate_Id, Tariff FROM VATIndexes WHERE Code = ''Výst21''';       // 4.1.2013
      Open;
      VATIndex_Id := FieldByName('Id').AsString;
      VATRate_Id := FieldByName('VATRate_Id').AsString;
      VATRate := FieldByName('Tariff').AsInteger;
      Close;
    end;  // with qrAbra
// hlavièka PP
    PPObject:= AbraOLE.CreateObject('@CashReceived');
    PPData:= AbraOLE.CreateValues('@CashReceived');
    PPObject.PrefillValues(PPData);
    PPData.ValueByName('DocQueue_ID') := PP_Id;
    PPData.ValueByName('Period_ID') := Period_Id;
    PPData.ValueByName('DocDate$DATE') := Floor(adeDatumDokladu.Date);
    PPData.ValueByName('AccDate$DATE') := Floor(adeDatumDokladu.Date);
    PPData.ValueByName('VATDate$DATE') := Floor(adeDatumPlneni.Date);
    PPData.ValueByName('CreatedBy_ID') := User_Id;
    PPData.ValueByName('Firm_ID') := Firm_Id;
    PPData.ValueByName('FirmOffice_ID') := FirmOffice_Id;
    PPData.ValueByName('Address_ID') := MyAddress_Id;
{$IFDEF ABAK}
    PPData.ValueByName('PricesWithVAT') := False;
    PPData.ValueByName('TotalRounding') := 257;                // zaokrouhlení na koruny
{$ELSE}
    PPData.ValueByName('PricesWithVAT') := True;
    PPData.ValueByName('VATFromAbovePrecision') := 6;
    PPData.ValueByName('TotalRounding') := 259;                // zaokrouhlení na koruny dolù
{$ENDIF}
    PPData.ValueByName('Currency_ID'):='0000CZK000';
// kolekce pro øádky PP
    RadkyPP := PPData.Value[IndexByName(PPData, 'Rows')];
// prázdný øádek
    RadekPP := AbraOLE.CreateValues('@CashReceivedRow');
    RadekPP.ValueByName('Division_ID') := '1000000101';
    RadekPP.ValueByName('RowType') := '0';
    RadkyPP.Add(RadekPP);
// vybrané øádky s s položkami (ne s placením)
    S := False;
    K := False;
    Z := False;
    for Radek := 1 to RowCount-1 do begin
// øádky se vytvoøí v poøadí S, K, Z
      if (Cells[3, Radek] <> '') then Cells[3, Radek] := UpperCase(char(Cells[3, Radek][1]));
// nejdøíve služby
      if (Ints[0, Radek] = 0) or (Ints[4, Radek] = 1) or (Cells[3, Radek] <> 'S') then Continue;
      RadekPP:= AbraOLE.CreateValues('@CashReceivedRow');
      RadekPP.ValueByName('Division_ID') := '1000000101';
      RadekPP.ValueByName('VATRate_ID') := VATRate_Id;
      RadekPP.ValueByName('VATIndex_ID') := VATIndex_Id;
      RadekPP.ValueByName('VATRate') := IntToStr(VATRate);
      RadekPP.ValueByName('Text') := Cells[1, Radek];
{$IFDEF ABAK}
      RadekPP.ValueByName('IncomeType_ID') := '2000000101';
{$ELSE}
      RadekPP.ValueByName('IncomeType_ID') := '2000000000';
{$ENDIF}
      if Cells[9, Radek] > '1' then begin
        RadekPP.ValueByName('RowType') := '2';
        RadekPP.ValueByName('UnitPrice') := Cells[2, Radek];
        RadekPP.ValueByName('Quantity') := Cells[9, Radek];
      end else begin
        RadekPP.ValueByName('RowType') := '1';
        RadekPP.ValueByName('TotalPrice') := Cells[2, Radek];
      end;
      RadkyPP.Add(RadekPP);
      S := True;
    end;  // for
    for Radek := 1 to RowCount-1 do begin
      if (Cells[3, Radek] <> '') then Cells[3, Radek] := UpperCase(char(Cells[3, Radek][1]));
// pak kauce
      if (Ints[0, Radek] = 0) or (Ints[4, Radek] = 1) or (Cells[3, Radek] <> 'K') then Continue;
      RadekPP:= AbraOLE.CreateValues('@CashReceivedRow');
      RadekPP.ValueByName('Division_ID') := '1000000101';
      RadekPP.ValueByName('VATRate_ID') := '00000X0000';
      RadekPP.ValueByName('VATIndex_ID') := '7000000000';
      RadekPP.ValueByName('VATRate') := '0';
      RadekPP.ValueByName('Text') := 'kauce';
      RadekPP.ValueByName('IncomeType_ID') := '1000000101';
      RadekPP.ValueByName('RowType') := '1';
      RadekPP.ValueByName('TotalPrice') := Cells[2, Radek];
      RadkyPP.Add(RadekPP);
      K := True;
    end;  // for
    for Radek := 1 to RowCount-1 do begin
      if (Cells[3, Radek] <> '') then Cells[3, Radek] := UpperCase(char(Cells[3, Radek][1]));
// nakonec zboží
      if (Ints[0, Radek] = 0) or (Ints[4, Radek] = 1) or (Cells[3, Radek] <> 'Z') then Continue;
      RadekPP:= AbraOLE.CreateValues('@CashReceivedRow');
      RadekPP.ValueByName('Division_ID') := '1000000101';
      RadekPP.ValueByName('VATRate_ID') := VATRate_Id;
      RadekPP.ValueByName('VATIndex_ID') := VATIndex_Id;
      RadekPP.ValueByName('VATRate') := IntToStr(VATRate);
      RadekPP.ValueByName('Text') := Cells[1, Radek];
      if (Cells[5, Radek] <> '') then
        RadekPP.ValueByName('Text') := Format('%s, SN: %s', [Cells[1, Radek], Cells[5, Radek]]);
{$IFDEF ABAK}
      RadekPP.ValueByName('IncomeType_ID') := '1000000101';
{$ELSE}
      RadekPP.ValueByName('IncomeType_ID') := '1000000000';
{$ENDIF}
      RadekPP.ValueByName('RowType') := '2';
      RadekPP.ValueByName('UnitPrice') := Cells[2, Radek];
      RadekPP.ValueByName('Quantity') := Cells[9, Radek];
      RadkyPP.Add(RadekPP);
      Z := True;
    end;  // for
    DruhStr := VS + ' ';
    if S then DruhStr := DruhStr + 'služby, ';
    if K then DruhStr := DruhStr + 'kauce, ';
    if Z then DruhStr := DruhStr + 'zboží, ';
    DruhStr := Copy(DruhStr, 1, Length(DruhStr)-2);
    PPData.ValueByName('Description') := DruhStr;
// vytvoøení PP
    if RadkyPP.Count > 0 then try
      ID := PPObject.CreateNewFromValues(PPData);
      PPData := PPObject.GetValues(ID);
      Doklad := string(PPData.Value[IndexByName(PPData, 'DisplayName')]);
      Zprava('Vytvoøeno ' + Doklad);
// èíslo dokladu do asgMain
      asgMain.Cells[4, asgMain.Row] := asgMain.Cells[4, asgMain.Row] + ' ' + Doklad;
      for Radek := 1 to RowCount-1 do begin
// èíslo dokladu do asgItems
        if (Ints[0, Radek] = 1) then Cells[14, Radek] := Doklad;
// èíslo dokladu do tabulky simple_billings
        if (Ints[0, Radek] = 1) then try
          SQLStr := 'UPDATE simple_billings SET'
          + ' Doc = ' + Ap + Doklad + Ap
          + ' WHERE Id = ' + Cells[13, Radek];
          SQL.Text := SQLStr;
          ExecSQL;
        except
          on E: Exception do Zprava('Chyba v pøi ukládání èísla dokladu do databáze.' + ^M + E.Message);
        end;  // try
// kauce do tabulky contracts
        if (Ints[0, Radek] = 1) and (Copy(UpperCase(Cells[3, Radek]), 0, 1) = 'K') then try
          SQLStr := 'UPDATE contracts SET'
          + ' Deposit = ' + Cells[2, Radek]
          + ' WHERE Id = ' + Ap + CId + Ap;
          SQL.Text := SQLStr;
          ExecSQL;
        except
          on E: Exception do dmCode.Zprava('Chyba v pøi ukládání kauce do databáze.' + ^M + E.Message);
        end;  // try
      end;  // for
// 21.3.15 doplnìní technika do øádku vytvoøeného triggerem v DE$_Eus
      DesU.dbAbra.Reconnect;
      with qrAbra do begin
        Close;
        SQLStr := 'SELECT Id FROM Stores'
        + ' WHERE Code = ' + Ap + aedTechnik.Text + Ap;
        SQL.Text := SQLStr;
        Open;
// Id technika
        CId := Fields[0].AsString;
        Close;
// update podle data a èísla dokladu
        SQLStr := 'UPDATE DE$_Eus SET'
        + ' Debit_ID = ' + Ap + CId + Ap
        + ' WHERE Description LIKE ' + Ap + Copy(Doklad, 1 , Pos('/', Doklad)-1) + '%' + Ap
        + ' AND Date$DATE = ' + StringReplace(FloatToStr(Floor(adeDatumDokladu.Date)), ',', '.', []);
        SQL.Text := SQLStr;
        ExecSQL;
      end;  // with qrAbrq
    except
      on E: Exception do begin
        cbXLS.Checked := False;
        cbClear.Checked := False;
        Zprava('Chyba pøi vytváøení dokladu.' + ^M + E.Message);
        Exit;
      end;
    end;  // try
  finally
    Screen.Cursor := crDefault;
  end;  // with fmMain ...
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.MakeFO(aRadek: integer);
// vytvoøení FO
var
  Period_Id,
  Firm_Id,
  FirmOffice_Id,
  VATRate_Id,
  VATIndex_Id,
  ID: string[10];
  Nevyplneno,
  K, S, Z: boolean;
  VATRate,
  Radek: integer;
  FaktObject,
  FaktData,
  RadkyFak,
  RadekFak: variant;
  Druh,
  DruhStr,
  Doklad,
  VS,
  CId,
  SQLStr: string;
begin
  Screen.Cursor := crHourGlass;
  with fmMain, qrMain, asgItems do try
    VS := asgMain.Cells[2, aRadek];
    CId := asgMain.Cells[8, aRadek];
    Firm_Id := asgMain.Cells[9, aRadek];
    FirmOffice_Id := asgMain.Cells[10, aRadek];
// kontrola vyplnìní asgItems
    Nevyplneno := False;
    for Radek := 1 to RowCount-1 do
      if (Ints[0, Radek] = 1) and (Ints[4, Radek] = 0) then begin       // øádek se má zpracovat
        if (Cells[3, Radek] = '') then begin                            // druh není vyplnìn
          Nevyplneno := True;
          Application.MessageBox(PChar(Cells[1, Radek] + ' - druh pøíjmu není vyplnìn.'), 'Druh pøíjmu', MB_ICONERROR + MB_OK);
        end else begin                                                  // druh je vyplnìn
          DruhStr := UpperCase(Cells[3, Radek]);
          Druh := DruhStr[1];
          if (Druh = 'S') or (Druh = 'K') or (Druh = 'Z') then Cells[3, Radek] := Druh
          else begin
{$IFDEF ABAK}
           Application.MessageBox(PChar(Cells[1, Radek] + ' - druh pøíjmu je S nebo Z.'), 'Druh pøíjmu', MB_ICONERROR + MB_OK);
{$ELSE}
            Application.MessageBox(PChar(Cells[1, Radek] + ' - druh pøíjmu je S, K nebo Z.'), 'Druh pøíjmu', MB_ICONERROR + MB_OK);
{$ENDIF}
            Nevyplneno := True;
          end;
        end;  // if (Cells[3, Radek] = '') ... else ...
// kontrola øádkù s nulovou cenou
        if (Floats[2, Radek] = 0) then
          if Application.MessageBox(PChar(Cells[1, Radek] + ' má nulovou cenu. Ponechat v dokladu ?'),
           'Nulová cena', MB_ICONQUESTION + MB_YESNO) = IDNO then Ints[0, Radek] := 0;
      end;  // if (Ints[0, Radek] = 1)...
    if Nevyplneno then begin
      cbClear.Checked := False;
      Exit;
    end;
// konstanty z Abry
    with qrAbra do begin
// Id období
      Close;
      SQL.Text := 'SELECT Id FROM Periods WHERE Code = ' + Ap + FormatDateTime('yyyy', adeDatumDokladu.Date) + Ap;
      Open;
      Period_Id := FieldByName('Id').AsString;
      Close;
// DPH
      SQL.Text := 'SELECT Id, VATRate_Id, Tariff FROM VATIndexes WHERE Code = ''Výst21''';       // 4.1.2013
      Open;
      VATIndex_Id := FieldByName('Id').AsString;
      VATRate_Id := FieldByName('VATRate_Id').AsString;
      VATRate := FieldByName('Tariff').AsInteger;
      Close;
    end;  // with qrAbra
// hlavièka FO
    FaktObject:= AbraOLE.CreateObject('@IssuedInvoice');
    FaktData:= AbraOLE.CreateValues('@IssuedInvoice');
    FaktObject.PrefillValues(FaktData);
    FaktData.ValueByName('DocQueue_ID') := FO_Id;
    FaktData.ValueByName('Period_ID') := Period_Id;
    FaktData.ValueByName('DocDate$DATE') := Floor(adeDatumDokladu.Date);
    FaktData.ValueByName('AccDate$DATE') := Floor(adeDatumDokladu.Date);
    FaktData.ValueByName('VATDate$DATE') := Floor(adeDatumPlneni.Date);
    FaktData.ValueByName('CreatedBy_ID') := User_Id;
    FaktData.ValueByName('Firm_ID') := Firm_Id;
    FaktData.ValueByName('FirmOffice_ID') := FirmOffice_Id;
    FaktData.ValueByName('Address_ID') := MyAddress_Id;
    FaktData.ValueByName('BankAccount_ID') := MyAccount_Id;
    FaktData.ValueByName('ConstSymbol_ID') := '0000308000';
    FaktData.ValueByName('VarSymbol') := VS;
    FaktData.ValueByName('TransportationType_ID') := '1000000101';
    FaktData.ValueByName('PaymentType_ID') := MyPayment_Id;
{$IFDEF ABAK}
    FaktData.ValueByName('DueTerm') := '14';
    FaktData.ValueByName('PricesWithVAT') := False;
    FaktData.ValueByName('TotalRounding') := 257;                // zaokrouhlení na koruny
{$ELSE}
    FaktData.ValueByName('DueTerm') := '10';
    FaktData.ValueByName('PricesWithVAT') := True;
    FaktData.ValueByName('VATFromAbovePrecision') := 6;
    FaktData.ValueByName('TotalRounding') := 259;                // zaokrouhlení na koruny dolù
{$ENDIF}
// kolekce pro øádky faktury
    RadkyFak := FaktData.Value[IndexByName(FaktData, 'Rows')];
// 1. øádek prázdný
    RadekFak:= AbraOLE.CreateValues('@IssuedInvoiceRow');
    RadekFak.ValueByName('Division_ID') := '1000000101';
    RadekFak.ValueByName('RowType') := '0';
    RadkyFak.Add(RadekFak);
// 2. øádek
    RadekFak:= AbraOLE.CreateValues('@IssuedInvoiceRow');
    RadekFak.ValueByName('Division_ID') := '1000000101';
    RadekFak.ValueByName('RowType') := '0';
    RadekFak.ValueByName('Text') := 'Fakturujeme Vám:';
    RadkyFak.Add(RadekFak);
// vybrané øádky s s položkami (ne s placením)
    K := False;
    S := False;
    Z := False;
    for Radek := 1 to RowCount-1 do begin
// øádky se vytvoøí v poøadí S, K, Z
      if (Cells[3, Radek] <> '') then Cells[3, Radek] := UpperCase(char(Cells[3, Radek][1]));
// nejdøíve služby
      if (Ints[0, Radek] = 0) or (Ints[4, Radek] = 1) or (Cells[3, Radek] <> 'S') then Continue;
      RadekFak:= AbraOLE.CreateValues('@IssuedInvoiceRow');
      RadekFak.ValueByName('Division_ID') := '1000000101';
      RadekFak.ValueByName('VATRate_ID') := VATRate_Id;
      RadekFak.ValueByName('VATIndex_ID') := VATIndex_Id;
      RadekFak.ValueByName('VATRate') := IntToStr(VATRate);
      RadekFak.ValueByName('Text') := Cells[1, Radek];
{$IFDEF ABAK}
      RadekFak.ValueByName('IncomeType_ID') := '2000000101';
{$ELSE}
      RadekFak.ValueByName('IncomeType_ID') := '2000000000';
{$ENDIF}
      if Cells[9, Radek] > '1' then begin
        RadekFak.ValueByName('RowType') := '2';
        RadekFak.ValueByName('UnitPrice') := Cells[2, Radek];
        RadekFak.ValueByName('Quantity') := Cells[9, Radek];
      end else begin
        RadekFak.ValueByName('RowType') := '1';
        RadekFak.ValueByName('TotalPrice') := Cells[2, Radek];
      end;
      RadkyFak.Add(RadekFak);
      S := True;
    end;  // for
    for Radek := 1 to RowCount-1 do begin
      if (Cells[3, Radek] <> '') then Cells[3, Radek] := UpperCase(char(Cells[3, Radek][1]));
// pak kauce
      if (Ints[0, Radek] = 0) or (Ints[4, Radek] = 1) or (Cells[3, Radek] <> 'K') then Continue;
      RadekFak:= AbraOLE.CreateValues('@IssuedInvoiceRow');
      RadekFak.ValueByName('Division_ID') := '1000000101';
      RadekFak.ValueByName('VATRate_ID') := '00000X0000';
      RadekFak.ValueByName('VATIndex_ID') := '7000000000';
      RadekFak.ValueByName('VATRate') := '0';
      RadekFak.ValueByName('Text') := 'kauce';
      RadekFak.ValueByName('IncomeType_ID') := '1000000101';
      RadekFak.ValueByName('RowType') := '1';
      RadekFak.ValueByName('TotalPrice') := Cells[2, Radek];
      RadkyFak.Add(RadekFak);
      K := True;
    end;  // for
    for Radek := 1 to RowCount-1 do begin
      if (Cells[3, Radek] <> '') then Cells[3, Radek] := UpperCase(char(Cells[3, Radek][1]));
// nakonec zboží
      if (Ints[0, Radek] = 0) or (Ints[4, Radek] = 1) or (Cells[3, Radek] <> 'Z') then Continue;
      RadekFak:= AbraOLE.CreateValues('@IssuedInvoiceRow');
      RadekFak.ValueByName('Division_ID') := '1000000101';
      RadekFak.ValueByName('VATRate_ID') := VATRate_Id;
      RadekFak.ValueByName('VATIndex_ID') := VATIndex_Id;
      RadekFak.ValueByName('VATRate') := IntToStr(VATRate);
      RadekFak.ValueByName('Text') := Cells[1, Radek];
      if (Cells[5, Radek] <> '') then
        RadekFak.ValueByName('Text') := Format('%s, SN: %s', [Cells[1, Radek], Cells[5, Radek]]);
{$IFDEF ABAK}
      RadekFak.ValueByName('IncomeType_ID') := '1000000101';
{$ELSE}
      RadekFak.ValueByName('IncomeType_ID') := '1000000000';
{$ENDIF}
      RadekFak.ValueByName('RowType') := '2';
      RadekFak.ValueByName('UnitPrice') := Cells[2, Radek];
      RadekFak.ValueByName('Quantity') := Cells[9, Radek];
      RadkyFak.Add(RadekFak);
      Z := True;
    end;  // for
    DruhStr := VS + ' ';
    if S then DruhStr := DruhStr + 'služby, ';
    if K then DruhStr := DruhStr + 'kauce, ';
    if Z then DruhStr := DruhStr + 'zboží, ';
    DruhStr := Copy(DruhStr, 1, Length(DruhStr)-2);
    FaktData.ValueByName('Description') := DruhStr;
// vytvoøení FO
    if RadkyFak.Count > 0 then try
      ID := FaktObject.CreateNewFromValues(FaktData);
      FaktData := FaktObject.GetValues(ID);
      Doklad := string(FaktData.Value[IndexByName(FaktData, 'DisplayName')]);
      Zprava('Vytvoøeno ' + Doklad);
// èíslo dokladu do asgMain
      asgMain.Cells[4, asgMain.Row] := asgMain.Cells[4, asgMain.Row] + ' ' + Doklad;
      for Radek := 1 to RowCount-1 do begin
// èíslo dokladu do asgItems
        if (Ints[0, Radek] = 1) then Cells[14, Radek] := Doklad;
// èíslo dokladu do tabulky simple_billings
        if (Ints[0, Radek] = 1) then try
          SQLStr := 'UPDATE simple_billings SET'
          + ' Doc = ' + Ap + Doklad + Ap
          + ' WHERE Id = ' + Cells[13, Radek];
          SQL.Text := SQLStr;
          ExecSQL;
        except
          on E: Exception do Zprava('Chyba v pøi ukládání èísla faktury do databáze.' + ^M + E.Message);
        end;  // try
// kauce do tabulky contracts
        if Copy(UpperCase(Cells[3, Radek]), 0, 1) = 'K' then try
          SQLStr := 'UPDATE contracts SET'
          + ' Deposit = ' + Cells[2, Radek]
          + ' WHERE Id = ' + Ap + CId + Ap;
          SQL.Text := SQLStr;
          ExecSQL;
        except
          on E: Exception do dmCode.Zprava('Chyba v pøi ukládání kauce do databáze.' + ^M + E.Message);
        end;  // try
      end;  // for
    except
      on E: Exception do begin
        cbClear.Checked := False;
        Zprava('Chyba pøi vytváøení faktury.' + ^M + E.Message);
        Exit;
      end;
    end;  // try
  finally
    Screen.Cursor := crDefault;
  end;  // with fmMain ...
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.MakeDL(aRadek: integer);
// vyskladnìní železa
var
  DocQueue_Id,
  Period_Id,
  Firm_Id,
  FirmOffice_Id,
  ID: string[10];
  DLObject,
  DLData,
  RadkyDL,
  RadekDL,
  Sarze,
  SarzeRadku: variant;
  Radek: integer;
  SQLStr,
  Doklad: string;
begin
// pøevezmou se hodnoty z asgMain
  Firm_Id := fmMain.asgMain.Cells[9, aRadek];
  FirmOffice_Id := fmMain.asgMain.Cells[10, aRadek];
  Screen.Cursor := crHourGlass;
  with fmMain, fmMain.qrMain, fmMain.asgItems do try
// konstanty z Abry
    with qrAbra do begin
// Id období
      Close;
      SQL.Text := 'SELECT Id FROM Periods WHERE Code = ' + Ap + FormatDateTime('yyyy', adeDatumDokladu.Date) + Ap;
      Open;
      Period_Id := FieldByName('Id').AsString;
      Close;
// øada dokladù DL
      SQL.Text := 'SELECT Id FROM DocQueues WHERE Code = ''DL'' AND DocumentType = ''21'' AND Hidden = ''N'' ';
      Open;
      DocQueue_Id := FieldByName('Id').AsString;
      Close;
    end;
// hlavièka DL
    DLObject:= AbraOLE.CreateObject('@BillOfDelivery');
    DLData:= AbraOLE.CreateValues('@BillOfDelivery');
    DLObject.PrefillValues(DLData);
    DLData.ValueByName('DocQueue_ID') := DocQueue_Id;
    DLData.ValueByName('Period_ID') := Period_Id;
    DLData.ValueByName('DocDate$DATE') := Floor(adeDatumDokladu.Date);
    DLData.ValueByName('AccDate$DATE') := Floor(adeDatumDokladu.Date);
    DLData.ValueByName('Firm_ID') := Firm_Id;
    DLData.ValueByName('FirmOffice_ID') := FirmOffice_Id;
    DLData.ValueByName('CreatedBy_ID') := User_Id;
    DLData.ValueByName('Description') := 'Výdej bez úèetního dokladu';
    DLData.ValueByName('IsAvailableForDelivery') := False;
    RadkyDL := DLData.Value[IndexByName(DLData, 'Rows')];
// øádky DL
    for Radek := 1 to RowCount-1 do
      if (Ints[0, Radek] = 1) and (Cells[3, Radek] = 'Z') and (Floats[9, Radek] > 0) then begin
        RadekDL:= AbraOLE.CreateValues('@BillOfDeliveryRow');
        RadekDL.ValueByName('Division_ID') := '1000000101';
        RadekDL.ValueByName('RowType') := 3;
        RadekDL.ValueByName('Store_ID') := Cells[10, Radek];
        RadekDL.ValueByName('StoreCard_ID') := Cells[11, Radek];
        RadekDL.ValueByName('Text') := Cells[7, Radek];
        RadekDL.ValueByName('Quantity') := Cells[9, Radek];
        RadekDL.ValueByName('QUnit') := 'ks';
// výrobní èísla
        if (Cells[12, Radek] <> '') then begin         // je SN
          SarzeRadku := RadekDL.Value[IndexByName(RadekDL, 'DocRowBatches')];
          Sarze := AbraOLE.CreateValues('@DocRowBatch');
          Sarze.ValueByName('StoreBatch_ID') := Cells[12, Radek];
          Sarze.ValueByName('Quantity') := 1;
          SarzeRadku.Add(Sarze);
        end;  // if SN
        RadkyDL.Add(RadekDL);
      end;  // if  Ints[0, Radek] = 1 ...
    if RadkyDL.Count > 0 then try
      ID := DLObject.CreateNewFromValues(DLData);
      DLData := DLObject.GetValues(ID);
      Doklad := string(DLData.Value[IndexByName(DLData, 'DisplayName')]);
      Zprava('Vytvoøeno ' + Doklad);
// èíslo DL do asgMain
      asgMain.Cells[5, asgMain.Row] := asgMain.Cells[5, asgMain.Row] + ' ' + Doklad;
      for Radek := 1 to RowCount-1 do begin
// èíslo DL do asgItems
        if (Ints[0, Radek] = 1) and (Cells[3, Radek] = 'Z') and (Floats[9, Radek] > 0) then Cells[15, Radek] := Doklad;
// èíslo DL do tabulky simple_billings
        if (Ints[0, Radek] = 1) and (Cells[3, Radek] = 'Z') and (Floats[9, Radek] > 0) then try
          SQLStr := 'UPDATE simple_billings SET'
          + ' DL = ' + Ap + Doklad + Ap
          + ' WHERE Id = ' + Cells[13, Radek];
          SQL.Text := SQLStr;
          ExecSQL;
        except
          on E: Exception do Zprava('Chyba v pøi ukládání èísla DL do databáze.' + ^M + E.Message);
        end;  // try
      end;  // for
    except
      on E: Exception do begin
        Zprava('Chyba pøi vytváøení dodacího listu.' + ^M + E.Message);
        Exit;
      end;
    end;  // try
  finally
    Screen.Cursor := crDefault;
  end;  // with fmMain ...
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.MakePR(aRadek: integer);
// pøíjem železa zpìt od zákazníkù je jednodušší udìlat pøíjemkou, pokud má vìc SN, musí se na to dát pozor ("výbìr)
var
  DocQueue_Id,
  Period_Id,
  Firm_Id,
  FirmOffice_Id,
  ID: string[10];
  PRObject,
  PRData,
  RadkyPR,
  RadekPR,
  Sarze,
  SarzeRadku: variant;
  Radek: integer;
  Pocet: double;
  SQLStr,
  Doklad: string;
begin
// pøevezmou se hodnoty z asgMain
  Firm_Id := fmMain.asgMain.Cells[9, aRadek];
  FirmOffice_Id := fmMain.asgMain.Cells[10, aRadek];
  Screen.Cursor := crHourGlass;
  with fmMain, fmMain.qrMain, fmMain.asgItems do try
// konstanty z Abry
    with qrAbra do begin
// Id období
      Close;
      SQL.Text := 'SELECT Id FROM Periods WHERE Code = ' + Ap + FormatDateTime('yyyy', adeDatumDokladu.Date) + Ap;
      Open;
      Period_Id := FieldByName('Id').AsString;
      Close;
// øada dokladù PR
      SQL.Text := 'SELECT Id FROM DocQueues WHERE Code = ''PR'' AND DocumentType = ''20'' AND Hidden = ''N'' ';
      Open;
      DocQueue_Id := FieldByName('Id').AsString;
      Close;
    end;
// hlavièka PR
    PRObject:= AbraOLE.CreateObject('@ReceiptCard');
    PRData:= AbraOLE.CreateValues('@ReceiptCard');
    PRObject.PrefillValues(PRData);
    PRData.ValueByName('DocQueue_ID') := DocQueue_Id;
    PRData.ValueByName('Period_ID') := Period_Id;
    PRData.ValueByName('DocDate$DATE') := Floor(adeDatumDokladu.Date);
    PRData.ValueByName('AccDate$DATE') := Floor(adeDatumDokladu.Date);
    PRData.ValueByName('Firm_ID') := Firm_Id;
    PRData.ValueByName('FirmOffice_ID') := FirmOffice_Id;
    PRData.ValueByName('CreatedBy_ID') := User_Id;
    PRData.ValueByName('Description') := 'Pøíjem bez úèetního dokladu';
    PRData.ValueByName('IsAvailableForDelivery') := False;
    RadkyPR := PRData.Value[IndexByName(PRData, 'Rows')];
// øádky PR
    for Radek := 1 to RowCount-1 do
      if (Ints[0, Radek] = 1) and (Cells[3, Radek] = 'Z') and (Floats[9, Radek] < 0) then begin
        RadekPR:= AbraOLE.CreateValues('@ReceiptCardRow');
        RadekPR.ValueByName('Division_ID') := '1000000101';
        RadekPR.ValueByName('RowType') := 3;
        RadekPR.ValueByName('Store_ID') := Cells[10, Radek];
        RadekPR.ValueByName('StoreCard_ID') := Cells[11, Radek];
        RadekPR.ValueByName('Text') := Cells[7, Radek];
        RadekPR.ValueByName('Quantity') := FloatToStr(Floats[9, Radek] * -1);
        RadekPR.ValueByName('QUnit') := 'ks';
// výrobní èísla - tohle bude jinak ??
        if (Cells[12, Radek] <> '') then begin         // je SN
          SarzeRadku := RadekPR.Value[IndexByName(RadekPR, 'DocRowBatches')];
          Sarze := AbraOLE.CreateValues('@DocRowBatch');
          Sarze.ValueByName('StoreBatch_ID') := Cells[12, Radek];
          Sarze.ValueByName('Quantity') := 1;
          SarzeRadku.Add(Sarze);
        end;  // if SN
        RadkyPR.Add(RadekPR);
      end;  // if  Ints[0, Radek] = 1 ...
    if RadkyPR.Count > 0 then try
      ID := PRObject.CreateNewFromValues(PRData);
      PRData := PRObject.GetValues(ID);
      Doklad := string(PRData.Value[IndexByName(PRData, 'DisplayName')]);
      Zprava('Vytvoøeno ' + Doklad);
// èíslo PR do asgMain
      asgMain.Cells[5, asgMain.Row] := asgMain.Cells[5, asgMain.Row] + ' ' + Doklad;
      for Radek := 1 to RowCount-1 do begin
// èíslo PR do asgItems
        if (Ints[0, Radek] = 1) and (Cells[3, Radek] = 'Z') and (Floats[9, Radek] < 0) then Cells[15, Radek] := Doklad;
// èíslo PR do tabulky simple_billings
        if (Ints[0, Radek] = 1) and (Cells[3, Radek] = 'Z') and (Floats[9, Radek] < 0) then try
          SQLStr := 'UPDATE simple_billings SET'
          + ' DL = ' + Ap + Doklad + Ap
          + ' WHERE Id = ' + Cells[13, Radek];
          SQL.Text := SQLStr;
          ExecSQL;
        except
          on E: Exception do Zprava('Chyba v pøi ukládání èísla PR do databáze.' + ^M + E.Message);
        end;  // try
      end;  // for
    except
      on E: Exception do begin
        Zprava('Chyba pøi vytváøení pøíjemky.' + ^M + E.Message);
        Exit;
      end;
    end;  // try
  finally
    Screen.Cursor := crDefault;
  end;  // with fmMain ...
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.UpdateTechniciXLS(aRadek: integer);
// peníze z PP do technici.xls
// kód v Excelu dìlá problémy, proto Open Office
{ OpenOffice start at cell (0,0) while Excel at (1,1)        }
{ Also, Excel uses (row, col) and OpenOffice uses (col, row) }
const
  ooHAlignStd = 0; //    com.sun.star.table.CellHoriJustify.STANDARD
  ooHAlignLeft = 1; //   com.sun.star.table.CellHoriJustify.LEFT
  ooHAlignCenter = 2; // com.sun.star.table.CellHoriJustify.CENTER
  ooHAlignRight = 3; //  com.sun.star.table.CellHoriJustify.RIGHT
var
  ServiceManager,
  Desktop,
  LoadParams,
  Dokument,
  Sheet: variant;
  Hotovost: double;
  XLSName: string;
  Radek: integer;

  function SetParams (Name: string; Data: variant): variant;
// zadání parametrù pøi otevírání souboru (?)
  var
    Reflection: variant;
  begin
    Reflection := ServiceManager.CreateInstance('com.sun.star.reflection.CoreReflection');
    Reflection.forName('com.sun.star.beans.PropertyValue').createObject(result);
    result.Name := Name;
    result.Value := Data;
  end;

begin
  Screen.Cursor := crHourGlass;
  with fmMain, fmMain.asgMain do try
// hotovost z asgItems
    Hotovost := 0;
    for Radek := 1 to asgItems.RowCount-1 do
      if asgItems.Ints[4, Radek] = 1 then Hotovost := Hotovost + asgItems.Floats[2, Radek];
// v asgMain musí existovat PP a èástka musí být záporná
    if (Pos('PP', Cells[4, aRadek] )= 0) or (Hotovost >= 0) then Exit;
// OO ještì nebyl spuštìn
    if VarIsEmpty(ServiceManager) then try
// zkusí se, jestli nebìží
      ServiceManager := GetActiveOleObject('com.sun.star.ServiceManager');
    except try
// jinak se spustí
      ServiceManager := CreateOleObject('com.sun.star.ServiceManager');
      except
        on E: Exception do begin
          cbClear.Checked := False;
          Zprava('Nelze spustit OpenOffice' + ^M + E.Message);
          Exit;
        end;
      end;  // try
    end;  // try
    if (VarIsEmpty(ServiceManager) or VarIsNull(ServiceManager)) then begin
      cbClear.Checked := False;
      Zprava('Nelze spustit OpenOffice.');
      Exit;
    end;
// povedlo se
    if VarIsEmpty(Desktop) then Desktop := ServiceManager.CreateInstance('com.sun.star.frame.Desktop');
// soubor technikù
    XLSName := FormatDateTime('"W:/"yy"/technici"yy".xls"', Date);
// (popis parametrù v OO MediaDescriptor)
    LoadParams := VarArrayCreate([0, 0], varVariant);
// listy nebudou vidìt
    LoadParams[0] := SetParams('Hidden', True);
// soubor se otevøe
    try
      Dokument := Desktop.LoadComponentFromURL('file:///' + XLSName, '_default', 0, LoadParams);
    except
      on E: Exception do begin
        cbClear.Checked := False;
        Zprava('Nepodaøilo se otevøít ' + XLSName + ^M + E.Message);
        if not (VarIsEmpty(ServiceManager) or VarIsNull(ServiceManager)) then ServiceManager := Unassigned;
        Exit;
      end;
    end;
    if (VarIsEmpty(Dokument) or VarIsNull(Dokument)) then begin
      cbClear.Checked := False;
      Zprava('Nepodaøilo se otevøít ' + XLSName);
      if not (VarIsEmpty(ServiceManager) or VarIsNull(ServiceManager)) then ServiceManager := Unassigned;
      Exit;
    end;
// aktivní list (podle technika)
    try
      Sheet := Dokument.getSheets.getByName(asgMain.Cells[6, aRadek]);
    except
      on E: Exception do begin
        cbClear.Checked := False;
        Zprava('Nepodaøilo se otevøít list ' + asgMain.Cells[6, aRadek] + ^M + E.Message);
        if not (VarIsEmpty(Desktop) or VarIsNull(Desktop)) then Desktop := Unassigned;
        if not (VarIsEmpty(ServiceManager) or VarIsNull(ServiceManager)) then ServiceManager := Unassigned;
        Exit;
      end;
    end;
    if (VarIsEmpty(Sheet) or VarIsNull(Sheet)) then begin
      cbClear.Checked := False;
      Zprava('Nepodaøilo se otevøít list ' + asgMain.Cells[6, aRadek]);
      if not (VarIsEmpty(Desktop) or VarIsNull(Desktop)) then Desktop := Unassigned;
      if not (VarIsEmpty(ServiceManager) or VarIsNull(ServiceManager)) then ServiceManager := Unassigned;
      Exit;
    end;
    Dokument.getCurrentController.setActiveSheet(Sheet);
// bude se hledat první prázdný øádek
    Radek := 3;
    while (Sheet.getCellByPosition(2, Radek).getFormula <> '') do Inc(Radek);      // sloupec s èástkami
// vloží se hodnoty
    Sheet.getCellByPosition(0, Radek).String := FormatDateTime('d.m.', Date);
    Sheet.getCellByPosition(0, Radek).HoriJustify := ooHAlignLeft;
    Sheet.getCellByPosition(1, Radek).Value := Hotovost;
    Sheet.getCellByPosition(1, Radek).HoriJustify := ooHAlignRight;;
    Sheet.getCellByPosition(2, Radek).String := Trim(asgMain.Cells[4, aRadek]) +  ' ' + asgMain.Cells[2, aRadek];  // PP + VS
    Sheet.getCellByPosition(2, Radek).HoriJustify := ooHAlignLeft;
    try
      Dokument.Store;
      Zprava(Format('Èástka %f pøidána na list %s.', [Hotovost, asgMain.Cells[6, aRadek]]));
    except
      Application.MessageBox(PChar('Nedá se uložit ' +  XLSName + '. Není nìkde otevøený ?' ), 'Open Office Calc', MB_ICONERROR + MB_OK);
      Zprava('Nedá se uložit ' +  XLSName);
      cbClear.Checked := False;
    end;
    Dokument.Dispose;
  finally
// Clean up
    Dokument := Null;
    Sheet := Null;
    if not (VarIsEmpty(Desktop) or VarIsNull(Desktop)) then Desktop := Unassigned;
    if not (VarIsEmpty(ServiceManager) or VarIsNull(ServiceManager)) then ServiceManager := Unassigned;
    Screen.Cursor := crDefault;
  end;  // with fmMain ...
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCode.ClearRequest(aRadek: integer);
// oprava popisù vytvoøených dokladù (FO/PP vs. DL/PR)
// vymazání žádostí o fakturaci
var
  Radek: integer;
  DL,
  Doc,
  Cislo,
  DLkFO,
  FOkDL,
  Popis,
  SQLStr: string;
  Period_Id: string[10];
begin
  Screen.Cursor := crHourGlass;
  with fmMain, fmMain.qrMain do try
// popis k FO/PP
    Close;
    DesU.dbZakos.Reconnect;
    DesU.dbAbra.Reconnect;
// najdou všechny vytvoøené doklady pro tuto dávku
    SQLStr := 'SELECT DISTINCT Doc FROM simple_billings'
    + ' WHERE Customer_Id = ' + Ap + asgMain.Cells[7, aRadek] + Ap
    + ' AND Doc IS NOT NULL'
    + ' AND Doc <> '''''
    + ' AND Past = 0';
    if asgMain.Cells[8, aRadek] <> '' then
      SQLStr := SQLStr + ' AND Contract_Id = ' + Ap + asgMain.Cells[8, aRadek] + Ap;
    SQL.Text := SQLStr;
    Open;
// pro každý doklad
    while not EOF do begin
      Doc := FieldByName('Doc').AsString;                  // display name
      Cislo := Copy(Doc, Pos('-', Doc)+1, Pos('/', Doc) - Pos('-', Doc)-1);
      with qrAbra do begin
// Id období
        SQL.Text := 'SELECT Id FROM Periods WHERE Code = ' + Ap + Copy(Doc, Pos('/', Doc)+1, 4) + Ap;
        Open;
        Period_Id := FieldByName('Id').AsString;
        Close;
      end;
// a všechny DL/PR
      with qrItems do begin
        Close;
        SQLStr := 'SELECT DISTINCT DL FROM simple_billings'
        + ' WHERE Doc = ' + Ap + Doc + Ap
        + ' AND DL IS NOT NULL'
        + ' AND DL <> '''''
        + ' AND Past = 0';
        SQL.Text := SQLStr;
        Open;
        if (RecordCount > 0) then begin
          DLkFO := ' (';
          while not EOF do begin
            DLkFO := DLkFO + Trim(FieldByName('DL').AsString) + ' ';
            Next;
          end;
          DLkFO := Copy(DLkFO, 1, Length(DLkFO)-1) + ')';
// oprava popisu faktury (pokud existuje DL/PR)
          with qrAbra do begin
            if (Pos('F', Doc) > 0) then SQLStr := 'SELECT Description FROM IssuedInvoices'
            + ' WHERE DocQueue_Id = ' + Ap + FO_Id + Ap
            else if (Pos('PP', Doc) > 0) then SQLStr := 'SELECT Description FROM CashReceived'
            + ' WHERE DocQueue_Id = ' + Ap + PP_Id + Ap;
            SQLStr := SQLStr
            + ' AND Period_Id = ' + Ap + Period_Id + Ap
            + ' AND OrdNumber = ' + Cislo;
            Close;
            SQL.Text := SQLStr;
            Open;
            if (Pos('(', FieldByName('Description').AsString) > 0) then
              Popis := Copy(FieldByName('Description').AsString, 1, Pos('(', FieldByName('Description').AsString)-1)
            else Popis := FieldByName('Description').AsString;
            Close;
            if (Pos('F', Doc) > 0) then SQLStr := 'UPDATE IssuedInvoices SET'
            + ' Description = ' + Ap + Popis + DLkFO + Ap
            + ' WHERE DocQueue_Id = ' + Ap + FO_Id + Ap
            else if (Pos('PP', Doc) > 0) then SQLStr := 'UPDATE CashReceived SET'
            + ' Description = ' + Ap + Popis + DLkFO + Ap
            + ' WHERE DocQueue_Id = ' + Ap + PP_Id + Ap;
            SQLStr := SQLStr
            + ' AND Period_Id = ' + Ap + Period_Id + Ap
            + ' AND OrdNumber = ' + Cislo;
            SQL.Text := SQLStr;
            ExecSQL;
          end;  // with qrAbra
        end;  // if (RecordCount > 0)
        Close;
      end;  // with qrItems
      Next;
    end;  // while not qrMain.EOF
    Close;
// popis k DL/PR
// najdou všechny vytvoøené DL/PR pro tuto dávku
    SQLStr := 'SELECT DISTINCT DL FROM simple_billings'
    + ' WHERE Customer_Id = ' + Ap + asgMain.Cells[7, aRadek] + Ap
    + ' AND DL IS NOT NULL'
    + ' AND DL <> '''''
    + ' AND Past = 0';
    if asgMain.Cells[8, aRadek] <> '' then
      SQLStr := SQLStr + ' AND Contract_Id = ' + Ap + asgMain.Cells[8, aRadek] + Ap;
    SQL.Text := SQLStr;
    Open;
// pro každý DL/PR
    while not EOF do begin
      DL := FieldByName('DL').AsString;                  // display name
      Cislo := Copy(DL, Pos('-', DL)+1, Pos('/', DL) - Pos('-', DL)-1);
      with qrAbra do begin
// Id období
        SQL.Text := 'SELECT Id FROM Periods WHERE Code = ' + Ap + Copy(DL, Pos('/', DL)+1, 4) + Ap;
        Open;
        Period_Id := FieldByName('Id').AsString;
        Close;
      end;
// a všechny doklady
      with qrItems do begin
        Close;
        SQLStr := 'SELECT DISTINCT Doc FROM simple_billings'
        + ' WHERE DL = ' + Ap + DL + Ap
        + ' AND Doc IS NOT NULL'
        + ' AND Doc <> '''''
        + ' AND Past = 0';
        SQL.Text := SQLStr;
        Open;
        if (RecordCount > 0) then begin
          FOkDL := ' ';
          while not EOF do begin
            FOkDL := FOkDL + FieldByName('Doc').AsString + ' ';
            Next;
          end;
// oprava popisu DL/PR
          with qrAbra do begin
            if (Pos('DL', DL) > 0) then SQLStr := 'UPDATE StoreDocuments SET'
            + ' Description = ' + Ap + 'Výdej k' + FOkDL + Ap
            + ' WHERE DocQueue_Id = ' + Ap + DL_Id + Ap
            else if (Pos('PR', DL) > 0) then SQLStr := 'UPDATE StoreDocuments SET'
            + ' Description = ' + Ap + 'Pøíjem k' + FOkDL + Ap
            + ' WHERE DocQueue_Id = ' + Ap + PR_Id + Ap;
            SQLStr := SQLStr
            + ' AND Period_Id = ' + Ap + Period_Id + Ap
            + ' AND OrdNumber = ' + Cislo;
            SQL.Text := SQLStr;
            ExecSQL;
          end;  // with qrAbra
        end;  // if (RecordCount > 0)
        Close;
      end;  // with qrItems
      Next;
    end;  // while not qrMain.EOF
    Close;
// vymazání žádostí o fakturaci
    with asgItems do
      for Radek := 1 to RowCount-1 do
        if Ints[0, Radek] = 1 then try
          SQLStr := 'UPDATE simple_billings SET'
          + ' Past = 1'
          + ' WHERE Id = ' + Cells[13, Radek];
          SQL.Text := SQLStr;
          ExecSQL;
        except on E: Exception do
          begin
            Zprava('Chyba v pøi opravì v databázi.' + ^M + E.Message);
            Exit;
          end;
        end;  // if
  finally
    Screen.Cursor := crDefault;
  end;  // with ...
  Zprava('Žádost vymazána.');
end;

end.

