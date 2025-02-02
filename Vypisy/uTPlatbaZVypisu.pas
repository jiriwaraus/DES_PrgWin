unit uTPlatbaZVypisu;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, IniFiles, Forms,
  Dialogs, StdCtrls, Grids, AdvObj, BaseGrid, AdvGrid, StrUtils,
  DB, ComObj, AdvEdit, DateUtils, Math, ExtCtrls,
  ZAbstractRODataset, ZAbstractDataset, ZDataset, ZAbstractConnection, ZConnection;

{
  SysUtils, Classes, DB, StrUtils, ZAbstractRODataset, ZAbstractDataset, ZDataset,
  ZAbstractConnection, ZConnection, Dialogs, DesUtils; }


type

  TPlatbaZVypisu = class
  private
    qrAbra: TZQuery;
  public
    typZaznamu: string[3];
    cisloUctuVlastni: string[16];
    cisloUctu: string[21];
    cisloUctuKZobrazeni: string[21];
    cisloDokladu: string[13];
    castka: currency;
    kodUctovani: string[1];
    VS: string[10];
    VS_orig: string[10];
    plnyPodleGpcKS: string[10];
    KS: string[4];
    SS: string[10];
    valuta: string[6];
    nazevKlienta: string[255];
    nulaNavic: string[1];
    kodMeny: string[4];
    Datum: double;
    kredit, debet: boolean;
    //isInternetKredit, isVoipKredit: boolean;
    znamyPripad: boolean;
    potrebaPotvrzeniUzivatelem: boolean;
    jePotvrzenoUzivatelem: boolean;
    zprava : string;
    vsechnyDoklady: boolean;
    pocetNacitanychPP: integer;

    problemLevel: integer;
    rozdeleniPlatby: integer;
    castecnaUhrada: integer;

    PredchoziPlatbyList : TList;
    PredchoziPlatbyVsList : TList;
    DokladyList : TList;
    
    constructor create(castka : currency); overload;
    constructor create(gpcLine : string); overload;

    procedure loadPredchoziPlatbyPodleVS(); overload;
    procedure loadPredchoziPlatbyPodleUctu(); overload;

  published
    procedure init(pocetPredchozichPlateb : integer);
    procedure loadPredchoziPlatby(pocetPlateb : integer);
    procedure loadPredchoziPlatbyPodleUctu(pocetPlateb : integer); overload;
    procedure loadPredchoziPlatbyPodleVS(pocetPlateb : integer); overload;
    procedure loadDokladyPodleVS();
    function automatickyOpravVS() : string;
    function getVSzMinulostiByBankAccount() : string;
    function getPocetPredchozichPlatebNaStejnyVS() : integer;
    function getProcentoPredchozichPlatebNaStejnyVS() : single;
    function getPocetPredchozichPlatebZeStejnehoUctu() : integer;
    function getProcentoPredchozichPlatebZeStejnehoUctu() : single;
    procedure setZnamyPripad(popis : string);
    function isPayuProvize() : boolean;
  end;


  TPredchoziPlatba = class
  public
    VS : string[10];
    Firm_ID  : string[10];
    Castka  : Currency;
    cisloUctu : string[21];
    cisloUctuKZobrazeni : string[21];
    Datum  : double;
    FirmName : string;
    constructor create(qrAbra : TZQuery);
  end;

  
implementation

uses
  AbraEntities, DesUtils;


constructor TPlatbaZVypisu.create(castka : currency);
begin
  self.qrAbra := DesU.qrAbra;
  self.castka := abs(castka);
  if castka >= 0 then self.kredit := true else self.kredit := false;
  self.debet := not self.kredit;

  self.PredchoziPlatbyList := TList.Create;
  self.PredchoziPlatbyVsList := TList.Create;
  self.DokladyList := TList.Create;
end;

constructor TPlatbaZVypisu.create(gpcLine : string);
begin
  self.qrAbra := DesU.qrAbra;

  self.typZaznamu := copy(gpcLine, 1, 3);
  self.cisloUctuVlastni := removeLeadingZeros(copy(gpcLine, 4, 16));
  self.cisloUctu := copy(gpcLine, 20, 16) + '/' + copy(gpcLine, 74, 4);
  self.cisloDokladu := copy(gpcLine, 36, 13);
  self.castka := StrToInt(removeLeadingZeros(copy(gpcLine, 49, 12))) / 100;
  self.kodUctovani := copy(gpcLine, 61, 1);
  self.VS := RemoveSpaces(removeLeadingZeros(copy(gpcLine, 62, 10)));
  //self.KSplnyPodleGpc := copy(gpcLine, 72, 10);
  self.KS := copy(gpcLine, 78, 4);
  self.SS := removeLeadingZeros(copy(gpcLine, 82, 10));
  //self.valuta := copy(gpcLine, 92, 6);
  self.nazevKlienta := Trim(copy(gpcLine, 98, 20));
  //self.nulaNavic := copy(gpcLine, 118, 1);
  //self.kodMeny := copy(gpcLine, 119, 4);
  self.Datum := Str6digitsToDate(copy(gpcLine, 123, 6));

  //self.isInternetKredit := false; // nebude vlastost, protoze platba muze byt rozdelena a cast bude kredit a cast ne
  //self.isVoipKredit := false; //dtto
  self.znamyPripad := false;
  self.potrebaPotvrzeniUzivatelem := false;
  self.jePotvrzenoUzivatelem := true;
  self.pocetNacitanychPP := 5;
  self.vsechnyDoklady := false;
  self.VS_orig := self.VS;

  if (self.kodUctovani = '1') OR (self.kodUctovani = '5') then self.kredit := false; //1 je debet, 5 je storno kreditu
  if (self.kodUctovani = '2') OR (self.kodUctovani = '4') then self.kredit := true; //2 je kredit, 4 je storno debetu
  self.debet := not self.kredit;

  { p�eps�no chov�n� VoIP kreditu, bude se br�t a� z toho co zbyde po nap�rov�n� na faktury
  //pokud je VS ve VoIP form�tu nebo je SS 8888 tak se pod�v�m jestli je v dbZakos contract oznacen jako VoipContract
  //ned�v�m se tedy pro v�echny z�znamy kv�li �et�en� �asu a mo�n�m chyb�m v dbZakos
  if ((copy(self.VS, 5, 1) = '9') AND (copy(self.VS, 1, 2) = '20')) OR (self.SS = '8888') then
    //self.isVoipKredit := true; //bylo, ale nav�c kontrola na typ
    self.isVoipKredit := DesU.isVoipContract(self.VS);
  }


  self.cisloUctuKZobrazeni := removeLeadingZeros(self.cisloUctu);
  if kredit AND (cisloUctuKZobrazeni = '2100098382/2010') then setZnamyPripad('z B�');
  if kredit AND (cisloUctuKZobrazeni = '2800098383/2010') then setZnamyPripad('z S�');
  if kredit AND (cisloUctuKZobrazeni = '171336270/0300') then setZnamyPripad('z �SOB');
  if kredit AND (cisloUctuKZobrazeni = '2107333410/2700') then setZnamyPripad('z PayU');
  if debet AND (cisloUctuKZobrazeni = '2100098382/2010') then setZnamyPripad('na B�');
  if debet AND (cisloUctuKZobrazeni = '2800098383/2010') then setZnamyPripad('na S�');
  if debet AND (cisloUctuKZobrazeni = '171336270/0300') then setZnamyPripad('na �SOB');
  if debet AND (cisloUctuVlastni = '2389210008000000') AND (AnsiContainsStr(nazevKlienta, 'illing')) then setZnamyPripad('z PayU na B�');

  cisloUctuKZobrazeni := DesU.prevedCisloUctuNaText(cisloUctuKZobrazeni);

  self.PredchoziPlatbyList := TList.Create;
  self.PredchoziPlatbyVsList := TList.Create;
  self.DokladyList := TList.Create;

end;


procedure TPlatbaZVypisu.init(pocetPredchozichPlateb : integer);
begin
  loadPredchoziPlatby(pocetPredchozichPlateb);
  loadDokladyPodleVS();
end;


procedure TPlatbaZVypisu.loadPredchoziPlatby(pocetPlateb : integer);
begin
  loadPredchoziPlatbyPodleUctu(pocetPlateb);
  loadPredchoziPlatbyPodleVS(pocetPlateb);
end;

procedure TPlatbaZVypisu.loadPredchoziPlatbyPodleUctu(pocetPlateb : integer);
begin
  self.pocetNacitanychPP := pocetPlateb;
  self.PredchoziPlatbyList := TList.Create;

  // posledn�ch N plateb ze stejn�ho ��sla ��tu
  with qrAbra do begin //todo aby se pro cislo uctu Ceske Posty nic nevratilo
    SQL.Text := 'SELECT FIRST ' + IntToStr(self.pocetNacitanychPP) + ' bs.VarSymbol, bs.Firm_ID, bs.Amount, '
              + 'bs.Credit, bs.BankAccount, bs.DocDate$Date, firms.Name as FirmName '
              + 'FROM BankStatements2 bs '
              + 'JOIN Firms ON bs.Firm_ID = Firms.Id '
              + 'WHERE bs.BankAccount = ''' + self.cisloUctu  + ''' '
              + 'AND bs.BankStatementRow_ID is null '
              + 'ORDER BY DocDate$Date DESC';
    Open;
    while not Eof do begin
      self.PredchoziPlatbyList.Add(TPredchoziPlatba.create(qrAbra));
      Next;
    end;
    Close;
  end;
end;

procedure TPlatbaZVypisu.loadPredchoziPlatbyPodleUctu();
begin
  loadPredchoziPlatbyPodleUctu(self.pocetNacitanychPP);
end;

procedure TPlatbaZVypisu.loadPredchoziPlatbyPodleVS(pocetPlateb : integer);
begin
  self.pocetNacitanychPP := pocetPlateb;
  self.PredchoziPlatbyVsList := TList.Create;

  // posledn�ch N plateb na stejn� VS
  if StrToIntDef(self.VS, 0) > 0 then
  with qrAbra do begin
    SQL.Text := 'SELECT FIRST ' + IntToStr(self.pocetNacitanychPP) + ' bs.VarSymbol, bs.Firm_ID, bs.Amount, '
              + 'bs.Credit, bs.BankAccount, bs.DocDate$Date, firms.Name as FirmName '
              + 'FROM BankStatements2 bs '
              + 'JOIN Firms ON bs.Firm_ID = Firms.Id '
              + 'WHERE bs.VarSymbol = ''' + self.VS  + ''' '
              + 'AND bs.BankStatementRow_ID is null '
              + 'ORDER BY DocDate$Date DESC';
    Open;
    while not Eof do begin
      self.PredchoziPlatbyVsList.Add(TPredchoziPlatba.create(qrAbra));
      Next;
    end;
    Close;
  end;
end;

procedure TPlatbaZVypisu.loadPredchoziPlatbyPodleVS();
begin
  loadPredchoziPlatbyPodleVS(self.pocetNacitanychPP);
end;


procedure TPlatbaZVypisu.loadDokladyPodleVS();
var
  SQLiiSelect, SQLiiJenNezaplacene, SQLiiOrder,
  SQLStr : string;
begin
  self.DokladyList := TList.Create;

  //if self.VS = '' then Exit; //pro platby bez VS kon��me. kdyby n�hodou existoval doklad s pr�zn�m VS, aby se nep�roval
  

  with qrAbra do begin

    // cteni z IssuedInvoices (faktury)
    SQLiiSelect := 'SELECT ii.ID FROM ISSUEDINVOICES ii'
                 + ' WHERE ii.VarSymbol = ''' + self.VS  + '''';

    SQLiiJenNezaplacene :=  ' AND (ii.LOCALAMOUNT - ii.LOCALPAIDAMOUNT - ii.LOCALCREDITAMOUNT + ii.LOCALPAIDCREDITAMOUNT) <> 0';
    SQLiiOrder := ' order by ii.DocDate$Date DESC';

    if self.vsechnyDoklady then
      SQL.Text := SQLiiSelect +  SQLiiOrder
    else
      SQL.Text := SQLiiSelect + SQLiiJenNezaplacene + SQLiiOrder;

    Open;
    while not Eof do begin
      self.DokladyList.Add(TDoklad.create(FieldByName('ID').AsString, '03'));
      Next;
    end;
    Close;

    // cteni z IssuedDInvoices (zalohove listy)
    SQLiiSelect := 'SELECT ii.ID FROM ISSUEDDINVOICES ii'
                 + ' WHERE ii.VarSymbol = ''' + self.VS  + '''';

    SQLiiJenNezaplacene :=  ' AND (ii.LOCALAMOUNT - ii.LOCALPAIDAMOUNT) <> 0';
    SQLiiOrder := ' order by ii.DocDate$Date DESC';

    if self.vsechnyDoklady then
      SQL.Text := SQLiiSelect +  SQLiiOrder
    else
      SQL.Text := SQLiiSelect + SQLiiJenNezaplacene + SQLiiOrder;

    Open;
    while not Eof do begin
      self.DokladyList.Add(TDoklad.create(FieldByName('ID').AsString, '10'));
      Next;
    end;
    Close;


    // kdy� se nenajde nezaplacen� faktura ani z�lohov� list, nat�hnu 1 zaplacen� abych mohl p�i�adit firmu
    if self.DokladyList.Count = 0 then begin

      SQL.Text := 'SELECT FIRST 1 ii.ID FROM ISSUEDINVOICES ii'
                   + ' WHERE ii.VarSymbol = ''' + self.VS  + ''''
                   + ' order by ii.DocDate$Date DESC';

      Open;
      if not Eof then begin
        self.DokladyList.Add(TDoklad.create(FieldByName('ID').AsString, '03'));
      end;
      Close;

    end;
  end;
end;

function TPlatbaZVypisu.automatickyOpravVS() : string;
var
  pouzivanyVSvMinulosti : string;
begin
  Result := '';
  if self.cisloUctuKZobrazeni = '/0000' then Exit;

  if self.problemLevel = 5 then
  begin
    pouzivanyVSvMinulosti := getVSzMinulostiByBankAccount();
    if pouzivanyVSvMinulosti <> '' then begin
      self.VS := pouzivanyVSvMinulosti;
      loadPredchoziPlatbyPodleVS();
      loadDokladyPodleVS;
    end;
  end;

end;


function TPlatbaZVypisu.getVSzMinulostiByBankAccount() : string;
begin
  Result := '';
  if self.cisloUctuKZobrazeni = '/0000' then Exit;

  with qrAbra do begin
    SQL.Text := 'SELECT varsymbol, count(*) as pocet FROM'
              + ' (SELECT FIRST 7 VarSymbol, Firm_ID FROM BankStatements2'
              + ' WHERE BankAccount = ''' + self.cisloUctu  + ''''
              + ' AND BankStatementRow_ID is null'
              + ' ORDER BY DocDate$Date DESC)'

              + ' GROUP BY VARSYMBOL'
              + ' order by pocet desc';

    Open;
    if not Eof then begin
      if StrToInt(FieldByName('Pocet').AsString) > 4 then
          Result := FieldByName('Varsymbol').AsString;
    end;
    Close;
  end;
end;


function TPlatbaZVypisu.getPocetPredchozichPlatebNaStejnyVS() : integer;
var
  i : integer;
begin
  Result := 0;
  if self.PredchoziPlatbyList.Count > 0 then
  begin
    for i := 0 to PredchoziPlatbyList.Count - 1 do
      if TPredchoziPlatba(self.PredchoziPlatbyList[i]).VS = self.VS then Inc(Result);
  end;
end;


function TPlatbaZVypisu.getProcentoPredchozichPlatebNaStejnyVS() : single;
begin
  if getPocetPredchozichPlatebNaStejnyVS() < 3 then
    Result := 0
  else
    Result := getPocetPredchozichPlatebNaStejnyVS() / PredchoziPlatbyList.Count;
end;


function TPlatbaZVypisu.getPocetPredchozichPlatebZeStejnehoUctu() : integer;
var
  i : integer;
begin
  Result := 0;
  if self.PredchoziPlatbyVsList.Count > 0 then
  begin
    for i := 0 to PredchoziPlatbyVsList.Count - 1 do
      if TPredchoziPlatba(self.PredchoziPlatbyVsList[i]).cisloUctu = self.cisloUctu then Inc(Result);
  end;
end;

function TPlatbaZVypisu.getProcentoPredchozichPlatebZeStejnehoUctu() : single;
begin
  if getPocetPredchozichPlatebZeStejnehoUctu() < 3 then
    Result := 0
  else
    Result := getPocetPredchozichPlatebZeStejnehoUctu() / PredchoziPlatbyVsList.Count;
end;

procedure TPlatbaZVypisu.setZnamyPripad(popis : string);
begin
  self.nazevKlienta := popis;
  self.znamyPripad := true;
end;

function TPlatbaZVypisu.isPayuProvize() : boolean;
begin
  if (self.kodUctovani = '1') //je to �ist� debet, nen� to storno kreditu
    AND (self.castka < 1000)
    AND (self.cisloUctuVlastni = '2389210008000000') then
    result := true
  else
    result := false;
end;

{** class TPredchoziPlatba **}

constructor TPredchoziPlatba.create(qrAbra : TZQuery);
begin
 with qrAbra do begin
  self.VS := RemoveSpaces(FieldByName('VarSymbol').AsString);
  self.Firm_ID := FieldByName('Firm_ID').AsString;
  self.castka := FieldByName('Amount').AsCurrency;
  self.cisloUctu := FieldByName('BankAccount').AsString;
  self.Datum := FieldByName('DocDate$Date').asFloat;
  self.FirmName := FieldByName('FirmName').AsString;

  self.cisloUctuKZobrazeni := DesU.prevedCisloUctuNaText(removeLeadingZeros(cisloUctu));

  if (FieldByName('Credit').AsString = 'N') then
    self.Castka := - self.Castka;

 end;
end;


end.
