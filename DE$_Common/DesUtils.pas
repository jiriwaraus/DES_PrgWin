unit DesUtils;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  //Windows, Messages, SysUtils, Variants, Classes, Dialogs, Forms,
  StrUtils,  IniFiles, ComObj, //, Grids, AdvObj, StdCtrls,
  IdHTTP, Data.DB, ZAbstractRODataset, ZAbstractDataset, ZDataset,
  ZAbstractConnection, ZConnection, Superobject;


type
  TDesU = class(TForm)
    dbAbra: TZConnection;
    qrAbra: TZQuery;
    dbZakos: TZConnection;
    qrZakos: TZQuery;


    procedure FormCreate(Sender: TObject);
    procedure desUtilsInit(createOptions : string);

    function prevedCisloUctuNaText(cisloU : string) : string;
    procedure opravRadekVypisuPomociPDocument_ID(Vypis_ID, RadekVypisu_ID, PDocument_ID, PDocumentType : string);
    procedure opravRadekVypisuPomociVS(Vypis_ID, RadekVypisu_ID, VS : string);
    function getOleObjDataDisplay(abraOleObj_Data : variant) : ansistring;
    function vytvorFaZaVoipKredit(VS : string; castka : currency; datum : double) : string;


    public
      PROGRAM_PATH,
      GPC_PATH,
      abraDefaultCommMethod,
      abraWebApiUrl,
      abraUserUN,
      abraUserPW : string;
      AbraOLE: variant;

      function getAbraOLE() : variant;
      function abraBoGet(abraBoName : string) : string;
      //function abraBoGetByRowId(abraBoName, rowId : string) : string;
      function abraBoGetById(abraBoName, sId : string) : string;
      function abraBoCreate(abraBoName : string; jsonSO: ISuperObject) : string;
      function abraBoCreateOLE(abraBoName : string; jsonSO: ISuperObject) : string;
      function abraBoCreateWebApi(abraBoName : string; jsonSO: ISuperObject) : string;
      function abraBoUpdate(abraBoName, abraBoId : string; jsonSO: ISuperObject) : string; overload;
      function abraBoUpdate(abraBoName, abraBoId, abraBoChildName, abraBoChildId: string; jsonSO: ISuperObject) : string; overload;
      function abraBoUpdateOLE(abraBoName, abraBoId : string; jsonSO: ISuperObject) : string; overload;
      function abraBoUpdateOLE(abraBoName, abraBoId, abraBoChildName, abraBoChildId: string; jsonSO: ISuperObject) : string; overload;
      function abraBoUpdateWebApi(abraBoName, abraBoId : string; jsonSO: ISuperObject) : string; overload;
      function abraBoUpdateWebApi(abraBoName, abraBoId, abraBoChildName, abraBoChildId: string; jsonSO: ISuperObject) : string; overload;

      function getAbraPeriodId(pYear : string) : string; overload;
      function getAbraPeriodId(pDate : double) : string; overload;
      function getAbraDocqueueId(code, documentType : string) : string;
      function getAbraVatrateId(code : string) : string;
      function getAbraVatindexId(code : string) : string;
      function getAbraIncometypeId(code : string) : string;
      function getAbracodeByVs(vs : string) : string;
      function getAbracodeByContractNumber(cnumber : string) : string;
      function getFirmIdByCode(code : string) : string;

    private
      function newAbraIdHttp(timeout : single; isJsonPost : boolean) : TIdHTTP;
      procedure logJson(jsonSO: ISuperObject; header : string);

  end;





function removeLeadingZeros(const Value: string): string;
function LeftPad(value:integer; length:integer=8; pad:char='0'): string; overload;
function LeftPad(value: string; length:integer=8; pad:char='0'): string; overload;
function Str6digitsToDate(datum : string) : double;
function IndexByName(DataObject: variant; Name: ShortString): integer;
function pocetRadkuTxtSouboru(SName: string): integer;
function RemoveSpaces(const s: string): string;
function FindInFolder(sFolder, sFile: string; bUseSubfolders: Boolean): string;
procedure writeToFile(pFileName, pContent : string);
function LoadFileToStr(const FileName: TFileName): ansistring;


const
  Ap = chr(39);
  ApC = Ap + ',';
  ApZ = Ap + ')';
  sLineBreak = {$IFDEF LINUX} AnsiChar(#10) {$ENDIF}
               {$IFDEF MSWINDOWS} AnsiString(#13#10) {$ENDIF};


var
  DesU: TDesU;



implementation

{$R *.dfm}

uses AbraEntities;

{****************************************************************************}
{**********************     ABRA common functions     ***********************}
{****************************************************************************}


procedure TDesU.FormCreate(Sender: TObject);
begin
  desUtilsInit('');
end;

procedure TDesU.desUtilsInit(createOptions : string);
var
  adpIniFile: TIniFile;
begin

  PROGRAM_PATH := ExtractFilePath(ParamStr(0));

  if FileExists(PROGRAM_PATH + '..\DE$_Common\abraDesProgramy.ini') then begin

    adpIniFile := TIniFile.Create(PROGRAM_PATH + '..\DE$_Common\abraDesProgramy.ini');
    with adpIniFile do try
      abraDefaultCommMethod := ReadString('Preferences', 'AbraDefaultCommMethod', '');
      abraWebApiUrl := ReadString('Preferences', 'AbraWebApiUrl', '');
      abraUserUN := ReadString('Preferences', 'AbraUserUN', '');
      abraUserPW := ReadString('Preferences', 'AbraUserPW', '');
      GPC_PATH := ReadString('Preferences', 'GpcPath', '');

      dbAbra.HostName := ReadString('Preferences', 'AbraHN', '');
      dbAbra.Database := ReadString('Preferences', 'AbraDB', '');
      dbAbra.User := ReadString('Preferences', 'AbraUN', '');
      dbAbra.Password := ReadString('Preferences', 'AbraPW', '');


      dbZakos.HostName := ReadString('Preferences', 'ZakHN', '');
      dbZakos.Database := ReadString('Preferences', 'ZakDB', '');
      dbZakos.User := ReadString('Preferences', 'ZakUN', '');
      dbZakos.Password := ReadString('Preferences', 'ZakPW', '');
    finally
      adpIniFile.Free;
    end;
  end else begin
    Application.MessageBox(PChar('Nenalezen soubor ' + PROGRAM_PATH + '..\DE$_Common\abraDesProgramy.ini, program ukonËen'),
      'abraDesProgramy.ini', MB_OK + MB_ICONERROR);
    Application.Terminate;
  end;


  if not dbAbra.Connected then try
    dbAbra.Connect;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Ned· se p¯ipojit k datab·zi Abry, program ukonËen.' + ^M + E.Message), 'Abra', MB_ICONERROR + MB_OK);
      Application.Terminate;
    end;
  end;
  {
  if not dbZakos.Connected then try
    dbZakos.Connect;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Ned· se p¯ipojit k datab·zi smluv, program ukonËen.' + ^M + E.Message), 'Abra', MB_ICONERROR + MB_OK);
      Application.Terminate;
    end;
  end;
  }

  {
  //if iniNacteno > 0 then Exit;
  if assigned(DesU) then
     //ShowMessage('DesU objekt je jiû vytvo¯en')
  else begin
     DesU := TDesU.Create(createOptions);
     //ShowMessage('DesU objekt nenÌ vytvo¯en, vytv·¯Ìme nynÌ');
  end;
  }
end;


function TDesU.getAbraOLE() : variant;
begin
  Result := null;
  if VarIsEmpty(AbraOLE) then try
    AbraOLE := CreateOLEObject('AbraOLE.Application');
    if not AbraOLE.Connect('@DES') then begin
      ShowMessage('ProblÈm s Abrou (connect DES).');
      Exit;
    end;
    //Zprava('P¯ipojeno k Ab¯e (connect DES).');
    if not AbraOLE.Login('SW', '') then begin
//    if not AbraOLE.Login(abraUserUN, abraUserPW) then begin
      ShowMessage('ProblÈm s Abrou (login Supervisor).');
      Exit;
    end;
    //Zprava('P¯ihl·öeno k Ab¯e (login Supervisor).');
  except on E: exception do
    begin
      Application.MessageBox(PChar('ProblÈm s Abrou.' + ^M + E.Message), 'Abra', MB_ICONERROR + MB_OK);
      //Zprava('ProblÈm s Abrou - ' + E.Message);
      Exit;
    end;
  end;
  Result := AbraOLE;
end;

{
function TDesU.getQrAbra() : variant;
begin

end;
}





{*** ABRA WebApi IdHTTP functions ***}

function TDesU.newAbraIdHttp(timeout : single; isJsonPost : boolean) : TIdHTTP;
var
  idHTTP: TIdHTTP;
begin
  idHTTP := TidHTTP.Create;

  idHTTP.Request.BasicAuthentication := True;
  idHTTP.Request.Username := abraUserUN;
  idHTTP.Request.Password := abraUserPW;
  idHTTP.ReadTimeout := Round (timeout * 1000); // ReadTimeout je v milisekund·ch

  if (isJsonPost) then begin
    idHTTP.Request.ContentType := 'application/json';
    idHTTP.Request.CharSet := 'utf-8';
    //idHTTP.Request.CharSet := 'cp1250';

  end;

  Result := idHTTP;
end;

function TDesU.abraBoGet(abraBoName : string) : string;
begin
  Result := abraBoGetById(abraBoName, '');
end;

{
function abraBoGetByRowId(abraBoName, rowId : string) : string;
begin
  Result := abraBoGetById(abraBoName, getEnpointPartForRowId(rowId));
end;
}

function TDesU.abraBoGetById(abraBoName, sId : string) : string;
var
  idHTTP: TIdHTTP;
  endpoint : string;
begin
  idHTTP := newAbraIdHttp(900, false);

  endpoint := abraWebApiUrl + abraBoName;
  if sId <> '' then
    endpoint := endpoint + '/' + sId;

  try
    try
      Result := idHTTP.Get(endpoint);
    except
      on E: Exception do
        ShowMessage('Error on request: '#13#10 + e.Message);
    end;
  finally
    idHTTP.Free;
  end;
end;

procedure TDesU.logJson(jsonSO: ISuperObject; header : string);
var
  myDate : TDateTime;
begin
  myDate := Now;
  writeToFile(PROGRAM_PATH + '/log/json/' + formatdatetime('yymmdd-hhnnss', Now) +'.txt', header + sLineBreak + jsonSO.AsJSon(true));
end;

function TDesU.abraBoCreate(abraBoName : string; jsonSO: ISuperObject) : string;
begin
  if AnsiLowerCase(abraDefaultCommMethod) = 'webapi' then
    Result := self.abraBoCreateWebApi(abraBoName, jsonSO)
  else
    Result := self.abraBoCreateOLE(abraBoName, jsonSO);
end;

function TDesU.abraBoCreateWebApi(abraBoName : string; jsonSO: ISuperObject) : string;
var
  idHTTP: TIdHTTP;
  sstreamJson: TStringStream;
  newAbraBo : string;
begin

  self.logJson(jsonSO, 'abraBoCreateWebApi - ' + abraWebApiUrl + abraBoName);

  //sstreamJson := TStringStream.Create(Utf8Encode(pJson)); // D2007 and earlier only
  sstreamJson := TStringStream.Create(jsonSO.AsJSon(), TEncoding.UTF8);
  idHTTP := newAbraIdHttp(900, true);
  try
    try begin
      newAbraBo := idHTTP.Post(abraWebApiUrl + abraBoName + 's', sstreamJson);
      Result := SO(newAbraBo).S['id'];
    end;
    except
      on E: Exception do begin
        ShowMessage('Error on request: '#13#10 + e.Message);
        ShowMessage(Result);
      end;
    end;
  finally
    sstreamJson.Free;
    idHTTP.Free;
  end;
end;

function TDesU.abraBoCreateOLE(abraBoName : string; jsonSO: ISuperObject) : string;
var
  i, j : integer;
  BO_Object,
  BO_Data,
  BORow_Object,
  BORow_Data,
  BO_Data_Coll,
  NewID : variant;

  //item1: ISuperObject;
  item2: TSuperAvlEntry;
  //item3: TSuperObjectIter;

begin

  {
  for item2 in jsonSO.AsObject do
  begin
    case item2.Value.DataType of
    stString:
        Result := Result + 'stString: '+item2.Name+' : '
            +item2.Value.AsString + sLineBreak;
    stDouble,
    stCurrency :     Result := Result + 'stFloat: '+item2.Name+' : '
            +item2.Value.AsString + sLineBreak;
    stInt :        Result := Result + 'stInt: '+item2.Name+' : '
            +item2.Value.AsString + sLineBreak;
    stBoolean :        Result := Result + 'stBool: '+item2.Name+' : '
            +item2.Value.AsString + sLineBreak;

    end;
  end;


  if ObjectFindFirst(jsonSO, item3) then
   repeat
     case item3.val.DataType of
      stBoolean,
      stDouble,
      stCurrency,
      stInt: Result := Result + 'Prochazeni 3: '+item3.key+' : '+ item3.val.AsString  + sLineBreak;
     end;
   until not ObjectFindNext(item3);
   ObjectFindClose(item3);


   Result := Result + sLineBreak;

  for i := 0 to jsonSO.A['rows'].Length - 1 do

    for item2 in jsonSO.A['rows'][i].AsObject do
    begin
      case item2.Value.DataType of
      stString:
          Result := Result + 'stString: '+item2.Name+' : '
              +item2.Value.AsString + sLineBreak;
      stDouble,
      stCurrency :     Result := Result + 'stFloat: '+item2.Name+' : '
              +item2.Value.AsString + sLineBreak;
      stInt :        Result := Result + 'stInt: '+item2.Name+' : '
              +item2.Value.AsString + sLineBreak;
      stBoolean :        Result := Result + 'stBool: '+item2.Name+' : '
              +item2.Value.AsString + sLineBreak;

    end;
  end;

  //exit;
  }
  self.logJson(jsonSO, 'abraBoCreateOLE - abraBoName=' + abraBoName);

  AbraOLE := getAbraOLE();
  BO_Object:= AbraOLE.CreateObject('@'+abraBoName);
  BO_Data:= AbraOLE.CreateValues('@'+abraBoName);
  BO_Object.PrefillValues(BO_Data);

  for item2 in jsonSO.AsObject do
  begin
    case item2.Value.DataType of
    stString, stDouble, stCurrency, stInt, stBoolean :
      BO_Data.ValueByName(item2.Name) := item2.Value.AsString;
    end;
  end;


  BORow_Object := AbraOLE.CreateObject('@'+abraBoName+'Row');
  BO_Data_Coll := BO_Data.Value[IndexByName(BO_Data, 'Rows')];

  for i := 0 to jsonSO.A['rows'].Length - 1 do
  begin
    BORow_Data := AbraOLE.CreateValues('@'+abraBoName+'Row');
    BORow_Object.PrefillValues(BORow_Data);

    for item2 in jsonSO.A['rows'][i].AsObject do
    begin
      case item2.Value.DataType of
      stString, stDouble, stCurrency, stInt, stBoolean :
        BORow_Data.ValueByName(item2.Name) := item2.Value.AsString;
      end;
    end;

    BO_Data_Coll.Add(BORow_Data);
  end;


  try begin
    NewID := BO_Object.CreateNewFromValues(BO_Data); //NewID je ID Abry
    Result := Result + '»Ìslo novÈho BO je ' + NewID;
  end;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Problem ' + ^M + E.Message), 'AbraOLE');
      Result := Result + 'Chyba p¯i zakl·d·nÌ BO';
    end;
  end;

end;


function TDesU.abraBoUpdate(abraBoName, abraBoId : string; jsonSO: ISuperObject) : string;
begin
  Result := self.abraBoUpdate(abraBoName, abraBoId, '', '', jsonSO);
end;

function TDesU.abraBoUpdateOLE(abraBoName, abraBoId : string; jsonSO: ISuperObject) : string;
begin
  Result := self.abraBoUpdateOLE(abraBoName, abraBoId, '', '', jsonSO);
end;

function TDesU.abraBoUpdateWebApi(abraBoName, abraBoId : string; jsonSO: ISuperObject) : string;
begin
  Result := self.abraBoUpdateWebApi(abraBoName, abraBoId, '', '', jsonSO);
end;


function TDesU.abraBoUpdate(abraBoName, abraBoId, abraBoChildName, abraBoChildId: string; jsonSO: ISuperObject) : string;
begin
  if AnsiLowerCase(self.abraDefaultCommMethod) = 'webapi' then
    Result := self.abraBoUpdateWebApi(abraBoName, abraBoId, abraBoChildName, abraBoChildId, jsonSO)
  else
    Result := self.abraBoUpdateOLE(abraBoName, abraBoId, abraBoChildName, abraBoChildId, jsonSO);
end;



function TDesU.abraBoUpdateWebApi(abraBoName, abraBoId, abraBoChildName, abraBoChildId : string; jsonSO: ISuperObject) : string;
var
  idHTTP: TIdHTTP;
  sstreamJson: TStringStream;
  endpoint : string;
begin


  // http://localhost/DES/issuedinvoices/8L6U000101/rows/5A3K100101
  endpoint := abraWebApiUrl + abraBoName + 's/' + abraBoId;
  if abraBoChildName <> '' then
    endpoint := endpoint + '/' + abraBoChildName + 's/' + abraBoChildId;

  self.logJson(jsonSO, 'abraBoUpdateWebApi - ' + endpoint);


  //sstreamJson := TStringStream.Create(Utf8Encode(pJson)); // D2007 and earlier only
  sstreamJson := TStringStream.Create(jsonSO.AsJSon(), TEncoding.UTF8);
  idHTTP := newAbraIdHttp(900, true);
  try
    try
      Result := idHTTP.Put(endpoint, sstreamJson);
    except
      on E: Exception do
        ShowMessage('Error on request: '#13#10 + e.Message);
    end;
  finally
    sstreamJson.Free;
    idHTTP.Free;
  end;
end;


function TDesU.abraBoUpdateOLE(abraBoName, abraBoId, abraBoChildName, abraBoChildId : string; jsonSO: ISuperObject) : string;
var
  i, j : integer;
  BO_Object,
  BO_Data,
  BORow_Object,
  BORow_Data,
  BO_Data_Coll,
  NewID : variant;

  item1: ISuperObject;
  item2: TSuperAvlEntry;
  item3: TSuperObjectIter;

begin
  abraBoName := abraBoName + abraBoChildName;

  if abraBoChildName <> '' then
    abraBoId := abraBoChildId;  //budeme pracovat s ID childa

  self.logJson(jsonSO, 'abraBoUpdateOLE - abraBoName=' + abraBoName + ' abraBoId=' + abraBoId);


  AbraOLE := getAbraOLE();
  BO_Object := AbraOLE.CreateObject('@' + abraBoName);
  BO_Data := AbraOLE.CreateValues('@' + abraBoName);

  BO_Data := BO_Object.GetValues(abraBoId);

  for item2 in jsonSO.AsObject do
  begin
    case item2.Value.DataType of
    stString, stDouble, stCurrency, stInt, stBoolean :
      BO_Data.ValueByName(item2.Name) := item2.Value.AsString;
    end;
  end;

  BO_Object.UpdateValues(abraBoId, BO_Data);

end;







{*** ABRA data manipulating functions ***}

function TDesU.prevedCisloUctuNaText(cisloU : string) : string;
begin
  Result := cisloU;
  if cisloU = '/0000' then Result := '0';
  if cisloU = '2100098382/2010' then Result := 'DES Fio bÏûn˝';
  if cisloU = '2800098383/2010' then Result := 'DES Fio spo¯ÌcÌ';
  if cisloU = '171336270/0300' then Result := 'DES »SOB';
  if cisloU = '2107333410/2700' then Result := 'PayU';
  if cisloU = '160987123/0300' then Result := '»esk· Poöta';
end;

procedure TDesU.opravRadekVypisuPomociPDocument_ID(Vypis_ID, RadekVypisu_ID, PDocument_ID, PDocumentType : string);
var
  JsonSO: ISuperObject;
  sResponse: string;
  {
  BStatement_Object,
  BStatement_Data,
  BStatementRow_Object,
  BStatementRow_Data,
  BStatementRow_Coll : variant;
  }

begin
  { takhle to bylo pres OLE
  BStatementRow_Object := AbraOLE.CreateObject('@BankStatementRow');
  BStatementRow_Data := AbraOLE.CreateValues('@BankStatementRow');

  BStatementRow_Data := BStatementRow_Object.GetValues(Radek_ID);
  BStatementRow_Data.ValueByName('PDocumentType') := PDocumentType;
  BStatementRow_Data.ValueByName('PDocument_ID') := PDocument_ID;
  BStatementRow_Object.UpdateValues(Radek_ID, BStatementRow_Data);
  }

  JsonSO := SO;
  JsonSO.S['PDocumentType'] := PDocumentType;
  JsonSO.S['PDocument_ID'] := PDocument_ID;

  //sResponse := abraBoUpdate('bankstatements/' + Vypis_ID + '/rows/' + RadekVypisu_ID, JsonSO); //bylo p¯ed refactorem
  sResponse := abraBoUpdate('bankstatement', Vypis_ID, 'row', RadekVypisu_ID, JsonSO);

end;


procedure TDesU.opravRadekVypisuPomociVS(Vypis_ID, RadekVypisu_ID, VS : string);
var
  JsonSO: ISuperObject;
  sResponse: string;
begin
  { takhle to bylo pres OLE
  BStatementRow_Object := AbraOLE.CreateObject('@BankStatementRow');
  BStatementRow_Data := AbraOLE.CreateValues('@BankStatementRow');

  BStatementRow_Data := BStatementRow_Object.GetValues(Radek_ID);
  BStatementRow_Data.ValueByName('VarSymbol') := ''; //odstranit VS aby se Abra chytla p¯i p¯i¯azenÌ
  BStatementRow_Object.UpdateValues(Radek_ID, BStatementRow_Data);

  BStatementRow_Data := BStatementRow_Object.GetValues(Radek_ID);
  BStatementRow_Data.ValueByName('VarSymbol') := VS;
  BStatementRow_Object.UpdateValues(Radek_ID, BStatementRow_Data);
  }

  JsonSO := SO;
  JsonSO.S['VarSymbol'] := ''; //odstranit VS aby se Abra chytla p¯i p¯i¯azenÌ
  sResponse := abraBoUpdate('bankstatement', Vypis_ID, 'rows', RadekVypisu_ID, JsonSO);

  JsonSO := SO;
  JsonSO.S['VarSymbol'] := VS;
  sResponse := abraBoUpdate('bankstatement', Vypis_ID, 'rows', RadekVypisu_ID, JsonSO);

end;

function TDesU.getOleObjDataDisplay(abraOleObj_Data : variant) : ansistring;
var
  j : integer;
begin
  Result := '';
  for j := 0 to abraOleObj_Data.Count - 1 do begin
    Result := Result + inttostr(j) + 'r ' + abraOleObj_Data.Names[j] + ': ' + vartostr(abraOleObj_Data.Value[j]) + sLineBreak;
  end;
end;

function TDesU.vytvorFaZaVoipKredit(VS : string; castka : currency; datum : double) : string;
var
  newIssuedInvoice : string;
  jsonBo,
  jsonBoRow,
  newJsonBo: ISuperObject;
begin

  jsonBo := SO;
  jsonBo.S['DocQueue_ID'] := self.getAbraDocqueueId('FO2', '03');
  jsonBo.S['Period_ID'] := self.getAbraPeriodId(datum);
  jsonBo.D['DocDate$DATE'] := datum;
  jsonBo.D['AccDate$DATE'] := datum;
  //jsonBo.S['Firm_ID'] := self.getFirmIdByCode(self.getAbracodeByContractNumber(VS));
  jsonBo.S['Firm_ID'] :='2SZ1000101';
  jsonBo.S['Description'] := 'kredit VoIP bÏûÌ liötiËka ùukat';
  jsonBo.S['Varsymbol'] := VS;
  jsonBo.B['PricesWithVat'] := true;

  jsonBo.O['rows'] := SA([]);

  // 1. ¯·dek
    jsonBoRow := SO;
    jsonBoRow.I['Rowtype'] := 0;
    jsonBoRow.S['Text'] := ' ';
    jsonBoRow.S['Division_Id'] := '1000000101';
    jsonBo.A['rows'].Add(jsonBoRow);

 //2. ¯·dek
    jsonBoRow := SO;
    jsonBoRow.I['Rowtype'] := 1;
    jsonBoRow.D['Totalprice'] := castka;
    jsonBoRow.S['Text'] := 'Kredit VoIP snÏûÌ hodÚouËce v˝pis˘';
    jsonBoRow.S['Vatrate_Id'] := self.getAbraVatrateId('V˝st21');
    //jsonBoRow.S['Vatindex_Id'] := self.getAbraVatindexId('V˝st21'); //je pot¯eba?
    jsonBoRow.S['Incometype_Id'] := self.getAbraIncometypeId('SL'); // sluûby
    jsonBoRow.S['BusOrder_Id'] := '6400000101'; // self.getAbraBusorderId('kredit VoIP');  todo
    jsonBoRow.S['Division_Id'] := '1000000101';
    jsonBo.A['rows'].Add(jsonBoRow);


  writeToFile(ExtractFilePath(ParamStr(0)) + '!json.txt', jsonBo.AsJSon(true));

  try begin
    newIssuedInvoice := DesU.abraBoCreate('issuedinvoice', jsonBo); //p¯i pouûitÌ OLE
    Result := newIssuedInvoice;
  end;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Problem ' + ^M + E.Message), 'Vytvo¯enÌ fa');
      Result := 'Chyba p¯i vytv·¯enÌ faktury';
    end;
  end;

end;


function TDesU.getAbraPeriodId(pYear : string) : string;
var
    abraPeriod : TAbraPeriod;
begin
  abraPeriod := TAbraPeriod.create(pYear);
  Result := abraPeriod.id;
end;

function TDesU.getAbraPeriodId(pDate : double) : string;
var
    abraPeriod : TAbraPeriod;
begin
  abraPeriod := TAbraPeriod.create(pDate);
  Result := abraPeriod.id;
end;


function TDesU.getAbraDocqueueId(code, documentType : string) : string;
begin

  with DesU.qrAbra do begin
    SQL.Text := 'SELECT Id FROM DocQueues'
              + ' WHERE Hidden = ''N'' AND Code = ''' + code  + ''' AND DocumentType = ''' + documentType + '''';
    Open;
    if not Eof then begin
      Result := FieldByName('Id').AsString;
    end;
    Close;
  end;
end;

function TDesU.getAbraVatrateId(code : string) : string;
begin

  with DesU.qrAbra do begin
    SQL.Text := 'SELECT VatRate_Id FROM VatIndexes'
              + ' WHERE Hidden = ''N'' AND Code = ''' + code + '''';
    Open;
    if not Eof then begin
      Result := FieldByName('VatRate_Id').AsString;
    end;
    Close;
  end;
end;

function TDesU.getAbraVatindexId(code : string) : string;
begin

  with DesU.qrAbra do begin
    SQL.Text := 'SELECT Id FROM VatIndexes'
              + ' WHERE Hidden = ''N'' AND Code = ''' + code  + '''';
    Open;
    if not Eof then begin
      Result := FieldByName('Id').AsString;
    end;
    Close;
  end;
end;

function TDesU.getAbraIncometypeId(code : string) : string;
begin

  with DesU.qrAbra do begin
    SQL.Text := 'SELECT Id FROM IncomeTypes'
              + ' WHERE Code = ''' + code + '''';
    Open;
    if not Eof then begin
      Result := FieldByName('Id').AsString;
    end;
    Close;
  end;
end;

function TDesU.getAbracodeByVs(vs : string) : string;
begin

  with DesU.qrZakos do begin
    SQL.Text := 'SELECT abra_code FROM customers'
              + ' WHERE variable_symbol = ''' + vs + '''';
    Open;
    if not Eof then begin
      Result := FieldByName('abra_code').AsString;
    end;
    Close;
  end;
end;

function TDesU.getAbracodeByContractNumber(cnumber : string) : string;
begin

  with DesU.qrZakos do begin
    SQL.Text := 'SELECT cu.abra_code FROM customers cu, contracts co '
              + ' WHERE co.number = ''' + cnumber + ''''
              + ' AND cu.id = co.customer_id';
    Open;
    if not Eof then begin
      Result := FieldByName('abra_code').AsString;
    end;
    Close;
  end;
end;

function TDesU.getFirmIdByCode(code : string) : string;
begin

  with DesU.qrAbra do begin
    SQL.Text := 'SELECT Id FROM Firms'
              + ' WHERE Code = ''' + code + '''';
    Open;
    if not Eof then begin
      Result := FieldByName('Id').AsString;
    end;
    Close;
  end;
end;



{***************************************************************************}
{********************     General helper functions     *********************}
{***************************************************************************}

// odstranÌ ze stringu nuly na zaË·tku
function removeLeadingZeros(const Value: string): string;
var
  i: Integer;
begin
  for i := 1 to Length(Value) do
    if Value[i]<>'0' then
    begin
      Result := Copy(Value, i, MaxInt);
      exit;
    end;
  Result := '';
end;


//zaplnÌ ¯etÏzec nulama zleva aû do celkovÈ dÈlky lenght
function LeftPad(value:integer; length:integer=8; pad:char='0'): string; overload;
begin
   result := RightStr(StringOfChar(pad,length) + IntToStr(value), length );
end;

function LeftPad(value: string; length:integer=8; pad:char='0'): string; overload;
begin
   result := RightStr(StringOfChar(pad,length) + value, length );
end;

function Str6digitsToDate(datum : string) : double;
begin
  Result := strtodate(copy(datum, 1, 2) + '.' + copy(datum, 3, 2) + '.20' + copy(datum, 5, 2));
end;

function IndexByName(DataObject: variant; Name: ShortString): integer;
// n·hrada za nefunkËnÌ DataObject.ValuByName(Name)
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

function pocetRadkuTxtSouboru(SName: string): integer;
var
  oSL : TStringlist;
begin
  oSL := TStringlist.Create;
  oSL.LoadFromFile(SName);
  Result := oSL.Count;
  oSL.Free;
end;

function RemoveSpaces(const s: string): string;
var
  len, p: integer;
  pc: PChar;
const
  WhiteSpace = [#0, #9, #10, #13, #32];

begin
  len := Length(s);
  SetLength(Result, len);

  pc := @s[1];
  p := 0;
  while len > 0 do begin
    if not (pc^ in WhiteSpace) then begin
      inc(p);
      Result[p] := pc^;
    end;
  inc(pc);
  dec(len);
  end;

  SetLength(Result, p);
end;


function FindInFolder(sFolder, sFile: string; bUseSubfolders: Boolean): string;
var
  sr: TSearchRec;
  i: Integer;
  sDatFile: String;
begin
  Result := '';
  sFolder := IncludeTrailingPathDelimiter(sFolder);
  if System.SysUtils.FindFirst(sFolder + sFile, faAnyFile - faDirectory, sr) = 0 then
  begin
    Result := sFolder + sr.Name;
    System.SysUtils.FindClose(sr);
    Exit;
  end;

  //not found .... search in subfolders
  if bUseSubfolders then
  begin
    //find first subfolder
    if System.SysUtils.FindFirst(sFolder + '*.*', faDirectory, sr) = 0 then
    begin
      try
        repeat
          if ((sr.Attr and faDirectory) <> 0) and (sr.Name <> '.') and (sr.Name <> '..') then //is real folder?
          begin
            //recursive call!
            //Result := FindInFolder(sFolder + sr.Name, sFile, bUseSubfolders); // pln· rekurze
            Result := FindInFolder(sFolder + sr.Name, sFile, false); // rekurze jen do 1. ˙rovnÏ

            if Length(Result) > 0 then Break; //found it ... escape
          end;
        until System.SysUtils.FindNext(sr) <> 0;  //...next subfolder
      finally
        System.SysUtils.FindClose(sr);
      end;
    end;
  end;
end;

procedure writeToFile(pFileName, pContent : string);
var
    OutputFile : TextFile;
begin
  AssignFile(OutputFile, pFileName);
  ReWrite(OutputFile);
  WriteLn(OutputFile, pContent);
  CloseFile(OutputFile);
end;

function LoadFileToStr(const FileName: TFileName): ansistring;
var
  FileStream : TFileStream;
begin
  FileStream:= TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
     if FileStream.Size>0 then
     begin
      SetLength(Result, FileStream.Size);
      FileStream.Read(Pointer(Result)^, FileStream.Size);
     end;
    finally
     FileStream.Free;
    end;
end;


end.
