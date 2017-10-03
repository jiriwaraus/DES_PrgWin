unit PrirazeniPNP;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, IniFiles, Forms,
  Dialogs, StdCtrls, Grids, AdvObj, BaseGrid, AdvGrid, StrUtils,
  DB, ComObj, AdvEdit, DateUtils, Math, ExtCtrls,
  ZAbstractRODataset, ZAbstractDataset, ZDataset, ZAbstractConnection, ZConnection,
  VypisyMain;

type
  TfmPrirazeniPnp = class(TForm)
    asgPnp: TAdvStringGrid;
    btnNactiPnp: TButton;
    btnPriradPnp: TButton;
    MemoPNP: TMemo;
    btnNactiPnpAlt: TButton;
    chbNacistPnp: TCheckBox;
    procedure btnNactiPnpClick(Sender: TObject);
    procedure btnNactiPnpAltClick(Sender: TObject);

    procedure asgPnpGetCellColor(Sender: TObject; ARow, ACol: Integer;
      AState: TGridDrawState; ABrush: TBrush; AFont: TFont);
    procedure asgPnpGetAlignment(Sender: TObject; ARow, ACol: Integer;
      var HAlign: TAlignment; var VAlign: TVAlignment);
    procedure FormShow(Sender: TObject);
    procedure btnPriradPnpClick(Sender: TObject);
    procedure asgPnpClickCell(Sender: TObject; ARow, ACol: Integer);
    procedure asgPNPCanSort(Sender: TObject; ACol: Integer;
      var DoSort: Boolean);
  public
    procedure nactiPNPinfo;
    procedure nactiPNP;
    procedure priradPNP;
  end;

var
  fmPrirazeniPnp: TfmPrirazeniPnp;
  asgPnpAllRowsChecked: boolean;

implementation

{$R *.dfm}

uses
  DesUtils, Superobject;




procedure TfmPrirazeniPnp.nactiPNP;
var
  SQLStr: AnsiString;
  radek, sloupec: integer;
begin
// nalezení zákazníkù s pøeplatky na 325 z Abry

  SQLStr := 'SELECT ADQ.Code || ''-'' || G1.OrdNumber || ''/'' || P.Code AS DokladVypis, G1.Amount, F.Name, G1.Text,'
  + ' bs.ID as Vypis_ID, bs2.ID as RadekVypisu_ID, bs2.Parent_ID as Vypis_ID, bs2.Firm_ID, bs2.varsymbol as RadekVypisu_VS'
  + ' FROM GENERALLEDGER G1, BANKSTATEMENTS bs, BANKSTATEMENTS2 bs2,'
  + '   AccDocQueues ADQ, Periods P, Firms F'
  + ' WHERE G1.CreditAccount_ID = ''A300000101'''
  + ' AND NOT EXISTS (SELECT * FROM GENERALLEDGER G2 WHERE G2.AccGroup_ID = G1.AccGroup_ID AND G2.ID <> G1.ID)'
  + ' AND ADQ.Id = G1.AccDocQueue_ID'
  + ' AND P.Id = G1.Period_ID'
  + ' AND F.Id = G1.Firm_ID'

  + ' AND G1.AccDocQueue_ID = bs.AccDocQueue_ID'
  + ' AND G1.Period_ID = bs.Period_ID'
  + ' AND G1.ORDNUMBER = bs.ORDNUMBER'

  + ' AND bs2.PARENT_ID = bs.ID'
  + ' AND bs2.FIRM_ID = G1.FIRM_ID'
  + ' AND bs2.AMOUNT = G1.AMOUNT'
  + ' AND bs2.PDOCUMENT_ID IS NULL'
  + ' AND bs2.ISMULTIPAYMENTROW = ''N'''
  + ' AND bs2.Amount > 5'
  ;


  with DesU.qrAbra, asgPnp do begin
    Screen.Cursor := crHourGlass;
    ClearNormalCells;
    RowCount := 2;
    //CheckFalse := '0';
    //CheckTrue := '1';
    asgPnpAllRowsChecked := true;

    radek := 0;
    SQL.Text := SQLStr;
    Open;
    while not EOF do begin
      Inc(radek);
      RowCount := radek + 1;
      Cells[0, radek] := FieldByName('DokladVypis').AsString; //ucetni doklad
      Floats[1, radek] := FieldByName('Amount').AsFloat; // ne asCurrency, protože potøebuju teèku jako desetinný oddìlovaè
      Cells[2, radek] := FieldByName('Name').AsString;
      Cells[3, radek] := FieldByName('Text').AsString;
      Cells[4, radek] := FieldByName('RadekVypisu_ID').AsString;
      Cells[5, radek] := FieldByName('Firm_ID').AsString;
      Cells[16, radek] := FieldByName('Vypis_ID').AsString;
      Application.ProcessMessages;
      Next;
    end;
    Close;

    for radek := 1 to RowCount - 1 do begin
      SQLStr :=   'SELECT'
      + ' ii.ID as Doklad_ID, ii.DOCQUEUE_ID, ii.DOCDATE$DATE, ii.VARSYMBOL as Doklad_VS, ii.FIRM_ID, ii.DESCRIPTION,'
      + ' D.Code || ''-'' || II.OrdNumber || ''/'' || substring(P.Code from 3 for 2) as CisloDokladu, D.DOCUMENTTYPE,'
      + ' (ii.LOCALAMOUNT - ii.LOCALPAIDAMOUNT - ii.LOCALCREDITAMOUNT + ii.LOCALPAIDCREDITAMOUNT) as Dluh,'
      + ' (ii.LOCALPAIDAMOUNT - ii.LOCALPAIDCREDITAMOUNT) as Zaplaceno, ii.LOCALAMOUNT'
      + ' from ISSUEDINVOICES ii'

      + ' JOIN DocQueues D ON ii.DocQueue_ID = D.ID'
      + ' JOIN Periods P ON ii.Period_ID = P.ID'

      + ' WHERE ii.Firm_ID = ''' + Cells[5, Radek] + ''''
      + ' AND (ii.LOCALAMOUNT - ii.LOCALPAIDAMOUNT - ii.LOCALCREDITAMOUNT + ii.LOCALPAIDCREDITAMOUNT)*100 >= ';
      if not chbNacistPnp.Checked then
        SQLStr := SQLStr + FloatToStr(Floats[1, radek]*100) //dluh je vìtší èi roven pøeplatku
      else
        SQLStr := SQLStr + '0.01'; //dluh je vìtší èi roven pøeplatku
      SQLStr := SQLStr + ' ORDER BY dluh';

      SQL.Text := SQLStr;
      Open;
      if not EOF then begin

        Cells[6, radek] := FieldByName('CisloDokladu').AsString;
        Cells[7, radek] := FieldByName('Doklad_ID').AsString;
        Cells[8, Radek] := FieldByName('Doklad_VS').AsString;
        Cells[9, Radek] := DateToStr(FieldByName('DOCDATE$DATE').AsFloat);
        //Cells[7, Radek] := FieldByName('DocumentType').AsString;
        //AddButton(9,Radek,45,18,'zmìò d',haCenter,vaCenter);

        Cells[10, radek] := format('%m', [FieldByName('LocalAmount').AsCurrency]);
        Cells[11, radek] := format('%m', [FieldByName('Zaplaceno').AsCurrency]);
        Cells[12, radek] := format('%m', [FieldByName('Dluh').AsCurrency]);
        AddCheckBox(13, radek, True, True);


        for sloupec := 7 to 12 do asgPnp.Colors[sloupec, radek] := clCream;

        Application.ProcessMessages;
        Next;
      end;
    end;
    Close;
    Screen.Cursor := crDefault;

  end;
end;


procedure TfmPrirazeniPnp.priradPNP;
var
  SQLStr: AnsiString;
  radek: integer;
  chbstate: boolean;
begin

  with DesU.qrAbra, asgPnp do begin

    for radek := FixedRows to RowCount - 1 do begin
      GetCheckBoxState(13, radek, chbstate);
      if (Cells[6, radek] <> '') AND (chbstate) then
      begin
        Cells[13, radek] := '...';
        RemoveCheckBox(13, radek);
        try
          DesU.opravRadekVypisuPomociPDocument_ID(Cells[16, radek], Cells[4, radek], Cells[7, radek], '03'); //DocumentType je vždy 03 pro faktury
          Cells[13, radek] := 'ok';
        except
          on E: Exception do
          Cells[13, radek] := 'fail';
        end;
        Application.ProcessMessages;
      end;
    end;

    DesU.dbAbra.Reconnect;
    for radek := 1 to RowCount - 1 do begin
      SQLStr :=   'SELECT'
      + ' (ii.LOCALPAIDAMOUNT - ii.LOCALPAIDCREDITAMOUNT) as Zaplaceno,'
      + ' (ii.LOCALAMOUNT - ii.LOCALPAIDAMOUNT - ii.LOCALCREDITAMOUNT + ii.LOCALPAIDCREDITAMOUNT) as Dluh'
      + ' from ISSUEDINVOICES ii'
      + ' WHERE ii.ID = ''' + Cells[7, radek]  + ''''
      ;

      SQL.Text := SQLStr;
      Open;
      if not EOF then begin

        Cells[14, radek] := format('%m', [FieldByName('Zaplaceno').AsCurrency]);
        Cells[15, radek] := format('%m', [FieldByName('Dluh').AsCurrency]);

        Application.ProcessMessages;
        Next;
      end;
    end;
    Close;

  end;
end;

// alternativní data, vše na 1 SELECT ale neumí øešit pokud existuje více nezaplacených faktur pro zákazníka co má pøeplatek
procedure TfmPrirazeniPnp.nactiPNPinfo;
var
  SQLStr: AnsiString;
  Radek: integer;
begin
// nalezení zákazníkù s pøeplatky na 325 z Abry



  SQLStr := '  SELECT preplatkyVypis.*,'
  + ' ii.ID as Doklad_ID, ii.DOCQUEUE_ID, ii.DOCDATE$DATE, ii.VARSYMBOL as Doklad_VS, ii.FIRM_ID, ii.DESCRIPTION, D.DOCUMENTTYPE,'
  + ' D.Code || ''-'' || II.OrdNumber || ''/'' || substring(P.Code from 3 for 2) as CisloDokladu,'
  + ' (ii.LOCALAMOUNT - ii.LOCALPAIDAMOUNT - ii.LOCALCREDITAMOUNT + ii.LOCALPAIDCREDITAMOUNT) as dluh,'
  + ' ii.LOCALAMOUNT, ii.LOCALPAIDAMOUNT, ii.LOCALCREDITAMOUNT, ii.LOCALPAIDCREDITAMOUNT'
  + ' from'
  + ' (SELECT ADQ.Code || ''-'' || G1.OrdNumber || ''/'' || P.Code AS DokladVypis, G1.Amount, F.Name, G1.Text,'
  + ' bs.ID as Vypis_ID, bs2.ID as RadekVypisu_ID,  bs2.FIRM_ID, bs2.varsymbol as RadekVypisu_VS'
  + ' FROM GENERALLEDGER G1, BANKSTATEMENTS bs, BANKSTATEMENTS2 bs2,'
  + '   AccDocQueues ADQ, Periods P, Firms F'
  + ' WHERE G1.CreditAccount_ID = ''A300000101'''
  + ' AND NOT EXISTS (SELECT * FROM GENERALLEDGER G2 WHERE G2.AccGroup_ID = G1.AccGroup_ID AND G2.ID <> G1.ID)'
  + ' AND ADQ.Id = G1.AccDocQueue_ID'
  + ' AND P.Id = G1.Period_ID'
  + ' AND F.Id = G1.Firm_ID'

  + ' AND G1.AccDocQueue_ID = bs.AccDocQueue_ID'
  + ' AND G1.Period_ID = bs.Period_ID'
  + ' AND G1.ORDNUMBER = bs.ORDNUMBER'

  + ' AND bs2.PARENT_ID = bs.ID'
  + ' AND bs2.FIRM_ID = G1.FIRM_ID'
  + ' AND bs2.AMOUNT = G1.AMOUNT'
  + ' AND bs2.PDOCUMENT_ID IS NULL'
  + ' AND bs2.ISMULTIPAYMENTROW = ''N'''
  + ' AND bs2.Amount > 5) as preplatkyVypis'

  + ' JOIN ISSUEDINVOICES ii ON ii.Firm_ID = preplatkyVypis.Firm_ID'
  + ' JOIN DocQueues D ON ii.DocQueue_ID = D.ID'
  + ' JOIN Periods P ON ii.Period_ID = P.ID'

  + ' WHERE 0 < (ii.LOCALAMOUNT - ii.LOCALPAIDAMOUNT - ii.LOCALCREDITAMOUNT + ii.LOCALPAIDCREDITAMOUNT) ' // dluh vìtší než nula
  // + ' WHERE preplatkyVypis.amount <= (ii.LOCALAMOUNT - ii.LOCALPAIDAMOUNT - ii.LOCALCREDITAMOUNT + ii.LOCALPAIDCREDITAMOUNT) ' //èástka PNP je menší nebo rovna dluhu

  ;


  with DesU.qrAbra, asgPnp do begin
    ClearNormalCells;
    RowCount := 2;
    Radek := 0;
    SQL.Text := SQLStr;
    Open;
    while not EOF do begin
      //opravRadekVypisuPomociPDocument_ID(AbraOLE, FieldByName('RadekVypisu_ID').AsString, FieldByName('Doklad_ID').AsString);
      Inc(Radek);
      RowCount := Radek + 1;
      Cells[0, Radek] := FieldByName('DokladVypis').AsString; //ucetni doklad
      Cells[1, radek] := format('%m', [FieldByName('Amount').AsCurrency]);
      Cells[2, Radek] := FieldByName('Name').AsString;
      Cells[3, Radek] := FieldByName('Text').AsString;
      Cells[4, Radek] := FieldByName('RadekVypisu_ID').AsString;
      Cells[5, radek] := FieldByName('FIRM_ID').AsString;
      Cells[6, radek] := FieldByName('CisloDokladu').AsString;
      Cells[7, radek] := FieldByName('Doklad_ID').AsString;
      Cells[8, Radek] := FieldByName('Doklad_VS').AsString;
      //Cells[7, Radek] := FieldByName('DocumentType').AsString;
      Cells[9, Radek] := DateToStr(FieldByName('DOCDATE$DATE').AsFloat);
      Cells[10, radek] := format('%m', [FieldByName('LocalAmount').AsCurrency]);
      Cells[11, radek] := format('%m', [FieldByName('LocalPaidAmount').AsCurrency
                                - FieldByName('LocalPaidCreditAmount').AsCurrency]);
      Cells[12, radek] := format('%m', [FieldByName('Dluh').AsCurrency]);


      //AddButton(12,Radek,45,18,'zmìò VS',haCenter,vaCenter);
      Application.ProcessMessages;
      Next;
    end;
  end;
end;


{*********************** akce Input elementù **********************************}

procedure TfmPrirazeniPnp.btnNactiPnpClick(Sender: TObject);
begin
  nactiPNP;
end;

procedure TfmPrirazeniPnp.btnNactiPnpAltClick(Sender: TObject);
begin
  nactiPNPinfo;
end;

procedure TfmPrirazeniPnp.btnPriradPnpClick(Sender: TObject);
begin
  priradPNP;
end;


procedure TfmPrirazeniPnp.asgPnpGetCellColor(Sender: TObject; ARow,
  ACol: Integer; AState: TGridDrawState; ABrush: TBrush; AFont: TFont);
begin
  if (ARow > 0) then begin
    case ACol of
      1,12: AFont.Style := [fsBold];
    end;
    case ACol of
      1: AFont.Color := clBlue;
    end;
    case ACol of
      12: AFont.Color := clFuchsia;
    end;
    case ACol of
      7..8:// asgPnp.Colors[ACol, ARow] := clCream;
    end;
  end;
end;

procedure TfmPrirazeniPnp.asgPNPCanSort(Sender: TObject; ACol: Integer;
  var DoSort: Boolean);
begin
  DoSort := ACol <> 13;
end;

procedure TfmPrirazeniPnp.asgPnpClickCell(Sender: TObject; ARow, ACol: Integer);
var
  radek: integer;
begin
  asgPnpAllRowsChecked := not asgPnpAllRowsChecked;
  if (ARow = 0) and (ACol = 13) then
    for radek := 1 to asgPnp.RowCount-1 do
      asgPnp.SetCheckBoxState(ACol, radek, asgPnpAllRowsChecked);
end;

procedure TfmPrirazeniPnp.asgPnpGetAlignment(Sender: TObject; ARow,
  ACol: Integer; var HAlign: TAlignment; var VAlign: TVAlignment);
begin
  case ACol of
    0,1,6,9..12: HAlign := taRightJustify;
  end;
end;

procedure TfmPrirazeniPnp.FormShow(Sender: TObject);
begin
  if DesU.appMode >= 3 then
    btnNactiPnpAlt.Visible := true;

  nactiPNP;
end;


end.
