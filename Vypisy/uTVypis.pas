unit uTVypis;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, IniFiles, Forms,
  Dialogs, StdCtrls, Grids, AdvObj, BaseGrid, AdvGrid, StrUtils,
  DB, ComObj, AdvEdit, DateUtils, Math, ExtCtrls,
  ZAbstractRODataset, ZAbstractDataset, ZDataset, ZAbstractConnection, ZConnection,
  uTPlatbaZVypisu, AbraEntities;

type

  TVypis = class
  private
    qrAbra: TZQuery;
  public
    Platby : TList;
    abraBankaccount : TAbraBankaccount;
    poradoveCislo : integer;
    cisloUctuVlastni : string[16];
    datum  : double;
    datumZHlavicky  : double;
    obratDebet  : currency;
    obratKredit  : currency;
    maxExistujiciPoradoveCislo : integer;
    maxExistujiciExtPoradoveCislo : integer;

    constructor create(gpcLine : string);
  published
    procedure init();
    procedure setridit();    
    procedure nactiMaxExistujiciPoradoveCislo();
    function isNavazujeNaRadu() : boolean;
    function prictiCastkuPokudDvojitaPlatba(pPlatbaZVypisu : TPlatbaZVypisu) : boolean;
  end;

implementation

uses
  DesUtils;

constructor TVypis.create(gpcLine : string);
begin
  self.qrAbra := DesU.qrAbra;
  self.Platby := TList.create;
  self.AbraBankAccount := TAbraBankaccount.Create;

  self.poradoveCislo := StrToInt(copy(gpcLine, 106, 3));
  self.cisloUctuVlastni := removeLeadingZeros(copy(gpcLine, 4, 16));
  self.obratDebet := StrToInt(copy(gpcLine, 76, 14)) / 100;
  self.obratKredit := StrToInt(copy(gpcLine, 91, 14)) / 100;
  self.datumZHlavicky := Str6digitsToDate(copy(gpcLine, 109, 6));
end;


function TVypis.isNavazujeNaRadu() : boolean;
begin
  if self.poradoveCislo - self.maxExistujiciPoradoveCislo = 1 then
    Result := true
  else
    Result := false;
end;

procedure TVypis.nactiMaxExistujiciPoradoveCislo();
begin
  with qrAbra do begin
    SQL.Text := 'SELECT bs1.OrdNumber as MaxOrdNumber, bs1.EXTERNALNUMBER as MaxExtOrdNumber'
              + ' FROM BANKSTATEMENTS bs1'
              + ' WHERE bs1.DOCQUEUE_ID = ''' + self.AbraBankAccount.bankStatementDocqueueId  + ''''
              + ' AND bs1.PERIOD_ID = (SELECT ID FROM PERIODS p WHERE p.DATEFROM$DATE <= ' + FloatToStr(self.datum)
              + ' AND p.DATETO$DATE > ' + FloatToStr(self.datum) + ')'
              + ' AND bs1.OrdNumber = (SELECT max(bs2.ORDNUMBER) FROM BANKSTATEMENTS bs2 WHERE bs1.DOCQUEUE_ID = bs2.DOCQUEUE_ID and bs1.PERIOD_ID = bs2.PERIOD_ID)';
    Open;
    if not Eof then begin
      self.maxExistujiciPoradoveCislo := FieldByName('MaxOrdNumber').AsInteger;
      self.maxExistujiciExtPoradoveCislo := FieldByName('MaxExtOrdNumber').AsInteger;
    end
    else begin
      self.maxExistujiciPoradoveCislo := 0;
      self.maxExistujiciExtPoradoveCislo := 0;
    end;
    Close;
  end;
end;


procedure TVypis.init();
var
  i : integer;
  iPlatba, payuProvizePP : TPlatbaZVypisu;
  payuProvize : currency;
begin

  self.abraBankaccount.loadByNumber(self.cisloUctuVlastni);

  self.datum := TPlatbaZVypisu(self.Platby[self.Platby.Count - 1]).Datum; //datum vypisy se urci jako datum poslední platby
  self.nactiMaxExistujiciPoradoveCislo();

  payuProvize := 0;
  for i := self.Platby.Count - 1 downto 0 do
  begin
    iPlatba := TPlatbaZVypisu(self.Platby[i]);

    // seèíst PayU provize
    if iPlatba.isPayuProvize then
    begin
      //payuProvizePP := iPlatba;
      payuProvize := payuProvize + iPlatba.castka;
      self.Platby.Delete(i);

    { nemelo by byt potreba, duplicita
    end
    // debety dozadu
    else if iPlatba.debet then
    begin
      self.Platby.Delete(i);
      self.Platby.Add(iPlatba);
      }
    end;
  end;

  if payuProvize > 0 then
  begin
    payuProvizePP := TPlatbaZVypisu.Create(-payuProvize);
    payuProvizePP.datum := self.datum;
    payuProvizePP.nazevKlienta := formatdatetime('myy', payuProvizePP.datum) + ' suma provize';
    self.Platby.Add(payuProvizePP);
  end;

end;

procedure TVypis.setridit();
var
  i : integer;
  iPlatba : TPlatbaZVypisu;

begin

  for i := self.Platby.Count - 1 downto 0 do
  begin
    iPlatba := TPlatbaZVypisu(self.Platby[i]);
    if (iPlatba.problemLevel = 2) AND (iPlatba.VS = iPlatba.VS_orig) then begin
      self.Platby.Delete(i);
      self.Platby.Add(iPlatba);
    end;
  end;

  for i := self.Platby.Count - 1 downto 0 do
  begin
    iPlatba := TPlatbaZVypisu(self.Platby[i]);
    if (iPlatba.problemLevel = 3) AND (iPlatba.VS = iPlatba.VS_orig) then begin
      self.Platby.Delete(i);
      self.Platby.Add(iPlatba);
    end;
  end;

  for i := self.Platby.Count - 1 downto 0 do
  begin
    iPlatba := TPlatbaZVypisu(self.Platby[i]);
    if (iPlatba.problemLevel = 1) AND (iPlatba.VS = iPlatba.VS_orig) then begin
      self.Platby.Delete(i);
      self.Platby.Add(iPlatba);
    end;
  end;

  for i := self.Platby.Count - 1 downto 0 do
  begin
    iPlatba := TPlatbaZVypisu(self.Platby[i]);
    if (iPlatba.problemLevel = 0) AND (iPlatba.VS = iPlatba.VS_orig) then begin
      self.Platby.Delete(i);
      self.Platby.Add(iPlatba);
    end;
  end;

  // debety dozadu
  for i := self.Platby.Count - 1 downto 0 do
  begin
    iPlatba := TPlatbaZVypisu(self.Platby[i]);
    if iPlatba.debet then begin
      self.Platby.Delete(i);
      self.Platby.Add(iPlatba);
    end;
  end;

end;

function TVypis.prictiCastkuPokudDvojitaPlatba(pPlatbaZVypisu : TPlatbaZVypisu) : boolean;
var
  i : integer;
  iPlatba : TPlatbaZVypisu;

begin
  Result := false;
  for i := self.Platby.Count - 1 downto 0 do
  begin
    iPlatba := TPlatbaZVypisu(self.Platby[i]);
    if (iPlatba.VS = pPlatbaZVypisu.VS) AND (iPlatba.cisloUctu = pPlatbaZVypisu.cisloUctu)
      AND (iPlatba.kredit = true) AND (iPlatba.znamyPripad = false)
      AND (pPlatbaZVypisu.kredit = true) AND (pPlatbaZVypisu.znamyPripad = false)
    then begin
      iPlatba.castka := iPlatba.castka + pPlatbaZVypisu.castka;
      Result := true;
      exit;
    end;
  end;
end;



end.
