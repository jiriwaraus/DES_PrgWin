unit FOx_prevod;

interface

uses
  Windows, Classes, Forms, Controls, SysUtils, Variants, DateUtils, Registry, Printers, Dialogs, FOx_main;

type
  TdmPrevod = class(TDataModule)
  private
    procedure FOxPrevod(Radek: integer);
  public
    procedure PrevedFOx;
  end;

var
  dmPrevod: TdmPrevod;

implementation

{$R *.dfm}

uses FOx_common, frxExportSynPDF;

// ------------------------------------------------------------------------------------------------

procedure TdmPrevod.PrevedFOx;
var
  Radek: integer;
begin
  Screen.Cursor := crHourGlass;
  with fmMain do try
    dmCommon.Zprava('Pøevod do PDF');
    with asgMain do begin
      dmCommon.Zprava(Format('Poèet dokladù k pøevodu: %d', [Trunc(ColumnSum(0, 1, RowCount-1))]));
      Screen.Cursor := crHourGlass;
      apnPrevod.Visible := False;
      apbProgress.Position := 0;
      apbProgress.Visible := True;
// hlavní smyèka
      for Radek := 1 to RowCount-1 do begin
        Row := Radek;
        apbProgress.Position := Round(100 * Radek / RowCount-1);
        Application.ProcessMessages;
        if Prerusit then begin
          Prerusit := False;
          apbProgress.Position := 0;
          apbProgress.Visible := False;
          btVytvorit.Enabled := True;
          asgMain.Visible := True;
          lbxLog.Visible := False;
          Break;
        end;
        if Ints[0, Radek] = 1 then FOxPrevod(Radek);
      end;  // for
    end;  // with asgMain
// konec hlavní smyèky
  finally
    apbProgress.Position := 0;
    apbProgress.Visible := False;
    apnPrevod.Visible := True;
    asgMain.Visible := False;
    lbxLog.Visible := True;
    Screen.Cursor := crDefault;
    dmCommon.Zprava('Pøevod do PDF ukonèen');
  end;
end;

// ------------------------------------------------------------------------------------------------

procedure TdmPrevod.FOxPrevod(Radek: integer);
// podle zálohového listu v Abøe vytvoøí formuláø v PDF
var
  OutFileName,
  OutDir,
  AbraKod,
  SQLStr: AnsiString;
  i: integer;
  Zaplaceno: double;
  frxSynPDFExport: TfrxSynPDFExport;
begin
  with fmMain, asgMain do begin
    with qrAbra do begin
// údaje z FOx do globálních promìnných
      Close;
      SQLStr := 'SELECT F.Code, F.Name, Street, City, PostCode, OrgIdentNumber, VATIdentNumber, II.ID,'
       + ' D.Code || ''-'' || lpad(II.OrdNumber, 4, ''0'') || ''/'' || substring(P.Code from 3 for 2) AS Cislo,'
       + ' DocDate$DATE, DueDate$DATE, VATDate$DATE, LocalAmount, LocalPaidAmount'
      + ' FROM Firms F, Addresses A, IssuedInvoices II, DocQueues D, Periods P'
      + ' WHERE F.ID = II.Firm_ID'
      + ' AND A.ID = F.ResidenceAddress_ID'
      + ' AND D.ID = II.DocQueue_ID'
      + ' AND P.ID = II.Period_ID'
      + ' AND F.Hidden = ''N''' ;
      SQLStr := SQLStr + ' AND II.Period_ID = ' + Ap + Period_Id + Ap
      + ' AND II.OrdNumber = ' + Cells[2, Radek];
      if rbInternet.Checked then SQLStr := SQLStr + ' AND DocQueue_ID = ' + Ap + FO4Queue_Id + Ap
      else SQLStr := SQLStr + ' AND DocQueue_ID = ' + Ap + FO2Queue_Id + Ap;
      SQL.Text := SQLStr;
      Open;
      if RecordCount = 0 then begin
        dmCommon.Zprava(Format('Neexistuje doklad s èíslem %d nebo zákazník %s.', [Ints[2, Radek], Cells[4, Radek]]));
        Close;
        Exit;
      end;
      CisloFO := FieldByName('Cislo').AsString;
      if Trim(FieldByName('Code').AsString) = '' then begin
        dmCommon.Zprava(Format('Doklad %s: zákazník nemá kód Abry.', [CisloFO]));
        Close;
        Exit;
      end;
      AbraKod := FieldByName('Code').AsString;
      OJmeno := FieldByName('Name').AsString;
      OUlice := FieldByName('Street').AsString;
      OObec := FieldByName('PostCode').AsString + ' ' + FieldByName('City').AsString;
      OICO := FieldByName('OrgIdentNumber').AsString;
      ODIC := FieldByName('VATIdentNumber').AsString;
      FO_Id := FieldByName('ID').AsString;
      DatumDokladu := FieldByName('DocDate$DATE').AsFloat;
      DatumSplatnosti := FieldByName('DueDate$DATE').AsFloat;
      DatumPlneni := FieldByName('VATDate$DATE').AsFloat;
      Vystaveni := FormatDateTime('dd.mm.yyyy', DatumDokladu);
      Plneni := FormatDateTime('dd.mm.yyyy', DatumPlneni);
      Splatnost := FormatDateTime('dd.mm.yyyy', DatumSplatnosti);
      VS := Cells[1, Radek];
      Celkem := FieldByName('LocalAmount').AsFloat;
      Zaplaceno := FieldByName('LocalPaidAmount').AsFloat;
      Close;
//      Cislo := Format('FO4-%4.4d/%d', [Ints[2, Radek], YearOf(DatumDokladu)]);
// všechny Firm_Id pro Abrakód firmy
      SQLStr := 'SELECT * FROM DE$_Code_To_Firm_Id (' + Ap + AbraKod + ApZ;
      SQL.Text := SQLStr;
      Open;
      if Fields[0].AsString = 'MULTIPLE' then begin
        dmCommon.Zprava(Format('%s (%s): Více zákazníkù pro kód %s.', [OJmeno, VS, AbraKod]));
        Close;
        Exit;
      end;
      Saldo := 0;
// a saldo pro všechny Firm_Id (saldo je záporné, pokud zákazník dluží)
      while not EOF do with qrAdresa do begin
        Close;
        SQLStr := 'SELECT SaldoPo + SaldoZLPo + Ucet325 FROM DE$_Firm_Totals (' + Ap + qrAbra.Fields[0].AsString + ApC + FloatToStr(DatumDokladu) + ')';
        SQL.Text := SQLStr;
        Open;
        Saldo := Saldo + Fields[0].AsFloat;
        qrAbra.Next;
      end; // while not EOF do with qrAdresa
    end;  // with qrAbra
    Saldo := Saldo + Zaplaceno;          // Saldo je po splatnosti (SaldoPo), je-li faktura už zaplacena, pøiète se platba
    Zaplatit := Celkem - Saldo;          // Celkem k úhradì = Celkem za fakt. období - Zùstatek minulých období(saldo)
// text na fakturu
    if Saldo > 0 then Platek := 'pøeplatek'
    else if Saldo < 0 then Platek := 'nedoplatek'
    else Platek := ' ';
    if Zaplatit < 0 then Zaplatit := 0;
// údaje z tabulky Smlouvy do globálních promìnných
    with qrMain do begin
      Close;
// u FOx je VS èíslo smlouvy
      SQLStr := 'SELECT Postal_name, Postal_street, Postal_PSC, Postal_city FROM customers Cu, contracts C'
      + ' WHERE Cu.Id = C.Customer_Id'
      + ' AND C.Number = ' + Ap + VS + Ap;
      SQL.Text := SQLStr;
      Open;
      PJmeno := FieldByName('Postal_name').AsString;
      PUlice := FieldByName('Postal_street').AsString;
      PObec := FieldByName('Postal_PSC').AsString + ' ' + FieldByName('Postal_city').AsString;
      Close;
    end;  // with qrMain
// zasílací adresa
    if (PJmeno = '') or (PObec = '') then begin
      PJmeno := OJmeno;
      PUlice := OUlice;
      PObec := OObec;
    end;
// adresáø pro ukládání faktur v PDF nemusí existovat
    if not DirectoryExists(PDFDir) then CreateDir(PDFDir);           // PDFDir je v FI.ini
    OutDir := PDFDir + Format('\%4d', [aseRok.Value]);
    if not DirectoryExists(OutDir) then CreateDir(OutDir);
    OutDir := OutDir + Format('\%2.2d', [aseMesic.Value]);
    if not DirectoryExists(OutDir) then CreateDir(OutDir);
// jméno souboru s fakturou
//    OutFileName := OutDir + Copy(CisloFO, 1, 8) + '.pdf';            // bez roku
    OutFileName := Format('%s\%s.pdf', [OutDir, Copy(CisloFO, 1, 8)]);            // bez roku
// soubor už existuje
    if FileExists(OutFileName) then
      if cbNeprepisovat.Checked then begin
        dmCommon.Zprava(Format('%s (%s): Soubor %s už existuje.', [OJmeno, VS, OutFileName]));
        Exit;
      end else DeleteFile(OutFileName);
// vytvoøená faktura se zpracuje do vlastního formuláøe a pøevede se do PDF
      frxReport.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'FOxdoPDF.fr3');
      frxReport.PrepareReport;
//  frxReport.ShowPreparedReport;
// uložení
      frxSynPDFExport := TfrxSynPDFExport.Create(nil);
      with frxSynPDFExport do try
        FileName := OutFileName;
        Title := 'Daòový doklad za kredit';
        Author := 'Družstvo Eurosignal';
        EmbeddedFonts := False;
        Compressed := True;
        OpenAfterExport := False;
        ShowDialog := False;
        ShowProgress := False;
        PDFA := True; // important
        frxReport.Export(frxSynPDFExport);
      finally
        Free;
      end;
// èekání na soubor - max. 5s
    for i := 1 to 50 do begin
      if FileExists(OutFileName) then Break;
      Sleep(100);
    end;
// hotovo
    if not FileExists(OutFileName) then
      dmCommon.Zprava(Format('%s (%s): Nepodaøilo se vytvoøit soubor %s.', [OJmeno, VS, OutFileName]))
    else begin
      dmCommon.Zprava(Format('%s (%s): Vytvoøen soubor %s.', [OJmeno, VS, OutFileName]));
      Ints[0, Radek] := 0;
      Row := Radek;
    end;
  end;  // with fmMain
end;

end.

