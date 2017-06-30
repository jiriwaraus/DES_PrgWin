unit uTParovatko;

interface

uses
  SysUtils, Variants, Classes, Controls, StrUtils,
  Windows, Messages, Dialogs, Forms,
  ZAbstractRODataset, ZAbstractDataset, ZDataset, ZAbstractConnection, ZConnection,  
  uTVypis, uTPlatbaZVypisu, AbraEntities;


type

  TPlatbaDokladPar = class
  public
    Platba : TPlatbaZVypisu;
    Doklad : TDoklad;
    Doklad_ID : string[10];
    CastkaPouzita : currency;
    Popis : string;
    vazbaNaDoklad : boolean;
  end;

  TParovatko = class
  public
    Vypis: TVypis;
    qrAbra: TZQuery;
    AbraOLE: variant;
    listPlatbaDokladPar : TList;//<TPlatbaDokladPar>;
    constructor create(Vypis: TVypis);
  published
    procedure sparujPlatbu(Platba : TPlatbaZVypisu);
    procedure odparujPlatbu(currPlatba : TPlatbaZVypisu);
    procedure vytvorPDPar(Platba : TPlatbaZVypisu; Doklad : TDoklad;
                Castka: currency; popis : string; vazbaNaDoklad : boolean);
    function zapisDoAbry() : string;
    function zapisDoAbryOLE_naprimo() : string;
    function zapisDoAbry_AA() : string;
    function getUzSparovano(Doklad_ID : string) : currency;
    function getPDParyAsText() : AnsiString;
    function getPDParyPlatbyAsText(currPlatba : TPlatbaZVypisu) : AnsiString;
    function getPDPar(currPlatba : TPlatbaZVypisu; currDoklad_ID: string) : TPlatbaDokladPar;
  end;




implementation

uses
  DesUtils, AArray, Superobject;


constructor TParovatko.create(Vypis: TVypis);
begin
  self.qrAbra := DesU.qrAbra;
  //self.AbraOLE := DesU.getAbraOLE;
  self.Vypis := Vypis;
  self.listPlatbaDokladPar := TList.Create();
end;


procedure TParovatko.sparujPlatbu(Platba : TPlatbaZVypisu);
var
  i : integer;
  nezaplaceneDoklady : TList;
  iDoklad : TDoklad;
  zbyvaCastka,
  kNaparovani : currency;
begin

  iDoklad := nil;
  Platba.rozdeleniPlatby := 0;
  Platba.castecnaUhrada := 0;

  self.odparujPlatbu(Platba); //není vlastnì už potøeba, protože vždy párujeme nanovo všechny Platby od zaèátku do konce

  if Platba.DokladyList.Count > 0 then
    iDoklad := TDoklad(Platba.DokladyList[0]); //pokud je alespon 1 doklad, priradime si ho pro debety a kredity bez nezaplacenych dokladu

  if Platba.debet then
  begin //platba je debet
      Platba.zprava := 'debet';
      Platba.problemLevel := 0;
      vytvorPDPar(Platba, iDoklad, Platba.Castka, '', false);
  end   // end platba je debet
  else

  begin //platba je kredit

    if Platba.isVoipKredit then
    begin
      vytvorPDPar(Platba, nil, Platba.Castka, '', false);
      Platba.zprava := 'VoIP kredit';
      Platba.problemLevel := 3;
      Exit;
    end;



    // vyrobím si list jen nezaplacených dokladù
    nezaplaceneDoklady := TList.Create;
    for i := 0 to Platba.DokladyList.Count - 1 do
      if TDoklad(Platba.DokladyList[i]).CastkaNezaplaceno <> 0 then
        nezaplaceneDoklady.Add(Platba.DokladyList[i]);

    if (nezaplaceneDoklady.Count = 0) then
    begin
      if Platba.znamyPripad then
      begin
        vytvorPDPar(Platba, iDoklad, Platba.Castka, '', false);
        Platba.zprava := 'známý kredit';
        Platba.problemLevel := 0;
      end
      else
      begin
        if Platba.getProcentoPredchozichPlatebZeStejnehoUctu() > 0.5 then begin
          vytvorPDPar(Platba, iDoklad, Platba.Castka, 'pøepl. | ' + Platba.VS + ' |', false);
          Platba.zprava := 'známý pøep. ' + FloatToStr(Platba.Castka) + ' Kè';
          Platba.problemLevel := 1;
        end else begin
          vytvorPDPar(Platba, iDoklad, Platba.Castka, 'pøepl. | ' + Platba.VS + ' |', false);
          Platba.zprava := 'neznámý pøep. ' + FloatToStr(Platba.Castka) + ' Kè';
          Platba.problemLevel := 5;
        end;
      end;
      Exit;
    end;


    zbyvaCastka := Platba.Castka;

    for i := nezaplaceneDoklady.Count - 1 downto 0 do
    // begin existují nezaplacené doklady
    begin
      iDoklad := TDoklad(nezaplaceneDoklady[i]);
      kNaparovani := iDoklad.CastkaNezaplaceno - getUzSparovano(iDoklad.ID);

      if (kNaparovani <> 0) then
      begin
        if (kNaparovani = zbyvaCastka) then
        begin
          vytvorPDPar(Platba, iDoklad, zbyvaCastka, '', true); //pøesnì |
          Platba.zprava := 'pøesnì';
          if Platba.rozdeleniPlatby > 0 then
            Platba.problemLevel := 0 //bylo 1
          else
            Platba.problemLevel := 0;
          zbyvaCastka := 0;
          Break;
        end;

        if (kNaparovani > zbyvaCastka) AND not(iDoklad.DocumentType = '10') then
        begin
          vytvorPDPar(Platba, iDoklad, zbyvaCastka, 'èást. ' + floattostr(zbyvaCastka) + ' z ' + floattostr(kNaparovani) + ' Kè |', true);
          Platba.zprava := 'èásteèná úhrada';
          Platba.castecnaUhrada := 1;
          Platba.problemLevel := 1;
          zbyvaCastka := 0;
          Break;
        end;

        if (kNaparovani < zbyvaCastka) then
        begin
          vytvorPDPar(Platba, iDoklad, kNaparovani, '', true); //pøesnì (rozpad) |
          zbyvaCastka := zbyvaCastka - kNaparovani;
          Inc(Platba.rozdeleniPlatby);
        end;
      end;
    end;
    // end existují nezaplacené doklady

    if (zbyvaCastka > 0) then
    begin
      vytvorPDPar(Platba, iDoklad, zbyvaCastka, 'pøepl. | ' + Platba.VS + ' |' , false);
      Platba.zprava := 'pøepl. ' + FloatToStr(zbyvaCastka) + ' Kè';
      Platba.problemLevel := 1;
    end;

    if (Platba.getPocetPredchozichPlatebZeStejnehoUctu() = 0)
      AND (Platba.PredchoziPlatbyVsList.Count > 3) then
    begin
      Platba.zprava := 'nový/neznámý úèet - ' + Platba.zprava;
      Platba.problemLevel := 2;
    end;

  end;
  // end platba je kredit

end;


procedure TParovatko.odparujPlatbu(currPlatba : TPlatbaZVypisu);
var
  i : integer;
  iPDPar : TPlatbaDokladPar;
begin

  for i := listPlatbaDokladPar.Count - 1 downto 0 do
  begin
    iPDPar := TPlatbaDokladPar(listPlatbaDokladPar[i]);
    if iPDPar.Platba = currPlatba then
      listPlatbaDokladPar.Delete(i);
  end;
end;


procedure TParovatko.vytvorPDPar(Platba : TPlatbaZVypisu; Doklad : TDoklad;
            Castka: currency; popis : string; vazbaNaDoklad : boolean);
var
  iPDPar : TPlatbaDokladPar;
begin
  iPDPar := TPlatbaDokladPar.Create();
  iPDPar.Platba := Platba;
  iPDPar.Doklad := Doklad;
  if assigned(iPDPar.Doklad) then
    iPDPar.Doklad_ID := iPDPar.Doklad.ID
  else
    iPDPar.Doklad_ID := '';
  iPDPar.CastkaPouzita := Castka;
  iPDPar.Popis := Popis;
  iPDPar.vazbaNaDoklad := vazbaNaDoklad;
  self.listPlatbaDokladPar.Add(iPDPar);
end;

function TParovatko.zapisDoAbry() : string;
begin
  //Result := self.zapisDoAbryOLE_naprimo();
  Result := self.zapisDoAbry_AA();
end;


function TParovatko.zapisDoAbryOLE_naprimo() : string;
var
  i, j : integer;
  iPDPar : TPlatbaDokladPar;
  BStatement_Object,
  BStatement_Data,
  BStatementRow_Object,
  BStatementRow_Data,
  BStatement_Data_Coll,
  NewID : variant;
  faZaVoipKreditId : string;
begin

  if (listPlatbaDokladPar.Count = 0) then Exit;

  Result := 'Zápis pomocí ABRA OLE výpisu pro úèet ' + self.Vypis.abraBankaccount.name + '.';

  AbraOLE := DesU.getAbraOLE;

  BStatement_Object:= AbraOLE.CreateObject('@BankStatement');
  BStatement_Data:= AbraOLE.CreateValues('@BankStatement');
  BStatement_Object.PrefillValues(BStatement_Data);
  BStatement_Data.ValueByName('DocQueue_ID') := self.Vypis.abraBankaccount.bankStatementDocqueueId;
  BStatement_Data.ValueByName('Period_ID') := DesU.getAbraPeriodId(self.Vypis.Datum);
  BStatement_Data.ValueByName('BankAccount_ID') := self.Vypis.abraBankaccount.id;
  BStatement_Data.ValueByName('ExternalNumber') := self.Vypis.PoradoveCislo;
  BStatement_Data.ValueByName('DocDate$DATE') := self.Vypis.Datum;
  BStatement_Data.ValueByName('CreatedAt$DATE') := IntToStr(Trunc(Date));

  BStatementRow_Object := AbraOLE.CreateObject('@BankStatementRow');
  BStatement_Data_Coll := BStatement_Data.Value[IndexByName(BStatement_Data, 'Rows')];

  for i := 0 to listPlatbaDokladPar.Count - 1 do
  begin
    iPDPar := TPlatbaDokladPar(listPlatbaDokladPar[i]);

    BStatementRow_Data := AbraOLE.CreateValues('@BankStatementRow');
    BStatementRow_Object.PrefillValues(BStatementRow_Data);
    BStatementRow_Data.ValueByName('Amount') := iPDPar.CastkaPouzita;
    BStatementRow_Data.ValueByName('Credit') := IfThen(iPDPar.Platba.Kredit,'1','0');
    BStatementRow_Data.ValueByName('BankAccount') := iPDPar.Platba.cisloUctu;
    BStatementRow_Data.ValueByName('Text') := Trim(iPDPar.popis + ' ' + iPDPar.Platba.nazevKlienta);
    BStatementRow_Data.ValueByName('SpecSymbol') := iPDPar.Platba.SS;
    BStatementRow_Data.ValueByName('DocDate$DATE') := iPDPar.Platba.Datum;
    BStatementRow_Data.ValueByName('AccDate$DATE') := iPDPar.Platba.Datum;


    if Assigned(iPDPar.Doklad) then
      if iPDPar.vazbaNaDoklad then //Doklad vyplnime jen pokud chceme vazbu (vazbaNaDoklad je true). Doklad máme naètený i v situaci kdy vazbu nechceme - kvùli Firm_ID
      begin
        BStatementRow_Data.ValueByName('PDocumentType') := iPDPar.Doklad.DocumentType;
        BStatementRow_Data.ValueByName('PDocument_ID') := iPDPar.Doklad.ID;
      end
      else
      begin
        BStatementRow_Data.ValueByName('Firm_ID') := iPDPar.Doklad.Firm_ID;
      end
    else //není Assigned(iPDPar.Doklad)
      if not(iPDPar.Platba.isVoipKredit) then
        BStatementRow_Data.ValueByName('Firm_ID') := '3Y90000101'; //a je firma DES. jinak se tam dá jako default "drobný nákup" then


    {
    pøepsal jsem logiku viz výše
    if Assigned(iPDPar.Doklad) AND not(iPDPar.vazbaNaDoklad) then //pokud necheme vazvu na konkrétní doklad (vazbaNaDoklad), tak jen vyplníme Firm_id
      BStatementRow_Data.ValueByName('Firm_ID') := iPDPar.Doklad.Firm_ID

    if not(Assigned(iPDPar.Doklad)) AND not(iPDPar.Platba.isVoipKredit) then
      BStatementRow_Data.ValueByName('Firm_ID') := '3Y90000101'; //a je firma DES. jinak se tam dá jako default "drobný nákup"

    if Assigned(iPDPar.Doklad) AND iPDPar.vazbaNaDoklad then //Doklad vyplnime jen pokud chceme vazbu (vazbaNaDoklad je true). Doklad máme naètený i v situaci kdy vazbu nechceme - kvùli Firm_ID
    begin
      BStatementRow_Data.ValueByName('PDocumentType') := iPDPar.Doklad.DocumentType;
      BStatementRow_Data.ValueByName('PDocument_ID') := iPDPar.Doklad.ID;
    end;
    }

    if iPDPar.Platba.isVoipKredit then
    begin
      faZaVoipKreditId := DesU.vytvorFaZaVoipKredit(iPDPar.Platba.VS, iPDPar.CastkaPouzita, iPDPar.Platba.Datum);
      if faZaVoipKreditId = '' then
        //pokud nenajdeme podle VS firmu, zapíšeme VS
        BStatementRow_Data.ValueByName('VarSymbol') := iPDPar.Platba.VS
      else begin
        //pokud jsme firmu našli, byla pro ni vytvoøena fa a tu teï pøipojíme. VS abra automaticky doplní
        BStatementRow_Data.ValueByName('PDocumentType') := '03'; // je to vždy faktura
        BStatementRow_Data.ValueByName('PDocument_ID') := faZaVoipKreditId;
      end;

    end;

    if iPDPar.Platba.Debet then
      BStatementRow_Data.ValueByName('VarSymbol') := iPDPar.Platba.VS; //pro debety aby vždy zùstal VS

    BStatement_Data_Coll.Add(BStatementRow_Data);

    //MessageDlg(DesU.getOleObjDataDisplay(BStatementRow_Data), mtInformation, [mbOk], 0);
    //writeToFile(DesU.PROGRAM_PATH + '!OLE'+inttostr(i)+'.txt', DesU.getOleObjDataDisplay(BStatementRow_Data));
  end;

  try begin
    NewID := BStatement_Object.CreateNewFromValues(BStatement_Data); //NewID je ID Abry v BANKSTATEMENTS
    Result := Result + ' Èíslo výpisu je ' + NewID;
  end;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Problem ' + ^M + E.Message), 'AbraOLE');
      Result := 'Chyba pøi zakládání výpisu';
    end;
  end;

  DesU.abraOLELogout;

end;


function TParovatko.zapisDoAbry_AA() : string;
var
  i, j : integer;
  iPDPar : TPlatbaDokladPar;
  boAA, boRowAA: TAArray;
  newID, faZaVoipKreditId : string;
begin

  if (listPlatbaDokladPar.Count = 0) then Exit;

  Result := 'Zápis pomocí AArray metoda ' +  DesU.abraDefaultCommMethod + ' výpisu pro úèet ' + self.Vypis.abraBankaccount.name + '.';



  boAA := TAArray.Create;
  boAA['DocQueue_ID'] := self.Vypis.abraBankaccount.bankStatementDocqueueId;
  boAA['Period_ID'] := DesU.getAbraPeriodId(self.Vypis.Datum);
  boAA['BankAccount_ID'] := self.Vypis.abraBankaccount.id;
  boAA['ExternalNumber'] := self.Vypis.PoradoveCislo;
  boAA['DocDate$DATE'] := self.Vypis.Datum;
  //boAA['CreatedAt$DATE'] := IntToStr(Trunc(Date));


  for i := 0 to listPlatbaDokladPar.Count - 1 do
  begin
    iPDPar := TPlatbaDokladPar(listPlatbaDokladPar[i]);

    boRowAA := boAA.addRow();
    boRowAA['Amount'] := iPDPar.CastkaPouzita;
    boRowAA['Credit'] := IfThen(iPDPar.Platba.Kredit,'1','0');
    boRowAA['BankAccount'] := iPDPar.Platba.cisloUctu;
    boRowAA['Text'] := Trim(iPDPar.popis + ' ' + iPDPar.Platba.nazevKlienta);
    boRowAA['SpecSymbol'] := iPDPar.Platba.SS;
    boRowAA['DocDate$DATE'] := iPDPar.Platba.Datum;
    boRowAA['AccDate$DATE'] := iPDPar.Platba.Datum;


    if Assigned(iPDPar.Doklad) then
      if iPDPar.vazbaNaDoklad then //Doklad vyplnime jen pokud chceme vazbu (vazbaNaDoklad je true). Doklad máme naètený i v situaci kdy vazbu nechceme - kvùli Firm_ID
      begin
        boRowAA['PDocumentType'] := iPDPar.Doklad.DocumentType;
        boRowAA['PDocument_ID'] := iPDPar.Doklad.ID;
      end
      else
      begin
        boRowAA['Firm_ID'] := iPDPar.Doklad.Firm_ID;
      end
    else //není Assigned(iPDPar.Doklad)
      if not(iPDPar.Platba.isVoipKredit) then
        boRowAA['Firm_ID'] := '3Y90000101'; //a je firma DES. jinak se tam dá jako default "drobný nákup" then


    if iPDPar.Platba.isVoipKredit then
    begin
      faZaVoipKreditId := DesU.vytvorFaZaVoipKredit(iPDPar.Platba.VS, iPDPar.CastkaPouzita, iPDPar.Platba.Datum);
      if faZaVoipKreditId = '' then
        //pokud nenajdeme podle VS firmu, zapíšeme VS
        boRowAA['VarSymbol'] := iPDPar.Platba.VS
      else begin
        //pokud jsme firmu našli, byla pro ni vytvoøena fa a tu teï pøipojíme. VS abra automaticky doplní
        boRowAA['PDocumentType'] := '03'; // je to vždy faktura
        boRowAA['PDocument_ID'] := faZaVoipKreditId;
      end;

    end;

    if iPDPar.Platba.Debet then
      boRowAA['VarSymbol'] := iPDPar.Platba.VS; //pro debety aby vždy zùstal VS

  end;

  try begin
    newId := DesU.abraBoCreate(boAA, 'bankstatement');
    Result := Result + ' Èíslo nového výpisu je ' + newID;
    DesU.abraOLELogout;
  end;
  except on E: exception do
    begin
      Application.MessageBox(PChar('Problem ' + ^M + E.Message), 'Vytváøení výpisu');
      Result := 'Chyba pøi vytváøení výpisu';
    end;
  end;

end;


function TParovatko.getUzSparovano(Doklad_ID : string) : currency;
var
  i : integer;
  iPDPar : TPlatbaDokladPar;
begin
  Result := 0;

  if listPlatbaDokladPar.Count > 0 then
    for i := 0 to listPlatbaDokladPar.Count - 1 do
    begin
      iPDPar := TPlatbaDokladPar(listPlatbaDokladPar[i]);
      if Assigned(iPDPar.Doklad) AND (iPDPar.vazbaNaDoklad) then
        if (iPDPar.Doklad.ID = Doklad_ID)  then
          Result := Result + iPDPar.CastkaPouzita;
    end;
end;


function TParovatko.getPDParyAsText() : AnsiString;
var
  i : integer;
  iPDPar : TPlatbaDokladPar;
begin
  Result := '';

  if listPlatbaDokladPar.Count = 0 then exit;

  for i := 0 to listPlatbaDokladPar.Count - 1 do
  begin
    iPDPar := TPlatbaDokladPar(listPlatbaDokladPar[i]);
    Result := Result + 'VS: ' + iPDPar.Platba.VS + ' ';
    if iPDPar.vazbaNaDoklad AND Assigned(iPDPar.Doklad) then
      Result := Result + 'Na doklad ' + iPDPar.Doklad.ID + ' napárováno ' + FloatToStr(iPDPar.CastkaPouzita) + ' Kè ';
    Result := Result + ' | ' + iPDPar.Popis + sLineBreak;
  end;
end;

function TParovatko.getPDParyPlatbyAsText(currPlatba : TPlatbaZVypisu) : AnsiString;
var
  i : integer;
  iPDPar : TPlatbaDokladPar;
begin
  Result := '';
  if listPlatbaDokladPar.Count = 0 then exit;

  for i := 0 to listPlatbaDokladPar.Count - 1 do
  begin
    iPDPar := TPlatbaDokladPar(listPlatbaDokladPar[i]);
    if iPDPar.Platba = currPlatba then begin
      Result := Result + 'VS: ' + iPDPar.Platba.VS + ' ';
      if iPDPar.vazbaNaDoklad AND Assigned(iPDPar.Doklad) then
        Result := Result + 'Na doklad ' + iPDPar.Doklad.ID + ' napárováno ' + FloatToStr(iPDPar.CastkaPouzita) + ' Kè ';
      Result := Result + ' | ' + iPDPar.Popis + sLineBreak;
    end;
  end;
end;


function TParovatko.getPDPar(currPlatba : TPlatbaZVypisu; currDoklad_ID: string) : TPlatbaDokladPar;
var
  i : integer;
  iPDPar : TPlatbaDokladPar;
begin
  Result := nil;
  if listPlatbaDokladPar.Count = 0 then exit;

  for i := 0 to listPlatbaDokladPar.Count - 1 do
  begin
    iPDPar := TPlatbaDokladPar(listPlatbaDokladPar[i]);
    if (iPDPar.Platba = currPlatba) and (iPDPar.Doklad_ID = currDoklad_ID) and
    (iPDPar.vazbaNaDoklad) then
      Result := iPDPar;
  end;
end;


end.
