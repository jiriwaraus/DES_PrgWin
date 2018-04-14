unit FIprevod;

interface

uses
  Windows, Classes, Forms, Controls, SysUtils, Variants, DateUtils, Registry, Printers, Dialogs, FImain;

type
  Ch32 = array [0..31] of char;
  TdmPrevod = class(TDataModule)
  private
{$IFNDEF ABAK}
    PWDbuf: Ch32;
    JePrint2PDF: boolean;
{$ENDIF}
    procedure FakturaPrevod(Radek: integer);
  public
    procedure PrevedFaktury;
    procedure demoPrevod();
  end;

{$IFNDEF ABAK}
const
  PWD: Ch32 =
    (char($44), char($F5), char($B3), char($27), char($D5), char($4D), char($01), char($1F),
     char($42), char($78), char($5E), char($DB), char($5B), char($4D), char($31), char($09),
     char($C6), char($DE), char($DA), char($F9), char($BD), char($69), char($CC), char($5A),
     char($64), char($4F), char($F6), char($12), char($A8), char($F8), char($3F), char($55));
{$ENDIF}

var
  dmPrevod: TdmPrevod;

implementation

{$R *.dfm}

uses FIcommon, frxExportSynPDF;

// ------------------------------------------------------------------------------------------------

procedure TdmPrevod.PrevedFaktury;
var
  Radek,
  i: integer;
  Reg: TRegistry;
begin
  Screen.Cursor := crHourGlass;

  with fmMain do try

    if rbPodleSmlouvy.Checked then
      dmCommon.Zprava(Format('Pøevod faktur do PDF od VS %s do %s', [aedOd.Text, aedDo.Text]))
      else dmCommon.Zprava(Format('Pøevod faktur do PDF od èísla %s do %s', [aedOd.Text, aedDo.Text]));
    with asgMain do begin
      dmCommon.Zprava(Format('Poèet faktur k pøevodu: %d', [Trunc(ColumnSum(0, 1, RowCount-1))]));
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

        if Ints[0, Radek] = 1 then FakturaPrevod(Radek)  // pokud zaškrtnuto, pøevádíme fa do PDF

      end; // konec hlavní smyèky
    end;  // with asgMain

  finally
    Printer.PrinterIndex := -1;  // default
    apbProgress.Position := 0;
    apbProgress.Visible := False;
    apnPrevod.Visible := True;
    asgMain.Visible := False;
    lbxLog.Visible := True;
    Screen.Cursor := crDefault;
    dmCommon.Zprava('Pøevod faktur do PDF ukonèen');
  end;

end;

// ------------------------------------------------------------------------------------------------

procedure TdmPrevod.FakturaPrevod(Radek: integer);
// podle faktury v Abøe a stavu pohledávek vytvoøí formuláø v PDF
var
  FrfFileName,
  OutFileName,
  OutDir,
  AbraKod,
  SQLStr: AnsiString;
  Zaplaceno: double;
  i: integer;
  Reg: TRegistry;
  frxSynPDFExport: TfrxSynPDFExport;
begin
  with fmMain, fmMain.asgMain do begin
    with qrAbra do begin


      // údaje z faktury do globálních promìnných
      Close;
      SQLStr := 'SELECT Code, Name, Street, City, PostCode, OrgIdentNumber, VATIdentNumber, II.ID, II.IsReverseChargeDeclared,'
       + ' DocDate$DATE, DueDate$DATE, VATDate$DATE, LocalAmount, LocalPaidAmount'
      + ' FROM Firms F, Addresses A, IssuedInvoices II'
      + ' WHERE F.ID = II.Firm_ID'
      + ' AND A.ID = F.ResidenceAddress_ID'
      + ' AND F.Hidden = ''N''' ;
//      + ' AND F.Firm_ID IS NULL';                             // poslední, bez následovníka
      SQLStr := SQLStr + ' AND II.Period_ID = ' + Ap + Period_Id + Ap
      + ' AND II.OrdNumber = ' + Cells[2, Radek]
      + ' AND II.DocQueue_ID = ';


      SQL.Text := SQLStr + Ap + IDocQueue_Id + Ap;
      Open;

      if RecordCount = 0 then begin
        dmCommon.Zprava(Format('Neexistuje faktura %d nebo zákazník %s.', [Ints[2, Radek], Cells[4, Radek]]));
        Close;
        Exit;
      end;
      if Trim(FieldByName('Code').AsString) = '' then begin
        dmCommon.Zprava(Format('Faktura %d: zákazník nemá kód Abry.', [Ints[2, Radek]]));
        Close;
        Exit;
      end;
      AbraKod := FieldByName('Code').AsString;
      OJmeno := FieldByName('Name').AsString;
      OUlice := FieldByName('Street').AsString;
      OObec := FieldByName('PostCode').AsString + ' ' + FieldByName('City').AsString;
      OICO := FieldByName('OrgIdentNumber').AsString;
      ODIC := FieldByName('VATIdentNumber').AsString;
      ID := FieldByName('ID').AsString;
      DRC := FieldByName('IsReverseChargeDeclared').AsString = 'A';
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
      SS := Format('%6.6d%2.2d', [Ints[2, Radek], aseRok.Value - 2000]);
      Mesic := MonthOf(DatumDokladu);
      FStr := 'FO1';
      Cislo := Format('%s-%5.5d/%d', [FStr, Ints[2, Radek], aseRok.Value]);

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
        SQL.Text := 'SELECT SaldoPo + SaldoZLPo + Ucet325 FROM DE$_Firm_Totals (' + Ap + qrAbra.Fields[0].AsString + ApC + FloatToStr(DatumDokladu) + ')';
        Open;
        Saldo := Saldo + Fields[0].AsFloat;
        qrAbra.Next;
      end; // while not EOF do with qrAdresa
    end;  // with qrAbra

    // právì pøevádìná faktura mùže být pøed splatností
    //    if Date <= DatumSplatnosti then begin
    Saldo := Saldo + Zaplaceno;          // Saldo je po splatnosti (SaldoPo), je-li faktura už zaplacena, pøiète se platba
    Zaplatit := Celkem - Saldo;          // Celkem k úhradì = Celkem za fakt. období - Zùstatek minulých období(saldo)
    // anebo je po splatnosti
    {end else begin
      Zaplatit := -Saldo;
      Saldo := Saldo + Celkem;             // èástka faktury se odeète ze salda, aby tam nebyla dvakrát
    end;  }

    // text na fakturu
    if Saldo > 0 then Platek := 'pøeplatek'
    else if Saldo < 0 then Platek := 'nedoplatek'
    else Platek := ' ';
    if Zaplatit < 0 then Zaplatit := 0;

    // údaje z tabulky Smlouvy do globálních promìnných
    with qrMain do begin
      Close;
      SQLStr := 'SELECT Postal_name, Postal_street, Postal_PSC, Postal_city FROM customers'
      + ' WHERE Variable_symbol = ' + Ap + VS + Ap;
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
    OutDir := OutDir + Format('\%2.2d', [Mesic]);
    if not DirectoryExists(OutDir) then CreateDir(OutDir);

    // jméno souboru s fakturou
    OutFileName := OutDir + Format('\%s-%5.5d.pdf', [FStr, Ints[2, Radek]]);
    // soubor už existuje
    if FileExists(OutFileName) AND cbNeprepisovat.Checked then begin
        dmCommon.Zprava(Format('%s (%s): Soubor %s už existuje.', [Cells[4, Radek], Cells[1, Radek], OutFileName]));
        Exit;
      end else
        DeleteFile(OutFileName);

    // vytvoøená faktura se zpracuje do vlastního formuláøe a pøevede se do PDF
    // uložení pomocí Synopse
    frxReport.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'FOsPDP.fr3');

    frxReport.PrepareReport;
    //  frxReport.ShowPreparedReport;
    //  uložení
    //  frxPDFExport.FileName := OutFileName;
    //  frxReport.Export(frxPDFExport);

    frxSynPDFExport := TfrxSynPDFExport.Create(nil);
    with frxSynPDFExport do try
      FileName := OutFileName;
      Title := 'Faktura za pøipojení k internetu';

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


procedure TdmPrevod.demoPrevod();
// podle faktury v Abøe a stavu pohledávek vytvoøí formuláø v PDF
var
  FrfFileName,
  OutFileName,
  OutDir,
  AbraKod,
  SQLStr: AnsiString;
  Zaplaceno: double;
  Radek, i: integer;
  Reg: TRegistry;
  frxSynPDFExport: TfrxSynPDFExport;
begin
  Radek := 1;

  with fmMain, fmMain.asgMain do begin
    with qrAbra do begin

      AbraKod := 'ABRAKKK';
      OJmeno := 'Pepa';
      OUlice := 'Kratka';
      OObec := '55523 Kulickov';
      OICO := 'xxx';
      ODIC := 'xxx';
      ID := 'xxx';
      DRC := false;
      DatumDokladu := 43000;
      DatumSplatnosti := 43000;
      DatumPlneni := 43000;
      Vystaveni := FormatDateTime('dd.mm.yyyy', 43000);
      Plneni := FormatDateTime('dd.mm.yyyy', 43000);
      Splatnost := FormatDateTime('dd.mm.yyyy', 43000);
      VS := '123123123';
      Celkem := 998;
      Zaplaceno := 10;

      SS := '555';
      Mesic := MonthOf(DatumDokladu);
      FStr := 'FO1';
      Cislo := Format('%s-%5.5d/%d', ['yy', 5678, 2015]);



      Saldo := 0;

    end;  // with qrAbra


    Saldo := Saldo + Zaplaceno;          // Saldo je po splatnosti (SaldoPo), je-li faktura už zaplacena, pøiète se platba
    Zaplatit := Celkem - Saldo;          // Celkem k úhradì = Celkem za fakt. období - Zùstatek minulých období(saldo)


    // text na fakturu
    if Saldo > 0 then Platek := 'pøeplatek'
    else if Saldo < 0 then Platek := 'nedoplatek'
    else Platek := ' ';
    if Zaplatit < 0 then Zaplatit := 0;

    // údaje z tabulky Smlouvy do globálních promìnných

      PJmeno := 'PJmeno';
      PUlice := 'PUlice';
      PObec := 'PObec';


    // zasílací adresa
    if (PJmeno = '') or (PObec = '') then begin
      PJmeno := OJmeno;
      PUlice := OUlice;
      PObec := OObec;
    end;

    // adresáø pro ukládání faktur v PDF nemusí existovat
    if not DirectoryExists(PDFDir) then CreateDir(PDFDir);           // PDFDir je v FI.ini
    OutDir := PDFDir + Format('\%4d', [2017]);
    if not DirectoryExists(OutDir) then CreateDir(OutDir);
    OutDir := OutDir + Format('\%2.2d', [Mesic]);
    if not DirectoryExists(OutDir) then CreateDir(OutDir);

    // jméno souboru s fakturou
    OutFileName := OutDir + Format('\%s-%5.5d.pdf', ['yy', 5678]);
    // soubor už existuje
    if FileExists(OutFileName) then

        DeleteFile(OutFileName);
    // vytvoøená faktura se zpracuje do vlastního formuláøe a pøevede se do PDF

    if JePrint2PDF then begin        // uložení pomocí Print2PDF

    end else begin                                         // uložení pomocí Synopse
      frxReport.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'fr3\FOsPDP.fr3');

      frxReport.PrepareReport;
//  frxReport.ShowPreparedReport;
// uložení
//  frxPDFExport.FileName := OutFileName;
//  frxReport.Export(frxPDFExport);
      frxSynPDFExport := TfrxSynPDFExport.Create(nil);
      with frxSynPDFExport do try
        FileName := OutFileName;
        Title := 'Faktura za pøipojení k internetu';

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

    end;      // if JePrint2PDF else

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

