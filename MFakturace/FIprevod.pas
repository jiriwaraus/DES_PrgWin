unit FIprevod;

interface

uses
  Windows, Classes, Forms, Controls, SysUtils, Variants, DateUtils, Registry, Printers, Dialogs;

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

uses DesUtils, DesFrxUtils, AArray, FImain, FIcommon,  frxExportSynPDF;

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
  slozenkaCastka,
  slozenkaVS,
  slozenkaSS,
  FrfFileName,
  OutFileName,
  OutDir,
  AbraKod,
  SQLStr: string;
  Celkem,
  Saldo,
  Zaplatit,
  Zaplaceno: double;
  Mesic, i: integer;
  Reg: TRegistry;
  frxSynPDFExport: TfrxSynPDFExport;
  reportData: TAArray;

begin
  reportData := TAArray.Create;
  reportData['Title'] := 'Faktura za pøipojení k internetu';
  reportData['Author'] := 'Družstvo Eurosignal';


  with fmMain, fmMain.asgMain do begin
    with DesU.qrAbra do begin

      // údaje z faktury do globálních promìnných
      Close;
      SQLStr := 'SELECT Code, Name, Street, City, PostCode, OrgIdentNumber, VATIdentNumber, II.ID, II.IsReverseChargeDeclared,'
       + ' DocDate$DATE, DueDate$DATE, VATDate$DATE, LocalAmount, LocalPaidAmount'
      + ' FROM Firms F, Addresses A, IssuedInvoices II'
      + ' WHERE F.ID = II.Firm_ID'
      + ' AND A.ID = F.ResidenceAddress_ID'
      + ' AND F.Hidden = ''N''' ;
//      + ' AND F.Firm_ID IS NULL';                             // poslední, bez následovníka
      SQLStr := SQLStr + ' AND II.Period_ID = ' + Ap + globalAA['abraIiPeriod_Id'] + Ap
      + ' AND II.OrdNumber = ' + Cells[2, Radek]
      + ' AND II.DocQueue_ID = ';


      SQL.Text := SQLStr + Ap + globalAA['abraIiDocQueue_Id'] + Ap;
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

      reportData['AbraKod'] := FieldByName('Code').AsString;
      reportData['OJmeno'] := FieldByName('Name').AsString;
      reportData['OUlice'] := FieldByName('Street').AsString;
      reportData['OObec'] := FieldByName('PostCode').AsString + ' ' + FieldByName('City').AsString;
      reportData['OICO'] := FieldByName('OrgIdentNumber').AsString;
      reportData['ODIC'] := FieldByName('VATIdentNumber').AsString;
      reportData['ID'] := FieldByName('ID').AsString;
      reportData['DatumDokladu'] := FieldByName('DocDate$DATE').AsFloat;
      reportData['DatumPlneni'] := FieldByName('VATDate$DATE').AsFloat;
      reportData['DatumSplatnosti'] := FieldByName('DueDate$DATE').AsFloat;
      reportData['VS'] := Cells[1, Radek];
      reportData['Celkem'] := FieldByName('LocalAmount').AsFloat;
      reportData['Zaplaceno'] := FieldByName('LocalPaidAmount').AsFloat;
      if FieldByName('IsReverseChargeDeclared').AsString = 'A' then
        reportData['DRCText'] := 'Podle §92a zákona è. 235/2004 Sb. o DPH daò odvede zákazník.  '
      else
        reportData['DRCText'] := ' ';



      Close;



      // všechny Firm_Id pro Abrakód firmy
      SQLStr := 'SELECT * FROM DE$_Code_To_Firm_Id (' + Ap + reportData['AbraKod'] + ApZ;
      SQL.Text := SQLStr;
      Open;
      if Fields[0].AsString = 'MULTIPLE' then begin
        dmCommon.Zprava(Format('%s (%s): Více zákazníkù pro kód %s.', [reportData['OJmeno'], reportData['VS'], reportData['AbraKod']]));
        Close;
        Exit;
      end;

      Saldo := 0;
      // a saldo pro všechny Firm_Id (saldo je záporné, pokud zákazník dluží)
      while not EOF do with DesU.qrAbra2 do begin
        Close;
        SQL.Text := 'SELECT SaldoPo + SaldoZLPo + Ucet325 FROM DE$_Firm_Totals (' + Ap + DesU.qrAbra.Fields[0].AsString + ApC + FloatToStr(reportData['DatumDokladu']) + ')';
        Open;
        Saldo := Saldo + Fields[0].AsFloat;
        DesU.qrAbra.Next;
      end; // while not EOF do with DesU.qrAbra2
    end;  // with DesU.qrAbra

    // právì pøevádìná faktura mùže být pøed splatností
    //    if Date <= DatumSplatnosti then begin
    Saldo := Saldo + reportData['Zaplaceno'];          // Saldo je po splatnosti (SaldoPo), je-li faktura už zaplacena, pøiète se platba
    Zaplatit := reportData['Celkem'] - Saldo;          // Celkem k úhradì = Celkem za fakt. období - Zùstatek minulých období(saldo)
    // anebo je po splatnosti
    {end else begin
      Zaplatit := -Saldo;
      Saldo := Saldo + Celkem;             // èástka faktury se odeète ze salda, aby tam nebyla dvakrát
    end;  }

    if Zaplatit < 0 then Zaplatit := 0;

    reportData['Saldo'] :=  Saldo;
    reportData['ZaplatitCislo'] := Zaplatit;
    reportData['Zaplatit'] := Format('%.2f Kè', [Zaplatit]);

    // text na fakturu
    if Saldo > 0 then reportData['Platek'] := 'pøeplatek'
    else if Saldo < 0 then reportData['Platek'] := 'nedoplatek'
    else reportData['Platek'] := ' ';

    reportData['Vystaveni'] := FormatDateTime('dd.mm.yyyy', reportData['DatumDokladu']);
    reportData['Plneni'] := FormatDateTime('dd.mm.yyyy', reportData['DatumPlneni']);
    reportData['Splatnost'] := FormatDateTime('dd.mm.yyyy', reportData['DatumSplatnosti']);

    reportData['SS'] := Format('%6.6d%2.2d', [Ints[2, Radek], aseRok.Value - 2000]);
    Mesic := MonthOf(reportData['DatumDokladu']);
    FStr := 'FO1';
    reportData['Cislo'] := Format('%s-%5.5d/%d', [FStr, Ints[2, Radek], aseRok.Value]);

    reportData['Resume'] := Format('Èástku %.0f,- Kè uhraïte, prosím, do %s na úèet 2100098382/2010 s variabilním symbolem %s.',
                                    [Zaplatit, reportData['Splatnost'], reportData['VS']]);

    // údaje z tabulky Smlouvy do globálních promìnných
    with DesU.qrZakos do begin
      Close;
      SQLStr := 'SELECT Postal_name, Postal_street, Postal_PSC, Postal_city FROM customers'
      + ' WHERE Variable_symbol = ' + Ap + VS + Ap;
      SQL.Text := SQLStr;
      Open;
      reportData['PJmeno'] := FieldByName('Postal_name').AsString;
      reportData['PUlice'] := FieldByName('Postal_street').AsString;
      reportData['PObec'] := FieldByName('Postal_PSC').AsString + ' ' + FieldByName('Postal_city').AsString;
      Close;
    end;  // with DesU.qrZakos

    // zasílací adresa
    if (PJmeno = '') or (PObec = '') then begin
      reportData['PJmeno'] := reportData['OJmeno'];
      reportData['PUlice'] := reportData['OUlice'];
      reportData['PObec'] := reportData['OObec'];
    end;

    //reportData['sQrKodem'] := true;


    slozenkaCastka := Format('%6.0f', [Zaplatit]);
    //nahradíme vlnovkou poslední mezeru, tedy dáme vlnovku pøed první èíslici
    for i := 2 to 6 do
      if slozenkaCastka[i] <> ' ' then begin
        slozenkaCastka[i-1] := '~';
        Break;
      end;

    //pro starší osmimístná èísla smluv se pøidají dvì nuly na zaèátek
    if Length(reportData['VS']) = 8 then
      slozenkaVS := '00' + reportData['VS']
    else
      slozenkaVS := reportData['VS'];


    slozenkaSS := Format('%8.8d%2.2d', [Ints[2, Radek], aseRok.Value - 2000]);

    reportData['C1'] := slozenkaCastka[1];
    reportData['C2'] := slozenkaCastka[2];
    reportData['C3'] := slozenkaCastka[3];
    reportData['C4'] := slozenkaCastka[4];
    reportData['C5'] := slozenkaCastka[5];
    reportData['C6'] := slozenkaCastka[6];
    reportData['V01'] := slozenkaVS[1];
    reportData['V02'] := slozenkaVS[2];
    reportData['V03'] := slozenkaVS[3];
    reportData['V04'] := slozenkaVS[4];
    reportData['V05'] := slozenkaVS[5];
    reportData['V06'] := slozenkaVS[6];
    reportData['V07'] := slozenkaVS[7];
    reportData['V08'] := slozenkaVS[8];
    reportData['V09'] := slozenkaVS[9];
    reportData['V10'] := slozenkaVS[10];
    reportData['S01'] := slozenkaSS[1];
    reportData['S02'] := slozenkaSS[2];
    reportData['S03'] := slozenkaSS[3];
    reportData['S04'] := slozenkaSS[4];
    reportData['S05'] := slozenkaSS[5];
    reportData['S06'] := slozenkaSS[6];
    reportData['S07'] := slozenkaSS[7];
    reportData['S08'] := slozenkaSS[8];
    reportData['S09'] := slozenkaSS[9];
    reportData['S10'] := slozenkaSS[10];

    reportData['VS2'] := reportData['VS']; //*hw* TODO je toto dobøe? nestaèil by jeden VS?
    reportData['SS2'] := slozenkaSS; // SS2 se liší od SS tak, že má 8 míst. SS má 6 míst (zleva jsou vždy pøidané nuly)

    reportData['Castka'] := slozenkaCastka + ',-';


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

    // !!! zde zavolání vytvoøení PDF
    //DesFrxU.vytvorPfdFaktura(OutFileName, 'FOsPDP.fr3', reportData);
    DesFrxU.vytvorPfdFaktura(OutFileName, 'FOseSlozenkou.fr3', reportData);





    // èekání na soubor - max. 5s
    for i := 1 to 50 do begin
      if FileExists(OutFileName) then Break;
      Sleep(100);
    end;

    // hotovo
    if not FileExists(OutFileName) then
      dmCommon.Zprava(Format('%s (%s): Nepodaøilo se vytvoøit soubor %s.', [reportData['OJmeno'], reportData['VS'], OutFileName]))
    else begin
      dmCommon.Zprava(Format('%s (%s): Vytvoøen soubor %s.', [reportData['OJmeno'], reportData['VS'], OutFileName]));
      Ints[0, Radek] := 0;
      Row := Radek;
    end;
  end;  // with fmMain
end;


end.

