// 2.10.2014 program pro mìsíèní fakturaci sjednocený pro DES i ABAK. Základem jse dosavadní program MesicniFakturace.
// Verze pro ABAK má v Project/Options/Conditionals nastaveno ABAK
// Základní rozdíly mezi obìma verzemi:
// - DES fakturuje najednou všechny smlouvy zákazníka, internet, VoIP i IPTV s datem vystavení i plnìní poslední den v mìsíci.
//  Faktury pøevedené do PDF jsou elektronicky podepsané
// - ABAK fakturuje každou smlouvu zvláš, internetové smlouvy na zaèátku mìsíce (zálohovì), VoIPové ka konci. Datum vystavení
//  je aktuální datum, datum plnìní u internetových smluv aktuální datum, u VoIPových poslední den fakturovaného mìsíce
// 20.11. pro export do PDF/A (bez Print2PDF) použita Synopse
// 4.12. ABAK - VoIPové smlouvy jednoho zákazníka se fakturují spoleènì
// 19.10.2016 Faktury s pøenesenou daòovou povinností pro smlouvy s tagem DRC
// 23.1.2017 výkazy pro ÈTÚ vyžadují dìlení podle technologie a rychlosti - do Abry bylo pøidáno 36 zakázek a ve faktuøe bude jedna
// z nich pøiøazena každému øádku

unit FImain;

interface

uses
  Windows, Messages, Dialogs, SysUtils, Variants, Classes, Graphics, Controls, StdCtrls, ExtCtrls, Forms, Mask, ComObj, ComCtrls,
  AdvObj, AdvPanel, AdvEdit, AdvSpin, AdvDateTimePicker, AdvEdBtn, AdvFileNameEdit, AdvProgressBar, GradientLabel,
  Grids, BaseGrid, AdvGrid, pCore2D, pBarcode2D, pQRCode, IniFiles, DateUtils, Math,
  DB, ZAbstractConnection, ZConnection, ZAbstractRODataset, ZAbstractDataset, ZDataset,

  frxClass, frxDBSet, frxDesgn;

type
  TfmMain = class(TForm)
    dbMain: TZConnection;
    qrMain: TZQuery;
    qrSmlouva: TZQuery;
    dbVoIP: TZConnection;
    qrVoIP: TZQuery;
    dbAbra: TZConnection;
    qrAbra: TZQuery;
    qrAdresa: TZQuery;
    qrDPH: TZQuery;
    qrRadky: TZQuery;
    frxReport: TfrxReport;
    frxDesigner: TfrxDesigner;
    fdsDPH: TfrxDBDataset;
    fdsRadky: TfrxDBDataset;
    QRCode: TBarcode2D_QRCode;
    apnVyberCinnosti: TAdvPanel;
    rbFakturace: TRadioButton;
    rbPrevod: TRadioButton;
    rbTisk: TRadioButton;
    rbMail: TRadioButton;
    glbFakturace: TGradientLabel;
    glbPrevod: TGradientLabel;
    glbTisk: TGradientLabel;
    glbMail: TGradientLabel;
    apnTop: TAdvPanel;
    apbProgress: TAdvProgressBar;
    apnMain: TAdvPanel;
    aseMesic: TAdvSpinEdit;
    aseRok: TAdvSpinEdit;
    lbFakturyZa: TLabel;
    cbBezVoIP: TCheckBox;
    cbSVoIP: TCheckBox;
    apnFakturyZa: TAdvPanel;
    rbInternet: TRadioButton;
    rbVoIP: TRadioButton;
    deDatumDokladu: TAdvDateTimePicker;
    deDatumPlneni: TAdvDateTimePicker;
    aedSplatnost: TAdvEdit;
    aedOd: TAdvEdit;
    aedDo: TAdvEdit;
    btVytvorit: TButton;
    btKonec: TButton;
    apnPrevod: TAdvPanel;
    cbNeprepisovat: TCheckBox;
    btOdeslat: TButton;
    btSablona: TButton;
    apnTisk: TAdvPanel;
    rbBezSlozenky: TRadioButton;
    rbSeSlozenkou: TRadioButton;
    rbKuryr: TRadioButton;
    apnMail: TAdvPanel;
    fePriloha: TAdvFileNameEdit;
    lbxLog: TListBox;
    asgMain: TAdvStringGrid;
    apnVyberPodle: TAdvPanel;
    lbVyber: TLabel;
    rbPodleFaktury: TRadioButton;
    rbPodleSmlouvy: TRadioButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure dbMainAfterConnect(Sender: TObject);
    procedure dbAbraAfterConnect(Sender: TObject);
    procedure dbVoIPAfterConnect(Sender: TObject);
    procedure glbFakturaceClick(Sender: TObject);
    procedure glbPrevodClick(Sender: TObject);
    procedure glbTiskClick(Sender: TObject);
    procedure glbMailClick(Sender: TObject);
    procedure aseMesicChange(Sender: TObject);
    procedure aseRokChange(Sender: TObject);
    procedure aedOdChange(Sender: TObject);
    procedure aedDoChange(Sender: TObject);
    procedure aedOdKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure aedOdExit(Sender: TObject);
    procedure aedDoKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure aedDoExit(Sender: TObject);
    procedure cbSVoIPClick(Sender: TObject);
    procedure cbBezVoIPClick(Sender: TObject);
    procedure rbInternetClick(Sender: TObject);
    procedure rbVoIPClick(Sender: TObject);
    procedure rbBezSlozenkyClick(Sender: TObject);
    procedure rbSeSlozenkouClick(Sender: TObject);
    procedure rbKuryrClick(Sender: TObject);
    procedure asgMainCanEditCell(Sender: TObject; ARow, ACol: Integer; var CanEdit: Boolean);
    procedure asgMainClickCell(Sender: TObject; ARow, ACol: Integer);
    procedure asgMainCanSort(Sender: TObject; ACol: Integer; var DoSort: Boolean);
    procedure asgMainGetAlignment(Sender: TObject; ARow, ACol: Integer; var HAlign: TAlignment; var VAlign: TVAlignment);
    procedure asgMainDblClick(Sender: TObject);
    procedure lbxLogDblClick(Sender: TObject);
    procedure frxReportBeginDoc(Sender: TObject);
    procedure frxReportEndDoc(Sender: TObject);
    procedure frxReportGetValue(const ParName: string; var ParValue: Variant);
    procedure btVytvoritClick(Sender: TObject);
    procedure btOdeslatClick(Sender: TObject);
    procedure btSablonaClick(Sender: TObject);
    procedure btKonecClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure rbPodleSmlouvyClick(Sender: TObject);
    procedure rbPodleFakturyClick(Sender: TObject);
    procedure rbFakturaceClick(Sender: TObject);
    procedure rbPrevodClick(Sender: TObject);
    procedure rbTiskClick(Sender: TObject);
    procedure rbMailClick(Sender: TObject);
  public
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
    Period_Id,
    IDocQueue_Id,
    VDocQueue_Id,
    DRCArticle_Id,
    DRCVATIndex_Id,
    VATRate_Id,
    VATIndex_Id: string[10];
    FStr,                              // prefix faktury
    PDFDir,
    VoIP_customers,
    BBmax,
    BillingView,
    InvoiceView: ShortString;
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
  end;

var
  fmMain: TfmMain;

implementation

uses DesUtils, FICommon, FIfaktura, FIPrevod, FITisk, FIMail;

{$R *.dfm}

procedure TfmMain.FormCreate(Sender: TObject);
begin
  Prerusit := False;
end;

procedure TfmMain.FormShow(Sender: TObject);
// inicializace, získání pøipojovacích informací pro databáze, pøipojení
var
  FileHandle: integer;
  FIIni: TIniFile;
  LogDir,
  LogFileName,
  FIFileName: AnsiString;

begin
  // jména pro viewjsou unikátní, aby program nebyl omezen na jednu instanci
  VoIP_customers := FormatDateTime('VoIPyymmddhhnnss', Now);
  BBmax := FormatDateTime('BByymmddhhnnss', Now);
  BillingView := FormatDateTime('BVyymmddhhnnss', Now);
  InvoiceView := FormatDateTime('IVyymmddhhnnss', Now);


  //FIFileName := ExtractFilePath(ParamStr(0)) + 'FIDES.ini';

  //adresáø pro logy
  LogDir := DesU.PROGRAM_PATH + '\logy\Mìsíèní fakturace\';
  if not DirectoryExists(LogDir) then Forcedirectories(LogDir);

// vytvoøení logfile, pokud neexistuje - 5.11. do jména pøidáno datum - 9.4.15 jen rok a mìsíc
// 2.1.  LogFileName := ExtractFilePath(ParamStr(0)) + FormatDateTime('"Fakturace "dd.mm.yyyy".log"', Date);
// 8.4.  LogFileName := LogDir + FormatDateTime('\yyyy.mm.dd".log"', Date);
  LogFileName := LogDir + FormatDateTime('yyyy.mm".log"', Date);
  if not FileExists(LogFileName) then begin
    FileHandle := FileCreate(LogFileName);
    FileClose(FileHandle);
  end;
  AssignFile(F, LogFileName);
  Append(F);
  Writeln(F);
  CloseFile(F);
  dmCommon.Zprava('Start programu "Mìsíèní fakturace".');

  {
  if FileExists(FIFileName) then begin                     // existuje FI.ini ?
    FIIni := TIniFile.Create(FIFileName);

// pøihlašovací údaje z FI.ini
    with FIIni do try
      dbAbra.HostName := ReadString('Preferences', 'AbraHN', '');
      dbAbra.Database := ReadString('Preferences', 'AbraDB', '');
      dbAbra.User := ReadString('Preferences', 'AbraUN', '');
      dbAbra.Password := ReadString('Preferences', 'AbraPW', '');
      dbMain.HostName := ReadString('Preferences', 'ZakHN', '');
      dbMain.Database := ReadString('Preferences', 'ZakDB', '');
      dbMain.User := ReadString('Preferences', 'ZakUN', '');
      dbMain.Password := ReadString('Preferences', 'ZakPW', '');
      dbVoIP.HostName := ReadString('Preferences', 'VoIPHN', '');
      dbVoIP.Database := ReadString('Preferences', 'VoIPDB', '');
      dbVoIP.User := ReadString('Preferences', 'VoIPUN', '');
      dbVoIP.Password := ReadString('Preferences', 'VoIPPW', '');
      dmMail.idSMTP.Host := ReadString('Mail', 'SMTPServer', 'mail.eurosignal.cz');
      dmMail.idSMTP.Username := ReadString('Mail', 'SMTPLogin', '');
      dmMail.idSMTP.Password := ReadString('Mail', 'SMTPPW', '');
      AbraConnection := ReadString('Preferences', 'AbraConn', '');
      PDFDir := ReadString('Preferences', 'PDFDir', '');
      Check := ReadBool('Preferences', 'Check', False);
    finally
      FIIni.Free;
    end;
  end else begin
    Application.MessageBox(PAnsiChar(Format('Neexistuje soubor %s, program ukonèen.', [FIFileName])), PAnsiChar(FIFileName),
     MB_ICONERROR + MB_OK);
    dmCommon.Zprava(Format('Neexistuje soubor %s, program ukonèen.', [FIFileName]));
    Application.Terminate;
    fmMain.Close;
    Exit;
  end;
  }

  dbAbra.HostName := DesU.getIniValue('Preferences', 'AbraHN');
  dbAbra.Database := DesU.getIniValue('Preferences', 'AbraDB');
  dbAbra.User := DesU.getIniValue('Preferences', 'AbraUN');
  dbAbra.Password := DesU.getIniValue('Preferences', 'AbraPW');

  dbVoIP.HostName := DesU.getIniValue('Preferences', 'VoIPHN');
  dbVoIP.Database := DesU.getIniValue('Preferences', 'VoIPDB');
  dbVoIP.User := DesU.getIniValue('Preferences', 'VoIPUN');
  dbVoIP.Password := DesU.getIniValue('Preferences', 'VoIPPW');

  PDFDir := DesU.getIniValue('Preferences', 'PDFDir');
  //Check := ReadBool('Preferences', 'Check', False);
  Check := false; //TODO k èemu to je? už není potøeba


  Prerusit := True; // pøíznak startu
  // fajfky v asgMain
  asgMain.CheckFalse := '0';
  asgMain.CheckTrue := '1';

// do 25. se oèekává fakturace za minulý mìsíc, pak už za aktuální
  if DayOf(Date)> 25 then aseMesic.Value := MonthOf(Date) else aseMesic.Value := MonthOf(IncMonth(Date, -1));
  if DayOf(Date)> 25 then aseRok.Value := YearOf(Date) else aseRok.Value := YearOf(IncMonth(Date, -1));
  apnFakturyZa.Visible := False;

end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.FormActivate(Sender: TObject);
// aby bylo vidìt, že se nìco dìje, pøipojují se databáze až tady, kdy už je vidìt fmMain, protože OnActivate nastane i pøi pøepnutí
// z jiného okna, kontrolují se existující pøipojení
begin
  if not Prerusit then Exit;             // to by mìlo ohlídat volání jen pøi startu
// pøipojení databází
  if not dbAbra.Connected then try
    dmCommon.Zprava('Pøipojení databáze Abry ...');
    dbAbra.Connect;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Nedá se pøipojit k databázi Abry, program ukonèen.' + ^M + E.Message), 'Abra', MB_ICONERROR + MB_OK);
      dmCommon.Zprava('Nedá se pøipojit k databázi Abry, program ukonèen. ' + #13#10 + 'Chyba: ' + E.Message);
      Application.Terminate;
      fmMain.Close;
    end;
  end;
  if not dbMain.Connected then try
    dmCommon.Zprava('Pøipojení databáze smluv ...');
    dbMain.Connect;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Nedá se pøipojit k databázi smluv, program ukonèen.' + ^M + E.Message), 'Abra', MB_ICONERROR + MB_OK);
      dmCommon.Zprava('Nedá se pøipojit k databázi smluv, program ukonèen. ' + #13#10 + 'Chyba: ' + E.Message);
      Application.Terminate;
      fmMain.Close;
    end;
  end;

  if not dbVoIP.Connected and cbSVoIP.Enabled then try

    dmCommon.Zprava('Pøipojení databáze VoIP ...');
    dbVoIP.Connect;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Nedá se pøipojit k databázi VoIP.' + ^M + E.Message), 'Abra', MB_ICONERROR + MB_OK);
      dmCommon.Zprava('Nedá se pøipojit k databázi VoIP. ' + #13#10 + 'Chyba: ' + E.Message);

      cbSVoIP.Checked := False;
      cbSVoIP.Enabled := False;

    end;
  end;  // try .. except
  Prerusit := False;
  aseRokChange(nil);
  rbFakturaceClick(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.dbMainAfterConnect(Sender: TObject);
begin
  with qrMain do begin                 // MySQL databáze zákazníkù
// pøeklad z UTF-8
    SQL.Text := 'SET CHARACTER SET cp1250';
    ExecSQL;
  end;
  dmCommon.Zprava('OK');
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.dbAbraAfterConnect(Sender: TObject);
begin
  with qrAbra do begin
    Close;

// Id øady dokladù FO1
    SQL.Text := 'SELECT Id FROM DocQueues WHERE Code = ''FO1'' AND DocumentType = ''03''';

    Open;
    IDocQueue_Id := FieldByName('Id').AsString;
    Close;
// Id DPH
    SQL.Text := 'SELECT Id, VATRate_Id, Tariff FROM VATIndexes WHERE Code = ''Výst21''';
    Open;
    VATIndex_Id := FieldByName('Id').AsString;
    VATRate_Id := FieldByName('VATRate_Id').AsString;
    VATRate := FieldByName('Tariff').AsInteger;
    Close;
    SQL.Text := 'SELECT Id FROM VATIndexes WHERE Code = ''VýstR21''';
    Open;
    DRCVATIndex_Id := FieldByName('Id').AsString;
    Close;
// DRC
    SQL.Text := 'SELECT Id FROM DRCArticles WHERE Code = ''21''';
    Open;
    DRCArticle_Id := FieldByName('Id').AsString;
    Close;
  end;
  dmCommon.Zprava('OK');
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.dbVoIPAfterConnect(Sender: TObject);
begin
  dmCommon.Zprava('OK');
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.rbFakturaceClick(Sender: TObject);
begin
  asgMain.Cells[0, 0] := 'fa';
  asgMain.ColWidths[6] := 0;
  glbFakturace.Color := clWhite;
  glbFakturace.ColorTo := clMenu;
  glbPrevod.Color := clSilver;
  glbPrevod.ColorTo := clGray;
  apnPrevod.Visible := False;
  glbTisk.Color := clSilver;
  glbTisk.ColorTo := clGray;
  apnTisk.Visible := False;
  glbMail.Color := clSilver;
  glbMail.ColorTo := clGray;
  apnMail.Visible := False;
  rbPodleSmlouvy.Checked := True;
  rbPodleFaktury.Enabled := False;
  apnVyberPodle.Visible := False;
  apbProgress.Visible := False;
  lbxLog.Visible := True;
  aseRokChange(Self);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.rbPrevodClick(Sender: TObject);
begin
  asgMain.Cells[0, 0] := 'PDF';
  asgMain.ColWidths[6] := 0;
  glbPrevod.Color := clWhite;
  glbPrevod.ColorTo := clMenu;
  apnPrevod.Visible := True;
  glbTisk.Color := clSilver;
  glbTisk.ColorTo := clGray;
  apnTisk.Visible := False;
  glbMail.Color := clSilver;
  glbMail.ColorTo := clGray;
  apnMail.Visible := False;
  glbFakturace.Color := clSilver;
  glbFakturace.ColorTo := clGray;
  rbPodleFaktury.Enabled := True;
  rbPodleFaktury.Checked := True;
  apnVyberPodle.Visible := True;
  aseRokChange(Self);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.rbTiskClick(Sender: TObject);
begin
  asgMain.Cells[0, 0] := 'tisk';
  asgMain.ColWidths[6] := 60;
  glbTisk.Color := clWhite;
  glbTisk.ColorTo := clMenu;
  apnTisk.Visible := True;
  glbMail.Color := clSilver;
  glbMail.ColorTo := clGray;
  apnMail.Visible := False;
  glbFakturace.Color := clSilver;
  glbFakturace.ColorTo := clGray;
  glbPrevod.Color := clSilver;
  glbPrevod.ColorTo := clGray;
  apnPrevod.Visible := False;
  rbPodleFaktury.Enabled := True;
  rbPodleFaktury.Checked := True;
  apnVyberPodle.Visible := True;
  aseRokChange(Self);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.rbMailClick(Sender: TObject);
begin
  asgMain.Cells[0, 0] := 'mail';
  asgMain.ColWidths[6] := 60;
  glbMail.Color := clWhite;
  glbMail.ColorTo := clMenu;
  apnMail.Visible := True;
  glbFakturace.Color := clSilver;
  glbFakturace.ColorTo := clGray;
  glbPrevod.Color := clSilver;
  glbPrevod.ColorTo := clGray;
  apnPrevod.Visible := False;
  glbTisk.Color := clSilver;
  glbTisk.ColorTo := clGray;
  apnTisk.Visible := False;
  rbPodleFaktury.Enabled := True;
  rbPodleFaktury.Checked := True;
  apnVyberPodle.Visible := True;
  aseRokChange(Self);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.glbFakturaceClick(Sender: TObject);
begin
  rbFakturace.Checked := True;
  rbFakturaceClick(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.glbPrevodClick(Sender: TObject);
begin
  rbPrevod.Checked := True;
  rbPrevodClick(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.glbTiskClick(Sender: TObject);
begin
  rbTisk.Checked := True;
  rbTiskClick(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.glbMailClick(Sender: TObject);
begin
  rbMail.Checked := True;
  rbMailClick(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.aseMesicChange(Sender: TObject);
begin
  if (aseMesic.Value = 0) then begin
    aseMesic.Value := 12;
    aseRok.Value := aseRok.Value - 1;
  end;
  if (aseMesic.Value = 13) then begin
    aseMesic.Value := 1;
    aseRok.Value := aseRok.Value + 1;
  end;
  aseRokChange(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.aseRokChange(Sender: TObject);
// pøi zmìnì (nejen) roku nastaví nové deDatumDokladu, deDatumPlneni, aedSplatnost, aedOd a aedDo
begin
  if not dbMain.Connected or not dbAbra.Connected then Exit;
  aedOd.Clear;
  aedDo.Clear;
  asgMain.ClearNormalCells;
  asgMain.RowCount := 2;
  btVytvorit.Caption := '&Naèíst';
  asgMain.Visible := True;
  lbxLog.Visible := False;
// Id období
  with qrAbra do begin
    Close;
    SQL.Text := 'SELECT Id FROM Periods WHERE Code = ' + Ap + aseRok.Text + Ap;
    Open;
    Period_Id := FieldByName('Id').AsString;
    Close;
  end;  // with qrAbra

// datum fakturace i datum plnìní je poslední den v mìsíci
  deDatumDokladu.Date := EndOfAMonth(aseRok.Value, aseMesic.Value);
  deDatumPlneni.Date := deDatumDokladu.Date;
  aedSplatnost.Text := '10';

// *** výbìr podle smlouvy
  if rbPodleSmlouvy.Checked then with qrMain do try
    Screen.Cursor := crSQLWait;
// view pro fakturaci
    dmCommon.AktualizaceView;
// první a poslední èíslo smlouvy

    SQL.Text := 'SELECT MIN(VS), MAX(VS) FROM InvoiceView';

    Open;
    aedOd.Text := Fields[0].AsString;
    aedDo.Text := Fields[1].AsString;
    Close;
  finally
    Screen.Cursor := crDefault;
  end;  // if rbPodleSmlouvy.Checked
// *** výbìr podle faktury
  if rbPodleFaktury.Checked then begin
    dbAbra.Reconnect;
    with qrAbra do begin
// rozpìtí èísel FO1 v mìsíci
      SQL.Text := 'SELECT MIN(OrdNumber), MAX(OrdNumber) FROM IssuedInvoices'
      + ' WHERE VATDate$DATE >= ' + FloatToStr(Trunc(StartOfAMonth(aseRok.Value, aseMesic.Value)))
      + ' AND VATDate$DATE <= ' + FloatToStr(Trunc(EndOfAMonth(aseRok.Value, aseMesic.Value)))
      + ' AND DocQueue_ID = ' + Ap + IDocQueue_Id + Ap;

      Open;
      if RecordCount > 0 then begin
        aedOd.Text := Fields[0].AsString;
        aedDo.Text := Fields[1].AsString;
        Close;
      end else begin
        aedOd.Clear;
        aedDo.Clear;
      end;
    end;  // with qrAbra
  end;  // if rbPodleFaktury.Checked
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.aedOdChange(Sender: TObject);
begin
  if btVytvorit.Caption <> '&Naèíst' then begin
    asgMain.ClearNormalCells;
    asgMain.RowCount := 2;
    btVytvorit.Caption := '&Naèíst';
  end;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.aedOdKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
// enter po zadání aedOd vyplní stejným èíslem aedDo
begin
  if Key = 13 then begin
    aedDo.Text := aedOd.Text;
    aedDo.SetFocus;
  end;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.aedOdExit(Sender: TObject);
// je-li aedOd vìtší než aedDo, opraví se
begin
//  if aedOd.IntValue > aedDo.IntValue then aedDo.Text := aedOd.Text;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.aedDoChange(Sender: TObject);
begin
  aedOdChange(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.aedDoKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
// enter po zadání aedDo spustí pøevod
begin
  if Key = 13 then btVytvorit.SetFocus;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.aedDoExit(Sender: TObject);
// je-li aedOd menší než aedDo, opraví se
begin
//  if aedDo.IntValue < aedOd.IntValue then aedOd.Text := aedDo.Text;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.rbInternetClick(Sender: TObject);
// ABAK
begin
  aseRokChange(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.rbVoIPClick(Sender: TObject);
begin
  aseRokChange(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.cbBezVoIPClick(Sender: TObject);
// DES - musí být nìco vybráno
begin
  if not (cbBezVoIP.Checked or cbSVoIP.Checked) then cbSVoIP.Checked := True;
  aseRokChange(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.cbSVoIPClick(Sender: TObject);
begin
  if not (cbBezVoIP.Checked or cbSVoIP.Checked) then cbBezVoIP.Checked := True;
  aseRokChange(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.rbPodleSmlouvyClick(Sender: TObject);
begin
  aseRokChange(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.rbPodleFakturyClick(Sender: TObject);
begin
  aseRokChange(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.rbBezSlozenkyClick(Sender: TObject);
begin
  aedOdChange(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.rbSeSlozenkouClick(Sender: TObject);
begin
  aedOdChange(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.rbKuryrClick(Sender: TObject);
begin
  aedOdChange(nil);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.asgMainDblClick(Sender: TObject);
begin
  asgMain.Visible := False;
  lbxLog.Visible := True;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.asgMainCanEditCell(Sender: TObject; ARow, ACol: Integer; var CanEdit: Boolean);
begin
  CanEdit := (ARow > 0) and (ACol in [0, 5]);   // fajfky nebo email
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.asgMainClickCell(Sender: TObject; ARow, ACol: Integer);
// klik v prvním øádku podle sloupce buï oznaèuje/odznaèuje všchny checkboxy, nebo spouští tøídìní,
var
  Radek: integer;
begin
  with asgMain do if (ARow = 0) and (ACol in [0..1]) then
    if Ints[ACol, 1] = 1 then for Radek := 1 to RowCount-1 do Ints[ACol, Radek] := 0
    else if Ints[ACol, 1] = 0 then for Radek := 1 to RowCount-1 do Ints[ACol, Radek] := 1;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.asgMainCanSort(Sender: TObject; ACol: Integer; var DoSort: Boolean);
// klik v prvním øádku podle sloupce buï oznaèuje/odznaèuje všchny checkboxy, nebo spouští tøídìní,
begin
  DoSort := ACol > 0;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.asgMainGetAlignment(Sender: TObject; ARow, ACol: Integer; var HAlign: TAlignment; var VAlign: TVAlignment);
begin
  HAlign := taLeftJustify;
  if (ACol = 0) or (ARow = 0) then HAlign := Classes.taCenter
  else if (ACol in [1..3]) and (ARow > 0) then HAlign := taRightJustify;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.lbxLogDblClick(Sender: TObject);
begin
  asgMain.Visible := True;
  lbxLog.Visible := False;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.frxReportBeginDoc(Sender: TObject);
var
  SQLStr: AnsiString;
  ASymbolWidth,
  ASymbolHeight,
  AWidth,
  AHeight: Integer;
begin
// øádky faktury
  with qrRadky do begin
    Close;
    SQLStr := 'SELECT Text, TAmountWithoutVAT AS BezDane, VATRate AS Sazba, TAmount - TAmountWithoutVAT AS DPH, TAmount AS SDani FROM IssuedInvoices2'
    + ' WHERE Parent_ID = ' + Ap + ID + Ap                                       // ID faktury
    + ' AND NOT (Text = ''Zaokrouhlení'' AND TAmount = 0)'
    + ' ORDER BY PosIndex';
    SQL.Text := SQLStr;
    Open;
  end;
// rekapitulace
  with qrDPH do begin
    Close;
    SQLStr := 'SELECT VATRate AS Sazba, SUM(TAmountWithoutVAT) AS BezDane, SUM(TAmount - TAmountWithoutVAT) AS DPH, SUM(TAmount) AS SDani FROM IssuedInvoices2'
    + ' WHERE Parent_ID = ' + Ap + ID + Ap
    + ' AND VATIndex_ID IS NOT NULL'
    + ' GROUP BY Sazba';
    SQL.Text := SQLStr;
    Open;
  end;
// QR kód
  if not rbSeSlozenkou.Checked then begin

    QRCode.Barcode := Format('SPD*1.0*ACC:CZ6020100000002100098382*AM:%d*CC:CZK*DT:%s*X-VS:%s*X-SS:%s*MSG:QR PLATBA EUROSIGNAL',
     [Round(Zaplatit), FormatDateTime('yyyymmdd', DatumSplatnosti), VS, SS]);

    QRCode.DrawToSize(AWidth, AHeight, ASymbolWidth, ASymbolHeight);
    with TfrxPictureView(frxReport.FindObject('pQR')).Picture.Bitmap do begin
      Width := AWidth;
      Height := AHeight;
      QRCode.DrawTo(Canvas, 0, 0);
    end;
  end;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.frxReportGetValue(const ParName: string; var ParValue: Variant);
// dosadí se promìné do formuláøe
begin
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
  if fmMain.rbSeSlozenkou.Checked then begin
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
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.frxReportEndDoc(Sender: TObject);
begin
  qrRadky.Close;
  qrDPH.Close;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.btVytvoritClick(Sender: TObject);
// pro zadaný mìsíc se vytvoøí faktury v Abøe, nebo pøevedou do PDF, vytisknou èi rozešlou mailem
begin
  btVytvorit.Enabled := False;
  btKonec.Caption := '&Pøerušit';
  Prerusit := False;
  Application.ProcessMessages;
  try
// *** Naplnìní asgMain ***
    if btVytvorit.Caption = '&Naèíst' then dmCommon.Plneni_asgMain
    else begin
// *** Fakturace ***
      if rbFakturace.Checked then dmFaktura.VytvorFaktury;
// *** Pøevod do PDF ***
      if rbPrevod.Checked then dmPrevod.PrevedFaktury;
// *** Tisk ***
      if rbTisk.Checked then dmTisk.TiskniFaktury;
// *** Posílání mailem ***
      if rbMail.Checked then dmMail.PosliFaktury;
    end;
  finally
    btKonec.Caption := '&Konec';
    btVytvorit.Enabled := True;
  end;
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.btSablonaClick(Sender: TObject);
begin
  frxReport.DesignReport(True, False);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.btOdeslatClick(Sender: TObject);
// odeslání faktur pøevedených do PDF na vzdálený server
begin
  WinExec(PChar(Format('WinSCP.com /command "option batch abort" "option confirm off" "open AbraPDF" "synchronize remote '
   + '%s\%4d\%2.2d /home/abrapdf/%4d" "exit"', [PDFDir, aseRok.Value, aseMesic.Value, aseRok.Value])), SW_SHOWNORMAL);
end;

// ------------------------------------------------------------------------------------------------

procedure TfmMain.btKonecClick(Sender: TObject);
begin
  if btKonec.Caption = '&Pøerušit' then begin
    Prerusit := True;
    dmCommon.Zprava('Pøerušeno uživatelem.');
    btKonec.Caption := '&Konec';
  end else begin
    dmCommon.Zprava('Konec programu "Mìsíèní fakturace".');
    Close;
  end;
end;

procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  with qrMain do try
    SQL.Text := 'DROP VIEW ' + VoIP_customers;
    ExecSQL;
    SQL.Text := 'DROP VIEW ' + InvoiceView;
    ExecSQL;
    SQL.Text := 'DROP VIEW ' + BillingView;
    ExecSQL;
    SQL.Text := 'DROP VIEW ' + BBmax;
    ExecSQL;
  except
  end;
end;

end.
