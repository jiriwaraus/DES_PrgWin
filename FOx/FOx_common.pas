unit FOx_common;

interface

uses
  Windows, SysUtils, Classes, Forms, Controls, DateUtils, Math, Registry, FOx_Main;

type
  TdmCommon = class(TDataModule)
  public
    function UserName: AnsiString;
    function CompName: AnsiString;
    function IndexByName(DataObject: variant; Name: ShortString): integer;
    procedure Zprava(TextZpravy: AnsiString);
    procedure Plneni_asgMain;
  end;

const
  Ap = chr(39);
  ApC = Ap + ',';
  ApZ = Ap + ')';
  MyAddress_Id: string[10] = '7000000101';
  MyAccount_Id: string[10] = '1400000101';       // Fio
  User_Id: string[10] = '2200000101';            // automatická fakturace
  Payment_Id: string[10] = '1000000101';         // typ platby: na bankovní úèet
  VATIndex_Id: string[10] = '6521000000';
  VATRate_Id: string[10] = '02100X0000';
  VATRate = '21';
var
  dmCommon: TdmCommon;

implementation

{$R *.dfm}

uses AdvGrid;

// ------------------------------------------------------------------------------------------------

function TdmCommon.UserName : AnsiString;
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

function TdmCommon.CompName : AnsiString;
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

procedure TdmCommon.Zprava(TextZpravy: AnsiString);
// do listboxu a logfile uloží èas a text zprávy
begin
  with fmMain do begin
    lbxLog.Items.Add(FormatDateTime('dd.mm.yy hh:nn:ss  ', Now) + TextZpravy);
    lbxLog.ItemIndex := lbxLog.Count - 1;
    Application.ProcessMessages;
    Sleep(10);
    Append(F);
    Writeln (F, Format('(%s - %s) ', [Trim(CompName), Trim(UserName)]) + FormatDateTime('dd.mm.yy hh:nn:ss  ', Now) + TextZpravy);
    CloseFile(F);
  end;
end;

// ------------------------------------------------------------------------------------------------

procedure TdmCommon.Plneni_asgMain;
var
  Radek: integer;
  VarSymbol: string[10];
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
    with qrAbra, asgMain do try
      ClearNormalCells;
      RowCount := 2;
      Close;
// doklady FOx se hledají v IssuedInvoices
      dmCommon.Zprava(Format('Naètení vytvoøených dokladù od %s do %s.', [aedOd.Text, aedDo.Text]));
      Close;
      dbAbra.Reconnect;
      SQLStr := 'SELECT Name, OrdNumber, VarSymbol, Amount FROM Firms F, IssuedInvoices II'
      + ' WHERE II.Firm_ID = F.ID'
      + ' AND F.Firm_ID IS NULL'
      + ' AND OrdNumber >= ' + aedOd.Text
      + ' AND OrdNumber <= ' + aedDo.Text;
      if rbInternet.Checked then SQLStr := SQLStr + ' AND DocQueue_ID = ' + Ap + FO4Queue_Id + Ap
      else SQLStr := SQLStr + ' AND DocQueue_ID = ' + Ap + FO2Queue_Id + Ap;
      SQLStr := SQLStr + ' ORDER BY OrdNumber';
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
// u FOx je VS èíslo smlouvy
          SQLStr := 'SELECT DISTINCT Postal_mail AS Mail, Disable_mailings AS Reklama FROM customers Cu, contracts C'
          + ' WHERE Cu.Id = C.Customer_Id'
          + ' AND C.Number = ' + Ap + VarSymbol + Ap;
          SQL.Text := SQLStr;
          Open;
          while not EOF do begin
            Inc(Radek);
            RowCount := Radek + 1;
            AddCheckBox(0, Radek, True, True);
            Ints[0, Radek] := 1;                                                   // fajfka tisk - mail
            Cells[1, Radek] := VarSymbol;                                          // smlouva
            Cells[2, Radek] := Format('%4.4d', [qrAbra.FieldByName('OrdNumber').AsInteger]);     // faktura
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
      Close;
      dmCommon.Zprava(Format('Poèet dokladù: %d', [Trunc(ColumnSum(0, 1, RowCount-1))]));
      if ColumnSum(0, 1, RowCount-1) > 0 then
        if arbPrevod.Checked then btVytvorit.Caption := '&Pøevést'
        else if arbTisk.Checked then btVytvorit.Caption := '&Vytisknout'
        else if arbMail.Checked then btVytvorit.Caption := '&Odeslat';
    except on E: Exception do
      Zprava('Neošetøená chyba: ' + E.Message);
    end;  // with qrAbra
  finally
    qrMain.Close;
    apbProgress.Position := 0;
    apbProgress.Visible := False;
    if arbPrevod.Checked then apnPrevod.Visible := True;
    if arbTisk.Checked then apnTisk.Visible := True;
    if arbMail.Checked then apnMail.Visible := True;
    Screen.Cursor := crDefault;
    btVytvorit.Enabled := True;
    btVytvorit.SetFocus;
  end;
end;

end.

