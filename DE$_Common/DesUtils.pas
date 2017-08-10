unit DesUtils;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  //Windows, Messages, SysUtils, Variants, Classes, Dialogs, Forms,
  StrUtils,  IOUtils, IniFiles, ComObj, //, Grids, AdvObj, StdCtrls,
  IdHTTP, Data.DB, ZAbstractRODataset, ZAbstractDataset, ZDataset,
  ZAbstractConnection, ZConnection, Superobject, AArray;


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
    function vytvorFaZaInternetKredit(VS : string; castka : currency; datum : double) : string;
    function vytvorFaZaVoipKredit(VS : string; castka : currency; datum : double) : string;


    public
      PROGRAM_PATH,
      GPC_PATH,
      abraDefaultCommMethod,
      abraConnName,
      abraUserUN,
      abraUserPW,
      abraWebApiUrl : string;
      appMode: integer;
      AbraOLE: variant;


      function getAbraOLE() : variant;
      procedure abraOLELogout();
      function abraBoGet(abraBoName : string) : string;
      function abraBoGetById(abraBoName, sId : string) : string;
      function abraBoCreate(boAA: TAArray; abraBoName : string) : string;
      function abraBoCreateOLE(boAA: TAArray; abraBoName : string) : string;
      function abraBoCreateWebApi(boAA: TAArray; abraBoName : string) : string;
      function abraBoUpdate(boAA: TAArray; abraBoName, abraBoId : string; abraBoChildName: string = ''; abraBoChildId: string = '') : string;
      function abraBoUpdateOLE(boAA: TAArray; abraBoName, abraBoId : string; abraBoChildName: string = ''; abraBoChildId: string = '') : string;
      function abraBoUpdateWebApi(boAA: TAArray; abraBoName, abraBoId : string; abraBoChildName: string = ''; abraBoChildId: string = '') : string;
      procedure logJson(boAAjson, header : string);

      function abraBoCreate_So(jsonSO: ISuperObject; abraBoName : string) : string;
      function abraBoCreate_SoOLE(jsonSO: ISuperObject; abraBoName : string) : string;
      function abraBoCreate_SoWebApi(jsonSO: ISuperObject; abraBoName : string) : string;
      function abraBoUpdate_So(jsonSO: ISuperObject; abraBoName, abraBoId : string; abraBoChildName: string = ''; abraBoChildId: string = '') : string;
      function abraBoUpdate_SoOLE(jsonSO: ISuperObject; abraBoName, abraBoId : string; abraBoChildName: string = ''; abraBoChildId: string = '') : string;
      function abraBoUpdate_SoWebApi(jsonSO: ISuperObject; abraBoName, abraBoId : string; abraBoChildName: string = ''; abraBoChildId: string = '') : string;
      procedure logJson_So(jsonSO: ISuperObject; header : string);


      function getAbraPeriodId(pYear : string) : string; overload;
      function getAbraPeriodId(pDate : double) : string; overload;
      function getAbraDocqueueId(code, documentType : string) : string;
      function getAbraVatrateId(code : string) : string;
      function getAbraVatindexId(code : string) : string;
      function getAbraIncometypeId(code : string) : string;
      function getAbraBusorderId(name : string) : string;
      function getAbraDivisionId() : string;
      function getAbraCurrencyId(code : string = 'CZK') : string;

      function getAbracodeByVs(vs : string) : string;
      function getAbracodeByContractNumber(cnumber : string) : string;
      function getFirmIdByCode(code : string) : string;
      function getZustatekByAccountId (accountId : string; datum : double) : double;
      function isVoipContract(cnumber : string) : boolean;
      function isCreditContract(cnumber : string) : boolean;

    private
      function newAbraIdHttp(timeout : single; isJsonPost : boolean) : TIdHTTP;

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
function FloatToStrFD (pFloat : extended) : string;
function RandString(const stringsize: integer): string;


const
  Ap = chr(39);
  ApC = Ap + ',';
  ApZ = Ap + ')';


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

  if not(FileExists(PROGRAM_PATH + 'abraDesProgramy.ini'))
    AND not(FileExists(PROGRAM_PATH + '..\DE$_Common\abraDesProgramy.ini')) then
  begin
    Application.MessageBox(PChar('Nenalezen soubor abraDesProgramy.ini, program ukonèen'),
      'abraDesProgramy.ini', MB_OK + MB_ICONERROR);
    Application.Terminate;
  end;

  if FileExists(PROGRAM_PATH + 'abraDesProgramy.ini') then
    adpIniFile := TIniFile.Create(PROGRAM_PATH + 'abraDesProgramy.ini')
  else
    adpIniFile := TIniFile.Create(PROGRAM_PATH + '..\DE$_Common\abraDesProgramy.ini');

  with adpIniFile do try
    appMode := strtoint(ReadString('Preferences', 'AppMode', '1'));
    abraDefaultCommMethod := ReadString('Preferences', 'AbraDefaultCommMethod', 'OLE');
    abraConnName := ReadString('Preferences', 'abraConnName', '');
    abraUserUN := ReadString('Preferences', 'AbraUserUN', '');
    abraUserPW := ReadString('Preferences', 'AbraUserPW', '');
    abraWebApiUrl := ReadString('Preferences', 'AbraWebApiUrl', '');
    GPC_PATH := IncludeTrailingPathDelimiter(ReadString('Preferences', 'GpcPath', ''));

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



  if not dbAbra.Connected then try
    dbAbra.Connect;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Nedá se pøipojit k databázi Abry, program ukonèen.' + ^M + E.Message), 'Abra', MB_ICONERROR + MB_OK);
      Application.Terminate;
    end;
  end;

  if (not dbZakos.Connected) AND (dbZakos.Database <> '') then try
    dbZakos.Connect;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Nedá se pøipojit k databázi smluv, program ukonèen.' + ^M + E.Message), 'Abra', MB_ICONERROR + MB_OK);
      Application.Terminate;
    end;
  end;


  {
  //if iniNacteno > 0 then Exit;
  if assigned(DesU) then
     //ShowMessage('DesU objekt je již vytvoøen')
  else begin
     DesU := TDesU.Create(createOptions);
     //ShowMessage('DesU objekt není vytvoøen, vytváøíme nyní');
  end;
  }
end;


function TDesU.getAbraOLE() : variant;
begin
  Result := null;
  if VarIsEmpty(AbraOLE) then try
    AbraOLE := CreateOLEObject('AbraOLE.Application');
    if not AbraOLE.Connect('@' + abraConnName) then begin
      ShowMessage('Problém s Abrou (connect ' + abraConnName + ').');
      Exit;
    end;
    //Zprava('Pøipojeno k Abøe (connect DES).');
    if not AbraOLE.Login(abraUserUN, abraUserPW) then begin
//    if not AbraOLE.Login(abraUserUN, abraUserPW) then begin
      ShowMessage('Problém s Abrou (login ' + abraUserUN +').');
      Exit;
    end;
    //Zprava('Pøihlášeno k Abøe (login Supervisor).');
  except on E: exception do
    begin
      Application.MessageBox(PChar('Problém s Abrou.' + ^M + E.Message), 'Abra', MB_ICONERROR + MB_OK);
      //Zprava('Problém s Abrou - ' + E.Message);
      Exit;
    end;
  end;
  Result := AbraOLE;
end;

procedure TDesU.abraOLELogout();
begin
  if VarIsEmpty(AbraOLE) then Exit;
  try
    self.AbraOLE.Logout;
  except
  end;
  self.AbraOLE := Unassigned;
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
  idHTTP.ReadTimeout := Round (timeout * 1000); // ReadTimeout je v milisekundách

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

procedure TDesU.logJson_So(jsonSO: ISuperObject; header : string);
var
  myDate : TDateTime;
begin
  if appMode >= 3 then begin
    myDate := Now;
    writeToFile(PROGRAM_PATH + '\log\json\' + formatdatetime('yymmdd-hhnnss', Now) + '_' + RandString(3) + '.txt', header + sLineBreak + jsonSO.AsJSon(true));
  end;
end;

function TDesU.abraBoCreate_So(jsonSO: ISuperObject; abraBoName : string) : string;
begin
  if AnsiLowerCase(abraDefaultCommMethod) = 'webapi' then
    Result := self.abraBoCreate_SoWebApi(jsonSO, abraBoName)
  else
    Result := self.abraBoCreate_SoOLE(jsonSO, abraBoName);
end;

function TDesU.abraBoCreate_SoWebApi(jsonSO: ISuperObject; abraBoName : string) : string;
var
  idHTTP: TIdHTTP;
  sstreamJson: TStringStream;
  newAbraBo : string;
begin

  self.logJson_So(jsonSO, 'abraBoCreate_SoWebApi - ' + abraWebApiUrl + abraBoName);

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
      end;
    end;
  finally
    sstreamJson.Free;
    idHTTP.Free;
  end;
end;

function TDesU.abraBoCreate_SoOLE(jsonSO: ISuperObject; abraBoName : string) : string;
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
  self.logJson_So(jsonSO, 'abraBoCreate_SoOLE - abraBoName=' + abraBoName);

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
    Result := Result + 'Èíslo nového BO je ' + NewID;
  end;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Problem ' + ^M + E.Message), 'AbraOLE');
      Result := Result + 'Chyba pøi zakládání BO';
    end;
  end;

end;


function TDesU.abraBoUpdate_So(jsonSO: ISuperObject; abraBoName, abraBoId, abraBoChildName, abraBoChildId: string) : string;
begin
  if AnsiLowerCase(self.abraDefaultCommMethod) = 'webapi' then
    Result := self.abraBoUpdate_SoWebApi(jsonSO, abraBoName, abraBoId, abraBoChildName, abraBoChildId)
  else
    Result := self.abraBoUpdate_SoOLE(jsonSO, abraBoName, abraBoId, abraBoChildName, abraBoChildId);
end;



function TDesU.abraBoUpdate_SoWebApi(jsonSO: ISuperObject; abraBoName, abraBoId, abraBoChildName, abraBoChildId : string) : string;
var
  idHTTP: TIdHTTP;
  sstreamJson: TStringStream;
  endpoint : string;
begin


  // http://localhost/DES/issuedinvoices/8L6U000101/rows/5A3K100101
  endpoint := abraWebApiUrl + abraBoName + 's/' + abraBoId;
  if abraBoChildName <> '' then
    endpoint := endpoint + '/' + abraBoChildName + 's/' + abraBoChildId;

  self.logJson_So(jsonSO, 'abraBoUpdate_SoWebApi - ' + endpoint);


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


function TDesU.abraBoUpdate_SoOLE(jsonSO: ISuperObject; abraBoName, abraBoId, abraBoChildName, abraBoChildId : string) : string;
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

  self.logJson_So(jsonSO, 'abraBoUpdate_SoOLE - abraBoName=' + abraBoName + ' abraBoId=' + abraBoId);


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


{** **}


procedure TDesU.logJson(boAAjson, header : string);
var
  myDate : TDateTime;
begin
  if appMode >= 3 then begin
    if not DirectoryExists(PROGRAM_PATH + '\log\json\') then
      Forcedirectories(PROGRAM_PATH + '\log\json\');
    myDate := Now;
    writeToFile(PROGRAM_PATH + '\log\json\' + formatdatetime('yymmdd-hhnnss', Now) + '_' + RandString(3) + '.txt', header + sLineBreak + boAAjson);
  end;
end;

function TDesU.abraBoCreate(boAA: TAArray; abraBoName : string) : string;
begin
  if AnsiLowerCase(abraDefaultCommMethod) = 'webapi' then
    Result := self.abraBoCreateWebApi(boAA, abraBoName)
  else
    Result := self.abraBoCreateOLE(boAA, abraBoName);
end;

function TDesU.abraBoCreateWebApi(boAA: TAArray; abraBoName : string) : string;
var
  idHTTP: TIdHTTP;
  sstreamJson: TStringStream;
  newAbraBo : string;
begin

  self.logJson(boAA.AsJSon(), 'abraBoCreateWebApi_AA - ' + abraWebApiUrl + abraBoName);

  sstreamJson := TStringStream.Create(boAA.AsJSon(), TEncoding.UTF8);
  idHTTP := newAbraIdHttp(900, true);
  try
    try begin
      newAbraBo := idHTTP.Post(abraWebApiUrl + abraBoName + 's', sstreamJson);
      Result := SO(newAbraBo).S['id'];
    end;
    except
      on E: Exception do begin
        ShowMessage('Error on request: '#13#10 + e.Message);
      end;
    end;
  finally
    sstreamJson.Free;
    idHTTP.Free;
  end;
end;

function TDesU.abraBoCreateOLE(boAA: TAArray; abraBoName : string) : string;
var
  i, j : integer;
  BO_Object,
  BO_Data,
  BORow_Object,
  BORow_Data,
  BO_Data_Coll,
  NewID : variant;

  iBoRowAA : TAArray;

begin

  self.logJson(boAA.AsJSon(), 'abraBoCreateOLE_AA - abraBoName=' + abraBoName);
  AbraOLE := getAbraOLE();
  BO_Object:= AbraOLE.CreateObject('@'+abraBoName);
  BO_Data:= AbraOLE.CreateValues('@'+abraBoName);
  BO_Object.PrefillValues(BO_Data);

  for i := 0 to boAA.Count - 1 do
    BO_Data.ValueByName(boAA.Keys[i]) := boAA.Values[i];

  if boAA.RowList.Count > 0 then
  begin
    BORow_Object := AbraOLE.CreateObject('@'+abraBoName+'Row');
    BO_Data_Coll := BO_Data.Value[IndexByName(BO_Data, 'Rows')];

    for i := 0 to boAA.RowList.Count - 1 do
    begin
      BORow_Data := AbraOLE.CreateValues('@'+abraBoName+'Row');
      BORow_Object.PrefillValues(BORow_Data);

      iBoRowAA := TAArray(boAA.RowList[i]);
      for j := 0 to iBoRowAA.Count - 1 do
        BORow_Data.ValueByName(iBoRowAA.Keys[j]) := iBoRowAA.Values[j];

      BO_Data_Coll.Add(BORow_Data);
    end;
  end;

  try begin
    NewID := BO_Object.CreateNewFromValues(BO_Data); //NewID je ID Abry
    //Result := Result + 'Èíslo nového BO je ' + NewID;
    Result := NewID;
  end;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Problem ' + ^M + E.Message), 'AbraOLE');
      Result := 'Chyba pøi zakládání BO';
    end;
  end;

end;


function TDesU.abraBoUpdate(boAA: TAArray; abraBoName, abraBoId, abraBoChildName, abraBoChildId: string) : string;
begin
  if AnsiLowerCase(self.abraDefaultCommMethod) = 'webapi' then
    Result := self.abraBoUpdateWebApi(boAA, abraBoName, abraBoId, abraBoChildName, abraBoChildId)
  else
    Result := self.abraBoUpdateOLE(boAA, abraBoName, abraBoId, abraBoChildName, abraBoChildId);
end;



function TDesU.abraBoUpdateWebApi(boAA: TAArray; abraBoName, abraBoId, abraBoChildName, abraBoChildId : string) : string;
var
  idHTTP: TIdHTTP;
  sstreamJson: TStringStream;
  endpoint : string;

begin
  // http://localhost/DES/issuedinvoices/8L6U000101/rows/5A3K100101
  endpoint := abraWebApiUrl + abraBoName + 's/' + abraBoId;
  if abraBoChildName <> '' then
    endpoint := endpoint + '/' + abraBoChildName + 's/' + abraBoChildId;

  self.logJson(boAA.AsJSon(), 'abraBoUpdateWebApi_AA - ' + endpoint);

  sstreamJson := TStringStream.Create(boAA.AsJSon(), TEncoding.UTF8);
  idHTTP := newAbraIdHttp(900, true);
  try
    Result := idHTTP.Put(endpoint, sstreamJson);
  finally
    sstreamJson.Free;
    idHTTP.Free;
  end;
end;


function TDesU.abraBoUpdateOLE(boAA: TAArray; abraBoName, abraBoId, abraBoChildName, abraBoChildId : string) : string;
var
  i: integer;
  BO_Object,
  BO_Data,
  BORow_Object,
  BORow_Data,
  BO_Data_Coll : variant;

begin
  abraBoName := abraBoName + abraBoChildName;

  if abraBoChildName <> '' then
    abraBoId := abraBoChildId;  //budeme pracovat s ID childa

  self.logJson(boAA.AsJSon(), 'abraBoUpdateOLE_AA - abraBoName=' + abraBoName + ' abraBoId=' + abraBoId);

  AbraOLE := getAbraOLE();
  BO_Object := AbraOLE.CreateObject('@' + abraBoName);
  BO_Data := AbraOLE.CreateValues('@' + abraBoName);

  BO_Data := BO_Object.GetValues(abraBoId);

  for i := 0 to boAA.Count - 1 do
    BO_Data.ValueByName(boAA.Keys[i]) := boAA.Values[i];

  BO_Object.UpdateValues(abraBoId, BO_Data);

end;



{*** ABRA data manipulating functions ***}

function TDesU.prevedCisloUctuNaText(cisloU : string) : string;
begin
  Result := cisloU;
  if cisloU = '/0000' then Result := '0';
  if cisloU = '2100098382/2010' then Result := 'DES Fio bìžný';
  if cisloU = '2800098383/2010' then Result := 'DES Fio spoøící';
  if cisloU = '171336270/0300' then Result := 'DES ÈSOB';
  if cisloU = '2107333410/2700' then Result := 'PayU';
  if cisloU = '160987123/0300' then Result := 'Èeská Pošta';
end;

procedure TDesU.opravRadekVypisuPomociPDocument_ID(Vypis_ID, RadekVypisu_ID, PDocument_ID, PDocumentType : string);
var
  boAA: TAArray;
  sResponse: string;
begin
  boAA := TAArray.Create;
  boAA['PDocumentType'] := PDocumentType;
  boAA['PDocument_ID'] := PDocument_ID;
  sResponse := self.abraBoUpdate(boAA, 'bankstatement', Vypis_ID, 'row', RadekVypisu_ID);
end;


procedure TDesU.opravRadekVypisuPomociVS(Vypis_ID, RadekVypisu_ID, VS : string);
var
  boAA: TAArray;
  sResponse: string;
begin
  boAA := TAArray.Create;
  boAA['VarSymbol'] := ''; //odstranit VS aby se Abra chytla pøi pøiøazení
  sResponse := self.abraBoUpdate(boAA, 'bankstatement', Vypis_ID, 'row', RadekVypisu_ID);

  boAA := TAArray.Create;
  boAA['VarSymbol'] := VS;
  sResponse := self.abraBoUpdate(boAA, 'bankstatement', Vypis_ID, 'row', RadekVypisu_ID);
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

function TDesU.vytvorFaZaInternetKredit(VS : string; castka : currency; datum : double) : string;
var
  i: integer;
  boAA, boRowAA: TAArray;
  newId, firmAbraCode: String;
begin

  firmAbraCode := self.getAbracodeByContractNumber(VS);
  if firmAbraCode = '' then begin
    Result := '';
    Exit;
  end;


  boAA := TAArray.Create;
  boAA['DocQueue_ID'] := self.getAbraDocqueueId('FO2', '03');
  boAA['Period_ID'] := self.getAbraPeriodId(datum);
  boAA['VatDate$DATE'] := datum;
  boAA['DocDate$DATE'] := datum;
  boAA['Firm_ID'] := self.getFirmIdByCode(firmAbraCode);
  boAA['Description'] := 'Kredit Internet';
  boAA['Varsymbol'] := VS;
  boAA['PricesWithVat'] := true;


  // 1. øádek
  boRowAA := boAA.addRow();
  boRowAA['Rowtype'] := 0;
  boRowAA['Text'] := ' ';
  boRowAA['Division_Id'] := self.getAbraDivisionId;

 //2. øádek
  boRowAA := boAA.addRow();
  boRowAA['Rowtype'] := 1;
  boRowAA['Totalprice'] := castka;
  boRowAA['Text'] := 'Kredit Internet';
  boRowAA['Vatrate_Id'] := self.getAbraVatrateId('Výst21');
  boRowAA['Incometype_Id'] := self.getAbraIncometypeId('SL'); // služby
  //boRowAA['BusOrder_Id'] := self.getAbraBusorderId('kredit Internet');
  boRowAA['Division_Id'] := self.getAbraDivisionId;

  //writeToFile(ExtractFilePath(ParamStr(0)) + '!json' + formatdatetime('hhnnss', Now) + '.txt', jsonBo.AsJSon(true));

  try begin
    newId := DesU.abraBoCreate(boAA, 'issuedinvoice');
    Result := newId;
  end;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Problem ' + ^M + E.Message), 'Vytvoøení fa');
      Result := 'Chyba pøi vytváøení faktury';
    end;
  end;

end;

function TDesU.vytvorFaZaVoipKredit(VS : string; castka : currency; datum : double) : string;
var
  i: integer;
  boAA, boRowAA: TAArray;
  newId, firmAbraCode: String;
begin

  firmAbraCode := self.getAbracodeByContractNumber(VS);
  if firmAbraCode = '' then begin
    Result := '';
    Exit;
  end;


  boAA := TAArray.Create;
  boAA['DocQueue_ID'] := self.getAbraDocqueueId('FO2', '03');
  boAA['Period_ID'] := self.getAbraPeriodId(datum);
  boAA['VatDate$DATE'] := datum;
  boAA['DocDate$DATE'] := datum;
  boAA['Firm_ID'] := self.getFirmIdByCode(firmAbraCode);
  boAA['Description'] := 'Kredit VoIP';
  boAA['Varsymbol'] := VS;
  boAA['PricesWithVat'] := true;


  // 1. øádek
  boRowAA := boAA.addRow();
  boRowAA['Rowtype'] := 0;
  boRowAA['Text'] := ' ';
  boRowAA['Division_Id'] := self.getAbraDivisionId;

 //2. øádek
  boRowAA := boAA.addRow();
  boRowAA['Rowtype'] := 1;
  boRowAA['Totalprice'] := castka;
  boRowAA['Text'] := 'Kredit VoIP';
  boRowAA['Vatrate_Id'] := self.getAbraVatrateId('Výst21');
  //boRowAA.S['Vatindex_Id'] := self.getAbraVatindexId('Výst21'); //je potøeba?
  boRowAA['Incometype_Id'] := self.getAbraIncometypeId('SL'); // služby
  boRowAA['BusOrder_Id'] := self.getAbraBusorderId('kredit VoIP'); // '6400000101' zkontrolovat že je 'kredit VoIP' v DB
  boRowAA['Division_Id'] := self.getAbraDivisionId;

  //writeToFile(ExtractFilePath(ParamStr(0)) + '!json' + formatdatetime('hhnnss', Now) + '.txt', jsonBo.AsJSon(true));

  try begin
    newId := DesU.abraBoCreate(boAA, 'issuedinvoice');
    Result := newId;
  end;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Problem ' + ^M + E.Message), 'Vytvoøení fa');
      Result := 'Chyba pøi vytváøení faktury';
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

function TDesU.getAbraBusorderId(name : string) : string;
begin

  with DesU.qrAbra do begin
    SQL.Text := 'SELECT Id FROM BusOrders'
              + ' WHERE Name = ''' + name + '''';
    Open;
    if not Eof then begin
      Result := FieldByName('Id').AsString;
    end;
    Close;
  end;
end;

function TDesU.getAbraDivisionId() : string;
begin
  Result := '1000000101';
end;

function TDesU.getAbraCurrencyId(code : string = 'CZK') : string;
begin
  Result := '0000CZK000'; //pouze CZK
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

function TDesU.getZustatekByAccountId (accountId : string; datum : double) : double;
begin

  with DesU.qrAbra do begin
    SQL.Text := 'SELECT (DEBITBEGINNING - CREDITBEGINNING + DEBITBEGINNIGTURNOVER'
      + ' - CREDITBEGINNIGTURNOVER + DEBITTURNOVER - CREDITTURNOVER) as zustatek'
      + ' FROM ACCOUNTCALCULUS'
      + ' (''%'',''' + accountId + ''',null,null,'
      + FloatToStrFD(datum) + ',' + FloatToStrFD(datum) + ','
      + ' '''',''0'','''',''0'','''',''0'','''',''0'','
      + ' null,null,null,0)';
    Open;
    if not Eof then begin
      Result := FieldByName('zustatek').AsFloat;
    end;
    Close;
  end;
end;

function TDesU.isVoipContract(cnumber : string) : boolean;
begin

  with DesU.qrZakos do begin
    SQL.Text := 'SELECT co.id FROM contracts co  '
              + ' WHERE co.number = ''' + cnumber + ''''
              + ' AND co.type = ''VoipContract''';
    Open;
    if not Eof then
      Result := true
    else
      Result := false;
    Close;
  end;
end;

function TDesU.isCreditContract(cnumber : string) : boolean;
begin

  with DesU.qrZakos do begin
    SQL.Text := 'SELECT co.id FROM contracts co  '
              + ' WHERE co.number = ''' + cnumber + ''''
              + ' AND co.credit = 1';
    Open;
    if not Eof then
      Result := true
    else
      Result := false;
    Close;
  end;
end;


{***************************************************************************}
{********************     General helper functions     *********************}
{***************************************************************************}

// odstraní ze stringu nuly na zaèátku
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


//zaplní øetìzec nulama zleva až do celkové délky lenght
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
// náhrada za nefunkèní DataObject.ValuByName(Name)
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
            //Result := FindInFolder(sFolder + sr.Name, sFile, bUseSubfolders); // plná rekurze
            Result := FindInFolder(sFolder + sr.Name, sFile, false); // rekurze jen do 1. úrovnì

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

function RandString(const stringsize: integer): string;
var
  i: integer;
  const ss: string = 'abcdefghijklmnopqrstuvwxyz';
begin
  for i:=1 to stringsize do
      Result:=Result + ss[random(length(ss)) + 1];
end;

// FloatToStr s nahrazením èárek teèkami
function FloatToStrFD (pFloat : extended) : string;
begin
  Result := AnsiReplaceStr(FloatToStr(pFloat), ',', '.');
end;




end.
