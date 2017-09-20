program NezaplaceneFO;

uses
  Forms,
  NF in 'NF.pas' {fmMain},
  NF2D in 'NF2D.pas' {fmDetail},
  DesUtils in '..\DE$_Common\DesUtils.pas' {DesU},
  AArray in '..\DE$_Common\AArray.pas',
  Superdate in '..\DE$_Common\Superdate.pas',
  Superobject in '..\DE$_Common\Superobject.pas',
  Supertimezone in '..\DE$_Common\Supertimezone.pas',
  Supertypes in '..\DE$_Common\Supertypes.pas',
  AbraEntities in '..\DE$_Common\AbraEntities.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TfmDetail, fmDetail);
  Application.CreateForm(TDesU, DesU);
  Application.Run;
end.
