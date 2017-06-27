program AbraCommDemo;

uses
  Vcl.Forms,
  AbraWebAPI_demo in 'AbraWebAPI_demo.pas' {Form1},
  DesUtils in '..\DE$_Common\DesUtils.pas' {DesU},
  Superobject in '..\DE$_Common\Superobject.pas',
  Superdate in '..\DE$_Common\Superdate.pas',
  Supertimezone in '..\DE$_Common\Supertimezone.pas',
  Supertypes in '..\DE$_Common\Supertypes.pas',
  AbraEntities in '..\DE$_Common\AbraEntities.pas',
  _Arrays in '..\DE$_Common\_Arrays.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TDesU, DesU);
  Application.Run;
end.
