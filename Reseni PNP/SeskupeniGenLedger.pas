unit SeskupeniGenLedger;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids, AdvObj,
  BaseGrid, AdvGrid, Vcl.ComCtrls;

type
  TfmSeskupeniVDeniku = class(TForm)
    btnNactiData: TButton;
    btnProvedSeskupeni: TButton;
    editKodUctu: TEdit;
    chb1: TCheckBox;
    chb2: TCheckBox;
    asgSeskupeniVDeniku: TAdvStringGrid;
    lblLimit: TLabel;
    editLimit: TEdit;
    editFirmName: TEdit;
    lblFirma: TLabel;
    rb1: TRadioButton;
    rb2: TRadioButton;
    dtpDatumOd: TDateTimePicker;
    dtpDatumDo: TDateTimePicker;
    lblPomlcka: TLabel;
    Label1: TLabel;
    chb3: TCheckBox;
    procedure asgSeskupeniVDenikuCanEditCell(Sender: TObject; ARow,
      ACol: Integer; var CanEdit: Boolean);
    procedure asgSeskupeniVDenikuCanSort(Sender: TObject; ACol: Integer;
      var DoSort: Boolean);
    procedure asgSeskupeniVDenikuClickCell(Sender: TObject; ARow,
      ACol: Integer);
    procedure btnNactiDataClick(Sender: TObject);
    procedure btnProvedSeskupeniClick(Sender: TObject);
    procedure asgSeskupeniVDenikuGetAlignment(Sender: TObject; ARow,
      ACol: Integer; var HAlign: TAlignment; var VAlign: TVAlignment);
  private
    { Private declarations }
  public
    procedure nactiData;
    procedure nactiDataNeseskupeneRadky;
    procedure nactiDataPoSkupinach;

    procedure provedSeskupeni;
  end;

var
  fmSeskupeniVDeniku: TfmSeskupeniVDeniku;
  asgSeskupeniAllRowsChecked: boolean;

implementation

{$R *.dfm}

uses
  DesUtils;

procedure TfmSeskupeniVDeniku.nactiData;
var
  SQLStr1, SQLStr2, accountId: string;
  radek: integer;
begin

  if rb1.Checked then
    nactiDataPoSkupinach
  else if rb2.Checked then
    nactiDataNeseskupeneRadky;
end;


procedure TfmSeskupeniVDeniku.nactiDataNeseskupeneRadky;
var
  SQLStr1, SQLStr2, accountId: string;
  radek: integer;
begin

  //najdu všechny firmy, které mají pro daný úèet v GeneralLedger samostatný (neseskupený) øádek
  SQLStr1 := 'SELECT G1.Firm_ID FROM GENERALLEDGER G1'
      + ' JOIN Firms ON G1.Firm_ID = Firms.Id '
      + ' WHERE G1.DebitAccount_ID = (  SELECT Id FROM Accounts  WHERE Code = ''' + trim(editKodUctu.Text) + ''' AND Hidden = ''N'' )'
      + '   AND NOT EXISTS (SELECT G2.ID FROM GENERALLEDGER G2 WHERE G2.AccGroup_ID = G1.AccGroup_ID AND G2.ID <> G1.ID)'
      + '   AND Firms.Name like ''' + trim(editFirmName.Text) + ''' ';

  SQLStr1 := SQLStr1 + ' UNION SELECT G1.Firm_ID FROM GENERALLEDGER G1'
      + ' JOIN Firms ON G1.Firm_ID = Firms.Id '
      + ' WHERE G1.CreditAccount_ID = (  SELECT Id FROM Accounts  WHERE Code = ''' + trim(editKodUctu.Text) + ''' AND Hidden = ''N'' )'
      + '   AND NOT EXISTS (SELECT G2.ID FROM GENERALLEDGER G2 WHERE G2.AccGroup_ID = G1.AccGroup_ID AND G2.ID <> G1.ID)'
      + '   AND Firms.Name like ''' + trim(editFirmName.Text) + ''' ';


  DesU.dbAbra.Reconnect;
  Screen.Cursor := crHourGlass;
  asgSeskupeniVDeniku.ClearNormalCells;
  asgSeskupeniVDeniku.RowCount := 2;
  asgSeskupeniAllRowsChecked := true;
  DesU.qrAbra.SQL.Text := SQLStr1;
  DesU.qrAbra.Open;

  asgSeskupeniVDeniku.CheckFalse := '10';
  asgSeskupeniVDeniku.CheckTrue := '11';
  radek := 0;

  while not DesU.qrAbra.EOF do
  with DesU.qrAbra2, asgSeskupeniVDeniku do begin

    //pro danou firmu najdu v GeneralLedger všechny samostatné (neseskupené) øádky
    SQLStr2 := 'SELECT Firms.Name as FirmName, Firms.Code as FirmCode, G1.Firm_ID, G1.Amount, G1.Text, G1.ACCGROUP_ID, G1.CREDITACCOUNT_ID, G1.DEBITACCOUNT_ID, G1.ID, G1.ACCDATE$DATE, CAccounts.Code as CACode, DAccounts.Code as DACode'
      + ' FROM GENERALLEDGER G1'
      + ' JOIN Firms ON G1.Firm_ID = Firms.Id '
      + ' JOIN Accounts CAccounts ON G1.CREDITACCOUNT_ID = CAccounts.Id '
      + ' JOIN Accounts DAccounts ON G1.DEBITACCOUNT_ID = DAccounts.Id '
      + ' WHERE G1.Firm_ID = ''' + DesU.qrAbra.FieldByName('Firm_ID').AsString + ''''
      + '   AND NOT EXISTS (SELECT G2.ID FROM GENERALLEDGER G2 WHERE G2.AccGroup_ID = G1.AccGroup_ID AND G2.ID <> G1.ID)';

    if chb1.Checked then
      SQLStr2 := SQLStr2 +' AND G1.Audited = ''N''';

    SQL.Text := SQLStr2;
    Open;

    while not EOF do begin
      Inc(radek);
      if radek > StrToInt(editLimit.Text) then Break;

      RowCount := radek + 1;
      AddCheckBox(0, radek, True, True);
      Cells[1, radek] := FieldByName('FirmName').AsString + '  (' + FieldByName('FirmCode').AsString + ')' ;
      Cells[2, radek] := FieldByName('Text').AsString;
      Cells[3, radek] := format('%m', [FieldByName('Amount').AsCurrency]);
      Cells[4, radek] := DateToStr(FieldByName('ACCDATE$DATE').AsFloat);
      Cells[5, radek] := FieldByName('DACode').AsString;
      Cells[6, radek] := FieldByName('CACode').AsString;
      Cells[7, radek] := FieldByName('ACCGROUP_ID').AsString;
      Cells[8, radek] := FieldByName('ID').AsString;


      //FontColors[7, radek] := $999999;
      //FontColors[8, radek] := $999999;
      Application.ProcessMessages;
      Next;
    end;
    Close;
    Inc(radek);

    DesU.qrAbra.Next;
  end;
  DesU.qrAbra.Close;
  Screen.Cursor := crDefault;
end;

procedure TfmSeskupeniVDeniku.nactiDataPoSkupinach;
var
  SQLStr1, SQLStr2, accountId, oldFirmCode: string;
  radek, pocetVeSkupine: integer;
begin

  DesU.dbAbra.Reconnect;
  Screen.Cursor := crHourGlass;
  asgSeskupeniVDeniku.ClearNormalCells;
  asgSeskupeniVDeniku.RowCount := 2;
  asgSeskupeniAllRowsChecked := true;
  radek := 1;
  pocetVeSkupine := 0;
  oldFirmCode := '';


  with DesU.qrAbra2, asgSeskupeniVDeniku do begin

    //pro danou firmu najdu v GeneralLedger všechny samostatné (neseskupené) øádky
    SQLStr2 := 'SELECT p.DATUM, p.DOKLAD, p.TEXT, p.CASTKA, p.MD as DACode, p.D as CACode, p.FIRMNAME, p.FIRMCODE, p.ID, p.FIRM_ID, p.ACCGROUP_ID, p.AUDITED, p.SUMA'
      + ' FROM DE$_UCET_PO_SKUPINACH(''' + trim(editKodUctu.Text) + ''') p'
      + ' WHERE lower (p.FIRMNAME) like lower(''' + trim(editFirmName.Text) + ''') '
      + ' AND p.DATUM >= ' + IntToStr(Trunc(dtpDatumOd.Date))
      + ' AND p.DATUM <= ' + IntToStr(Trunc(dtpDatumDo.Date));


    if chb1.Checked then
      SQLStr2 := SQLStr2 +' AND p.Audited = ''N''';

    if not chb3.Checked then
      SQLStr2 := SQLStr2 +' AND p.SUMA <> 0';


    SQL.Text := SQLStr2;
    Open;

    while not EOF do begin
      if radek > StrToInt(editLimit.Text) then Break;

      if oldFirmCode <> FieldByName('FirmCode').AsString then begin //další firma
        if (pocetVeSkupine = 1) and (not chb2.Checked) then begin
           radek := radek - 2;
        end;
        oldFirmCode := FieldByName('FirmCode').AsString;
        Inc(radek);
        pocetVeSkupine := 0;
      end;

      RowCount := radek + 1;
      AddCheckBox(0, radek, True, True);
      Cells[1, radek] := FieldByName('FirmName').AsString + '  (' + FieldByName('FirmCode').AsString + ')' ;
      Cells[2, radek] := FieldByName('Text').AsString;
      Cells[3, radek] := format('%m', [FieldByName('Castka').AsCurrency]);
      Cells[4, radek] := DateToStr(FieldByName('Datum').AsFloat);
      Cells[5, radek] := FieldByName('DACode').AsString;
      Cells[6, radek] := FieldByName('CACode').AsString;
      Cells[7, radek] := FieldByName('ACCGROUP_ID').AsString;
      Cells[8, radek] := FieldByName('ID').AsString;
      Cells[9, radek] := FieldByName('Suma').AsString;


      //FontColors[7, radek] := $999999;
      //FontColors[8, radek] := $999999;

      Inc(radek);
      Inc(pocetVeSkupine);
      Application.ProcessMessages;
      Next;
    end;
      if (pocetVeSkupine = 1) and (not chb2.Checked) then begin
        radek := radek - 2;
        RowCount := radek + 1;
      end;
    Close;
  end;
  Screen.Cursor := crDefault;
end;


procedure TfmSeskupeniVDeniku.provedSeskupeni;
var
  SQLStr: AnsiString;
  radek: integer;
  chbstate: boolean;
  currentAccGroupId: string;
begin

  with DesU.qrAbra, asgSeskupeniVDeniku do begin


    currentAccGroupId := '';
    radek := FixedRows;

    //for radek := FixedRows + 1 to RowCount - 1 do begin  //zaèínáme na 2. datovém øádku, tedy 3. øádku celkovì
    while radek < RowCount do begin

      if (Cells[1, radek] = '') then begin  //když je prázdný øádek, tedy oddìlovaè
        currentAccGroupId := '';
        radek := radek + 1;
      end;

      while (currentAccGroupId = '') AND (radek < RowCount - 1) do begin
        GetCheckBoxState(0, radek, chbstate);
        if chbstate then
          currentAccGroupId := Cells[7, radek];
        radek := radek + 1;
      end;
      if (Cells[1, radek] = '') then Continue;


      GetCheckBoxState(0, radek, chbstate);
      if chbstate AND (Cells[1, radek] <> '') AND (currentAccGroupId <> '') then //zaškrlý checkbox a jméno firmy vyplnìné a na pøedchozím øádku je ACCGROUP_ID
      begin
        Cells[0, radek] := '...';
        RemoveCheckBox(0, radek);
        try
          SQL.Text := 'UPDATE GeneralLedger SET ACCGROUP_ID = ''' + currentAccGroupId + ''''
                    + ' WHERE Id = ''' + Cells[8, radek] + '''';
          ExecSQL;
          Cells[9, radek] := 'SET ACCGROUP_ID = ''' + currentAccGroupId + ''' WHERE Id = ''' + Cells[8, radek] + '''';
          Close;

          Cells[0, radek] := 'ok';
        except
          on E: Exception do
          Cells[0, radek] := 'fail';
        end;
        Application.ProcessMessages;
      end;
      radek := radek + 1;
    end;

    DesU.dbAbra.Reconnect;

    Close;

  end;
end;

{*********************** akce Input elementù **********************************}

procedure TfmSeskupeniVDeniku.btnNactiDataClick(Sender: TObject);
begin
  nactiData;
end;

procedure TfmSeskupeniVDeniku.btnProvedSeskupeniClick(Sender: TObject);
begin
  provedSeskupeni;
end;

procedure TfmSeskupeniVDeniku.asgSeskupeniVDenikuCanEditCell(Sender: TObject;
  ARow, ACol: Integer; var CanEdit: Boolean);
begin
  CanEdit := true;
end;

procedure TfmSeskupeniVDeniku.asgSeskupeniVDenikuCanSort(Sender: TObject;
  ACol: Integer; var DoSort: Boolean);
begin
  DoSort := ACol <> 0;
end;

procedure TfmSeskupeniVDeniku.asgSeskupeniVDenikuClickCell(Sender: TObject;
  ARow, ACol: Integer);
var
  radek: integer;
  chbstate: boolean;
begin

  if (ARow = 0) and (ACol = 0) then begin
    asgSeskupeniAllRowsChecked := not asgSeskupeniAllRowsChecked;
    for radek := 1 to asgSeskupeniVDeniku.RowCount - 1 do
      asgSeskupeniVDeniku.SetCheckBoxState(ACol, radek, asgSeskupeniAllRowsChecked);
    exit;
  end;


  if (ARow > 0) and (ACol = 0) then begin
    radek := ARow + 1;
    asgSeskupeniVDeniku.GetCheckBoxState(0, radek, chbstate);
    while (asgSeskupeniVDeniku.Cells[1, radek] <> '') do begin

      asgSeskupeniVDeniku.SetCheckBoxState(0, radek, not chbstate);
      Inc(radek);
    end;




    //asgSeskupeniVDeniku.Cells[2, ARow] := asgSeskupeniVDeniku.Cells[0, ARow];
  end;

end;


procedure TfmSeskupeniVDeniku.asgSeskupeniVDenikuGetAlignment(Sender: TObject;
  ARow, ACol: Integer; var HAlign: TAlignment; var VAlign: TVAlignment);
begin
  case ACol of
    0: HAlign := taCenter  ;
    3,4,5..7: HAlign := taRightJustify;
  end;
end;

end.
