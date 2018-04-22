unit DesFrxUtils;

interface

uses
  Winapi.Windows, Winapi.ShellApi, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.RegularExpressions,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  StrUtils,  // IOUtils, IniFiles, ComObj, //, Grids, AdvObj, StdCtrls,
  Data.DB, ZAbstractRODataset, ZAbstractDataset, ZDataset,
  ZAbstractConnection, ZConnection, AArray,

  frxClass, frxDBSet, frxDesgn, pCore2D, pBarcode2D, pQRCode;



type
  TDesFrxU = class(TForm)
    dbAbra: TZConnection;
    qrAbra: TZQuery;
    qrAdresa: TZQuery;
    qrAbraDPH: TZQuery;
    qrAbraRadky: TZQuery;
    frxReport: TfrxReport;
    fdsDPH: TfrxDBDataset;
    fdsRadky: TfrxDBDataset;
    QRCode: TBarcode2D_QRCode;


    procedure FormCreate(Sender: TObject);

    procedure frxReportGetValue(const ParName: string; var ParValue: Variant);


  public
    PdfDir: string;
    reportData: TAArray;

    F: TextFile;
    DRC,
    Check,
    Prerusit: boolean;
    Mesic,
    VATRate: integer;
    DatumDokladu,
    DatumPlneni,
    DatumSplatnosti,
    Celkem,
    Saldo,
    Zaplatit: double;
    AbraOLE: variant;
    C, V, S,                           // pole èísel na složenku
    ID,
    User_Id,
    Firm_Id,
    Period_Id: ShortString;
        // prefix faktury

    Cislo,
    VS,
    SS,
    PJmeno,
    PUlice,
    PObec,
    OJmeno,
    OUlice,
    OObec,
    OICO,
    ODIC,
    Vystaveni,
    Plneni,
    Splatnost,
    Platek: AnsiString;

    function vytvorPfdFaktura(pdfFileName, fr3FileName : string; reportData: TAArray) : string;

  private
    IDocQueue_Id,
    VATIndex_Id,
    VATRate_Id,
    DRCVATIndex_Id,
    DRCArticle_Id,

    VDocQueue_Id: string[10];


  end;

var
  DesFrxU: TDesFrxU;

implementation

uses DesUtils, AbraEntities, frxExportSynPDF;

{$R *.dfm}

procedure TDesFrxU.FormCreate(Sender: TObject);
{
var
    abraVatIndex : TAbraVatIndex;
    abraDrcArticle : TAbraDrcArticle;
    }
begin

  dbAbra.HostName := DesU.getIniValue('Preferences', 'AbraHN');
  dbAbra.Database := DesU.getIniValue('Preferences', 'AbraDB');
  dbAbra.User := DesU.getIniValue('Preferences', 'AbraUN');
  dbAbra.Password := DesU.getIniValue('Preferences', 'AbraPW');

  // pøipojení databáze
  if not dbAbra.Connected then try
    dbAbra.Connect;
  except on E: exception do
    begin
      Application.MessageBox(PChar('DesFrxUtils - nedá se pøipojit k databázi Abry.' + ^M + E.Message), 'Abra', MB_ICONERROR + MB_OK);
      Application.Terminate;
      DesFrxU.Close;
    end;
  end;

end;

function TDesFrxU.vytvorPfdFaktura(pdfFileName, fr3FileName : string; reportData: TAArray) : string;
var
  ASymbolWidth,
  ASymbolHeight,
  AWidth,
  AHeight: integer;
  frxSynPDFExport: TfrxSynPDFExport;
begin
  self.reportData := reportData;

  // øádky faktury
  with qrAbraRadky do begin
    Close;
    SQL.Text := 'SELECT Text, TAmountWithoutVAT AS BezDane, VATRate AS Sazba, TAmount - TAmountWithoutVAT AS DPH, TAmount AS SDani FROM IssuedInvoices2'
    + ' WHERE Parent_ID = ' + Ap + ID + Ap                                       // ID faktury
    + ' AND NOT (Text = ''Zaokrouhlení'' AND TAmount = 0)'
    + ' ORDER BY PosIndex';
    Open;
  end;

  // rekapitulace
  with qrAbraDPH do begin
    Close;
    SQL.Text := 'SELECT VATRate AS Sazba, SUM(TAmountWithoutVAT) AS BezDane, SUM(TAmount - TAmountWithoutVAT) AS DPH, SUM(TAmount) AS SDani FROM IssuedInvoices2'
    + ' WHERE Parent_ID = ' + Ap + ID + Ap
    + ' AND VATIndex_ID IS NOT NULL'
    + ' GROUP BY Sazba';
    Open;
  end;


  // QR kód

  if reportData['sQrKodem'] then begin

    QRCode.Barcode := Format('SPD*1.0*ACC:CZ6020100000002100098382*AM:%d*CC:CZK*DT:%s*X-VS:%s*X-SS:%s*MSG:QR PLATBA EUROSIGNAL',
     [Round(Zaplatit), FormatDateTime('yyyymmdd', DatumSplatnosti), VS, SS]);

    QRCode.DrawToSize(AWidth, AHeight, ASymbolWidth, ASymbolHeight);
    with TfrxPictureView(frxReport.FindObject('pQR')).Picture.Bitmap do begin
      Width := AWidth;
      Height := AHeight;
      QRCode.DrawTo(Canvas, 0, 0);
    end;
  end;

  // vytvoøená faktura se zpracuje do vlastního formuláøe a pøevede se do PDF
  // uložení pomocí Synopse
  frxReport.LoadFromFile(DesU.PROGRAM_PATH + fr3FileName);

  frxReport.PrepareReport;
  //  frxReport.ShowPreparedReport;
  //  uložení
  //  frxPDFExport.FileName := OutFileName;
  //  frxReport.Export(frxPDFExport);

  frxSynPDFExport := TfrxSynPDFExport.Create(nil);
  with frxSynPDFExport do try
    FileName := pdfFileName;
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


  qrAbraRadky.Close;
  qrAbraDPH.Close;

end;


// ------------------------------------------------------------------------------------------------

procedure TDesFrxU.frxReportGetValue(const ParName: string; var ParValue: Variant);
// dosadí se promìné do formuláøe
begin

{
  if ParName = 'Cislo' then ParValue := Cislo
  else if ParName = 'VS' then ParValue := VS
  else if ParName = 'SS' then ParValue := Trim(SS)
  else if ParName = 'PJmeno' then ParValue := PJmeno
  else if ParName = 'PUlice' then ParValue := PUlice
  else if ParName = 'PObec' then ParValue := PObec
  else if ParName = 'OJmeno' then ParValue := OJmeno
  else if ParName = 'OUlice' then ParValue := OUlice
  else if ParName = 'OObec' then ParValue := OObec
  else if ParName = 'OICO' then begin
    if Trim(OICO) <> '' then ParValue := 'IÈ: ' + OICO else ParValue := ' '
  end else if ParName = 'ODIC' then begin
    if Trim(ODIC) <> '' then ParValue := 'DIÈ: ' + ODIC else ParValue := ' '
  end else if ParName = 'Vystaveni' then ParValue := Vystaveni
  else if ParName = 'Plneni' then ParValue := Plneni
  else if ParName = 'Splatnost' then ParValue := Splatnost
  else if ParName = 'Platek' then ParValue := Platek
  else if ParName = 'Celkem' then ParValue := Celkem
  else if ParName = 'Saldo' then ParValue := Saldo
  else if ParName = 'Zaplatit' then ParValue := Format('%.2f Kè', [Zaplatit])

  else if ParName = 'Resume' then ParValue := Format('Èástku %.0f,- Kè uhraïte, prosím, do %s na úèet 2100098382/2010 s variabilním symbolem %s.',
   [Zaplatit, Splatnost, VS])
  else if ParName = 'DRCText' then
    if DRC then ParValue := 'Podle §92a zákona è. 235/2004 Sb. o DPH daò odvede zákazník.  ' else ParValue := ' ';

  //if FakturyU.rbSeSlozenkou.Checked then begin
  if TRUE then begin //*HW* TODO
    if ParName = 'C1' then ParValue := C[1]
    else if ParName = 'C2' then ParValue := C[2]
    else if ParName = 'C3' then ParValue := C[3]
    else if ParName = 'C4' then ParValue := C[4]
    else if ParName = 'C5' then ParValue := C[5]
    else if ParName = 'C6' then ParValue := C[6]
    else if ParName = 'V01' then ParValue := V[1]
    else if ParName = 'V02' then ParValue := V[2]
    else if ParName = 'V03' then ParValue := V[3]
    else if ParName = 'V04' then ParValue := V[4]
    else if ParName = 'V05' then ParValue := V[5]
    else if ParName = 'V06' then ParValue := V[6]
    else if ParName = 'V07' then ParValue := V[7]
    else if ParName = 'V08' then ParValue := V[8]
    else if ParName = 'V09' then ParValue := V[9]
    else if ParName = 'V10' then ParValue := V[10]
    else if ParName = 'S01' then ParValue := S[1]
    else if ParName = 'S02' then ParValue := S[2]
    else if ParName = 'S03' then ParValue := S[3]
    else if ParName = 'S04' then ParValue := S[4]
    else if ParName = 'S05' then ParValue := S[5]
    else if ParName = 'S06' then ParValue := S[6]
    else if ParName = 'S07' then ParValue := S[7]
    else if ParName = 'S08' then ParValue := S[8]
    else if ParName = 'S09' then ParValue := S[9]
    else if ParName = 'S10' then ParValue := S[10]
    else if ParName = 'VS2' then ParValue := VS
    else if ParName = 'SS2' then ParValue := SS
    else if ParName = 'Castka' then ParValue := C + ',-';
  end;

}

end;





end.
