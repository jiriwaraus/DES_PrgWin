unit AbraWebAPI_demo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    btnGet: TButton;
    Memo1: TMemo;
    Memo2: TMemo;
    btnPost: TButton;
    btnPut: TButton;
    editUrl: TEdit;
    lblUrl: TLabel;
    lblReqData: TLabel;
    Memo3: TMemo;
    btnArrayTest1: TButton;
    btnPutAa: TButton;
    Button1: TButton;
    procedure btnGetClick(Sender: TObject);
    procedure btnPostClick(Sender: TObject);
    procedure btnPutClick(Sender: TObject);
    procedure btnArrayTest1Click(Sender: TObject);
    procedure btnPutAaClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


implementation

{$R *.dfm}

uses DesUtils, Superobject, AArray;


procedure TForm1.btnArrayTest1Click(Sender: TObject);
var
  FruitColors: TAArray;
  boAA, boRowAA: TAArray;
  TestString, newid: String;
  i: integer;
begin

  boAA := TAArray.Create;

  boAA['docqueue_id'] := DesU.getAbraDocqueueId('FO1', '03');
  boAA['period_id'] := DesU.getAbraPeriodId('2017');
  boAA['docdate$date'] := '2017-06-28';
  boAA['accdate$date'] := '2017-06-30';
  boAA['firm_id'] := '2SZ1000101';
  boAA['varsymbol'] := '911123335';
  boAA['description'] := 'pppp�ipojen� rychlou�k� b��';
  boAA['priceswithvat'] := true;


  boRowAA := boAA.addRow();
  boRowAA['rowtype'] := 0;
  boRowAA['text'] := 'prvni radek fakturujeme';
  boRowAA['division_id'] := '1000000101';


  boRowAA := boAA.addRow();
  boRowAA['rowtype'] := 1;
  boRowAA['text'] := 'Za na�e sv�l� Slu�by';
  boRowAA['totalprice'] := 246;
  boRowAA['vatrate_id'] := DesU.getAbraVatrateId('V�st21');;
  boRowAA['incometype_id'] := DesU.getAbraIncometypeId('SL');
  boRowAA['division_id'] := '1000000101';


  newid := DesU.abraBoCreateOLE(boAA, 'issuedinvoice');
  //newid := DesU.abraBoCreateWebApi(boAA, 'issuedinvoice');

  memo2.Lines.Add(newid);
  {
  FruitColors := TAArray.Create;
  FruitColors['Apple'] := 'Green';
  FruitColors['Peach'] := 'bbla'; //TRUE;
  FruitColors['Some Fruit'] := 'ctrnact'; //14;

  memo2.Lines.Add('Position=' + inttostr(FruitColors.Position) + ' Count=' + inttostr(FruitColors.Count) );

  for i := 0 to FruitColors.Count - 1 do
    memo2.Lines.Add(FruitColors.Values[i]);
  }
  {
  if FruitColors['Peach'] then
    memo2.Lines.Add('ttttttttttt')
  else
      memo2.Lines.Add('ffffffffff');
  while FruitColors.Foreach do
  begin
    TestString := FruitColors.Value[FruitColors.Position];
    memo2.Lines.Add(FruitColors[FruitColors.Position]);
  end;
  }

end;

procedure TForm1.btnGetClick(Sender: TObject);
var
  sResponse: string;
  MyObject: ISuperObject;
  mySuperArray: TSuperAvlEntry;
  item: ISuperObject;
begin
  //editUrl.Text := 'periods?where=code+gt+2015';
  editUrl.Text := 'bankstatements/36E2000101';

  sResponse := DesU.abraBoGet(editUrl.Text);

  memo2.Lines.Add(sResponse);

  MyObject := SO(sResponse);
  memo2.Lines.Add (MyObject.AsJSon(True));
  memo2.Lines.Add (MyObject.AsArray[0].AsString);
  memo2.Lines.Add (MyObject.AsArray[0].AsObject.S['name']);

  for item in MyObject do
    memo2.Lines.Add (item.AsObject.S['name']);

  //hodnota := MyObject.S['last'];
  //hodnota := SO(Mydata).S['last'];  //zkracena verze
end;

procedure TForm1.btnPostClick(Sender: TObject);
var
  sResponse: string;
  Json: string;
begin

editUrl.Text := 'issuedinvoice';

Json := '{'+
  '"docqueue_id": "L000000101",'+
  '"period_id": "1L20000101",'+
  '"docdate$date": "2017-06-04",'+
  '"firm_id": "2SZ1000101",'+
  '"description": "pppp�ipojen�, 2018020612",'+
  '"accdate$date": "2017-05-30",'+
  '"varsymbol": "2014020777",'+
  '"priceswithvat": true,'+

  '"rows": ['+
  '  {'+
  '    "totalprice": 3881.5,'+
  '    "division_id": "1000000101",'+
  '    "busorder_id": "9D00000101",'+
  '    "bustransaction_id": "3L00000101",'+
  '    "text": "podle smlouvy  2019020777  slu�bu  5AA-Optimal",'+
  '    "vatrate_id": "02100X0000",'+
  '    "rowtype": 1,'+
  '    "incometype_id": "2000000000",'+
  '  }'+
  ']'+
  '}';

  memo1.Lines.Add(Json);

  sResponse := DesU.abraBoCreate_So(SO(Json), editUrl.Text);

  memo2.Lines.Add (SO(sResponse).AsJSon(True));

  memo2.Lines.Add(sResponse);
end;


procedure TForm1.btnPutAaClick(Sender: TObject);
var
  boAA: TAArray;
  sResponse, newid: String;
begin

  boAA := TAArray.Create;
  boAA['varsymbol'] := '77989';
  sResponse := DesU.abraBoUpdate(boAA, 'bankstatement', '36E2000101', 'row', '5BRD000101');

  memo2.Lines.Add (boAA.AsJSon());
  memo2.Lines.Add ('-------');
  // memo2.Lines.Add (sResponse);
  //memo2.Lines.Add ('-------');
  memo2.Lines.Add (SO(sResponse).AsJSon(true));


end;

procedure TForm1.btnPutClick(Sender: TObject);
var
  sResponse: string;
  Json: string;
  JsonSO: ISuperObject;
begin

  //editUrl.Text := 'bankstatements/36E2000101/rows/5BRD000101';

  JsonSO := SO;
  JsonSO.S['varsymbol'] := '1116378';
  Json := JsonSO.AsJSon(true);
  memo1.Lines.Add(Json);
  sResponse := DesU.abraBoUpdate_So(SO(Json), 'bankstatement', '36E2000101', 'row', '5BRD000101');
  memo2.Lines.Add (SO(sResponse).AsJSon(true));




end;


procedure TForm1.Button1Click(Sender: TObject);
var


  boAA, boRowAA: TAArray;
  TestString, newid: String;
  i: integer;
begin
  {
  boAA := TAArray.Create;
  boAA['DocQueue_ID'] := 'L000000101';
  boAA['Period_ID'] := 20117;
  boAA['VatDate$DATE'] := '2017-06-04';
  boAA['DocDate$DATE'] := 45665;
  boAA['Firm_ID'] := 'id firmy "nejlep��" firma';
  //jsonBo.S['Firm_ID'] :='2SZ1000101';
  boAA['Description'] := 'Kredit VoIP';
  boAA['Varsymbol'] := 1200025;
  boAA['PricesWithVat'] := true;


  // 1. ��dek
  boRowAA := boAA.addRow();
  boRowAA['Rowtype'] := 0;
  boRowAA['Text'] := ' ';


 //2. ��dek
  boRowAA := boAA.addRow();
  boRowAA['Rowtype'] := 1;
  boRowAA['Totalprice'] := 12556.32;
  boRowAA['Text'] := 'Kredit �lu�ou�k� VoIP';
  }

  boAA := TAArray.Create;
  boAA['DocQueue_ID'] := '5600000101';
  //boAA['Period_ID'] := 20117;
  boAA['VatDate$DATE'] := '2017-06-04';
  boAA['DocDate$DATE'] := '2017-06-05';
  boAA['Firm_ID'] := '3000000101';
  boAA['Description'] := 'nnn sluzby';
  boAA['Varsymbol'] := 1200025;
  boAA['PricesWithVat'] := true;


  // 1. ��dek
  boRowAA := boAA.addRow();
  boRowAA['Rowtype'] := 1;
  boRowAA['Totalprice'] := 1320;
  boRowAA['Text'] := 'fakturujume nnn sluzby';
  boRowAA['Division_id'] := '2100000101';
  boRowAA['Vatrate_Id'] := '02100X0000';



  memo2.Lines.Add (boAA.AsJSon());
  memo2.Lines.Add ('Metoda zapisu: ' + DesU.abraDefaultCommMethod);


  newid := DesU.abraBoCreate(boAA, 'issuedinvoice');

  memo2.Lines.Add(newid);

end;









end.
