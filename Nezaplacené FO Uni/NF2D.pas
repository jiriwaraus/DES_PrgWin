unit NF2D;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, Grids, BaseGrid, AdvGrid, AdvObj;

type
  TfmDetail = class(TForm)
    asgDetail: TAdvStringGrid;
    procedure FormShow(Sender: TObject);
    procedure asgDetailGetAlignment(Sender: TObject; ARow, ACol: Integer; var HAlign: TAlignment; var VAlign: TVAlignment);
  end;

var
  fmDetail: TfmDetail;

implementation

uses DesUtils, NF;

{$R *.dfm}

procedure TfmDetail.FormShow(Sender: TObject);
var
  SQLStr: string;
  R: integer;
begin
  with DesU.qrAbra, asgDetail do begin
    ClearNormalCells;
    SQLStr := 'SELECT II.DocDate$DATE AS Datum, DQ.Code AS Rada, II.OrdNumber AS Cislo, P.Code AS Rok, II.Description AS Text,'
// 12.5.12    + ' II.Amount AS Vystaveno, II.PaidAmount + II.CreditAmount AS Zaplaceno, ICN.Amount AS Dobropis'
    + ' II.LocalAmount - II.LocalCreditAmount AS Vystaveno, II.LocalPaidAmount - II.LocalPaidCreditAmount AS Zaplaceno, ICN.Amount AS Dobropis'
    + ' FROM IssuedInvoices II'
    + ' INNER JOIN DocQueues DQ ON II.DocQueue_ID = DQ.Id'               // øada dokladù
    + ' INNER JOIN Periods P ON II.Period_ID = P.Id'                     // rok
    + ' LEFT JOIN IssuedCreditNotes ICN ON II.ID = ICN.Source_ID'
//    + ' WHERE II.DocDate$DATE <= ' + IntToStr(Trunc(StrToDate(fmMain.deDatumDo.Text)))
//    + ' AND II.DocDate$DATE >= ' + IntToStr(Trunc(StrToDate(fmMain.deDatumOd.Text)))
    + ' WHERE II.Firm_ID IN (SELECT ID FROM Firms WHERE Code = ' + Ap + fmMain.asgPohledavky.Cells[1, fmMain.Radek] + ApZ
//    + ' AND II.Amount - II.PaidAmount - II.CreditAmount > 0'
    + ' AND II.LocalAmount - II.LocalCreditAmount - (II.LocalPaidAmount - II.LocalPaidCreditAmount) <> 0'
    + ' ORDER BY II.DocDate$DATE';
    Close;
    SQL.Text := SQLStr;
    Open;
    R := 0;
    while not EOF do begin
      Inc(R);
      RowCount := R + 1;
      FixedRows := 1;
      Cells[0, R] := FormatDateTime('dd.mm.yyyy', FieldByName('Datum').AsFloat);
      Cells[1, R] := FieldByName('Rada').AsString + '-' + FieldByName('Cislo').AsString
       + '/' + Copy(FieldByName('Rok').AsString, 3, 2);
      Floats[2, R] := FieldByName('Vystaveno').AsFloat;
      Floats[3, R] := FieldByName('Zaplaceno').AsFloat - FieldByName('Dobropis').AsFloat;
      Floats[4, R] := FieldByName('Dobropis').AsFloat;
      Cells[5, R] := FieldByName('Text').AsString;
      Next;
    end;
  end;
  with fmDetail do begin
    Caption := fmMain.asgPohledavky.Cells[0, fmMain.Radek];
    ClientHeight := asgDetail.RowCount * 19 + 4;
  end;
end;

procedure TfmDetail.asgDetailGetAlignment(Sender: TObject; ARow, ACol: Integer; var HAlign: TAlignment; var VAlign: TVAlignment);
begin
  if ARow = 0 then HAlign := taLeftJustify
  else if (ACol in [2..4]) then HAlign := taRightJustify;
end;

end.
