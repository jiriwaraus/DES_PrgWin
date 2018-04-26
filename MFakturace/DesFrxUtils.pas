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
    qrAbraDPH: TZQuery;
    qrAbraRadky: TZQuery;
    frxReport: TfrxReport;
    fdsDPH: TfrxDBDataset;
    fdsRadky: TfrxDBDataset;
    QRCode: TBarcode2D_QRCode;

    procedure frxReportGetValue(const ParName: string; var ParValue: Variant);
    procedure frxReportBeginDoc(Sender: TObject);


  public
    //pdfFileName, fr3FileName : string;
    reportData: TAArray;

    function fakturaVytvorPfd(pdfFileName, fr3FileName : string; reportData: TAArray) : string;
    function fakturaTisk(fr3FileName : string; reportData: TAArray) : string;
    function faktura(action, fr3FileName : string; reportData: TAArray) : string;

    function vytvorPdf(fr3FileName : string; reportData: TAArray) : string;
    function tisk(fr3FileName : string; reportData: TAArray) : string;

  end;

var
  DesFrxU: TDesFrxU;

implementation

uses DesUtils, AbraEntities, frxExportSynPDF;

{$R *.dfm}

function TDesFrxU.fakturaVytvorPfd(pdfFileName, fr3FileName : string; reportData: TAArray) : string;
begin
  reportData['pdfFileName'] := pdfFileName;
  faktura('vytvoreniPdf', fr3FileName, reportData);
end;

function TDesFrxU.fakturaTisk(fr3FileName : string; reportData: TAArray) : string;
begin
  faktura('tisk', fr3FileName, reportData);
end;

function TDesFrxU.faktura(action, fr3FileName : string; reportData: TAArray) : string;
var
  ASymbolWidth,
  ASymbolHeight,
  AWidth,
  AHeight: integer;
begin
  self.reportData := reportData;

  // øádky faktury
  with qrAbraRadky do begin
    Close;
    SQL.Text := 'SELECT Text, TAmountWithoutVAT AS BezDane, VATRate AS Sazba, TAmount - TAmountWithoutVAT AS DPH, TAmount AS SDani FROM IssuedInvoices2'
    + ' WHERE Parent_ID = ' + Ap + reportData['ID'] + Ap                                       // ID faktury
    + ' AND NOT (Text = ''Zaokrouhlení'' AND TAmount = 0)'
    + ' ORDER BY PosIndex';
    Open;
  end;

  // rekapitulace
  with qrAbraDPH do begin
    Close;
    SQL.Text := 'SELECT VATRate AS Sazba, SUM(TAmountWithoutVAT) AS BezDane, SUM(TAmount - TAmountWithoutVAT) AS DPH, SUM(TAmount) AS SDani FROM IssuedInvoices2'
    + ' WHERE Parent_ID = ' + Ap + reportData['ID'] + Ap
    + ' AND VATIndex_ID IS NOT NULL'
    + ' GROUP BY Sazba';
    Open;
  end;

  if action = 'vytvoreniPdf' then begin
    tisk(fr3FileName, reportData);
  end;

  if action = 'tisk' then begin
    tisk(fr3FileName, reportData);
  end;

  qrAbraRadky.Close;
  qrAbraDPH.Close;
end;

function TDesFrxU.vytvorPdf(fr3FileName : string; reportData: TAArray) : string;
var
    frxSynPDFExport: TfrxSynPDFExport;
begin
  frxReport.LoadFromFile(DesU.PROGRAM_PATH + fr3FileName);
  frxReport.PrepareReport;

  // vytvoøená faktura se zpracuje do vlastního formuláøe a pøevede se do PDF
  // uložení pomocí Synopse
  frxSynPDFExport := TfrxSynPDFExport.Create(nil);
  with frxSynPDFExport do try
    FileName := reportData['pdfFileName'];
    Title := reportData['Title'];
    Author := reportData['Author'];
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
end;

function TDesFrxU.tisk(fr3FileName : string; reportData: TAArray) : string;
begin
  frxReport.LoadFromFile(DesU.PROGRAM_PATH + fr3FileName);
  frxReport.PrepareReport;
  frxReport.PrintOptions.ShowDialog := true;
  frxReport.Print;
end;


// ------------------------------------------------------------------------------------------------

procedure TDesFrxU.frxReportGetValue(const ParName: string; var ParValue: Variant);
// dosadí se promìné do formuláøe
begin

if ParName = 'Value = 0' then Exit; //pro jistotu, ve fr3 souboru toto bylo v highlight.condition

  try
    ParValue := self.reportData[ParName];
  except
    ShowMessage('Lehlo to na ' + ParName); //nefunguje mi
    //on E: Exception do
    //  ShowMessage(ParName + ' Chyba frxReportGetValue: '#13#10 + e.Message);
  end;  

end;

procedure TDesFrxU.frxReportBeginDoc(Sender: TObject);
var
  ASymbolWidth,
  ASymbolHeight,
  AWidth,
  AHeight: integer;
begin

  // QR kód
  // nejdøíve ovìøení, že je reportData['sQrKodem'] typu boolean
  if varIsType(reportData['sQrKodem'], varBoolean) AND reportData['sQrKodem'] then begin
    QRCode.Barcode := Format('SPD*1.0*ACC:CZ6020100000002100098382*AM:%d*CC:CZK*DT:%s*X-VS:%s*X-SS:%s*MSG:QR PLATBA EUROSIGNAL',
     [Round(reportData['ZaplatitCislo']), FormatDateTime('yyyymmdd', reportData['DatumSplatnosti']), reportData['VS'], reportData['SS']]);
    QRCode.DrawToSize(AWidth, AHeight, ASymbolWidth, ASymbolHeight);
    with TfrxPictureView(frxReport.FindObject('pQR')).Picture.Bitmap do begin
      Width := AWidth;
      Height := AHeight;
      QRCode.DrawTo(Canvas, 0, 0);
    end;
  end;  
  
end;


end.
