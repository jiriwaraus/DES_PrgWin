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
    procedure btnGetClick(Sender: TObject);
    procedure btnPostClick(Sender: TObject);
    procedure btnPutClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


implementation

{$R *.dfm}

uses DesUtils, Superobject;


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
  '"description": "pøipojení, 2018020612",'+
  '"accdate$date": "2017-05-30",'+
  '"varsymbol": "2014020777",'+
  '"priceswithvat": true,'+

  '"rows": ['+
  '  {'+
  '    "totalprice": 631.5,'+
  '    "division_id": "1000000101",'+
  '    "busorder_id": "9D00000101",'+
  '    "bustransaction_id": "3L00000101",'+
  '    "text": "podle smlouvy  2019020777  službu  5AA-Optimal",'+
  '    "vatrate_id": "02100X0000",'+
  '    "rowtype": 1,'+
  '    "incometype_id": "2000000000",'+
  '  }'+
  ']'+
  '}';

  memo1.Lines.Add(Json);

  sResponse := DesU.abraBoCreate(editUrl.Text, SO(Json));

  memo2.Lines.Add (SO(sResponse).AsJSon(True));

  memo2.Lines.Add(sResponse);
end;


procedure TForm1.btnPutClick(Sender: TObject);
var
  sResponse: string;
  Json: string;
  JsonSO: ISuperObject;
begin

  editUrl.Text := 'bankstatements/36E2000101/rows/5BRD000101';

  JsonSO := SO;
  JsonSO.S['varsymbol'] := '6378';

  Json := JsonSO.AsJSon(true);
  memo1.Lines.Add(Json);

  sResponse := DesU.abraBoUpdate('bankstatement', '36E2000101', 'row', '5BRD000101', SO(Json));

  memo2.Lines.Add (SO(sResponse).AsJSon(true));

  //memo2.Lines.Add(sResponse);
end;


end.
