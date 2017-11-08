program ReseniPNP;

uses
  Forms,
  PrirazeniPNP in '..\Vypisy\PrirazeniPNP.pas' {fmPrirazeniPnp},
  AbraEntities in '..\DE$_Common\AbraEntities.pas',
  DesUtils in '..\DE$_Common\DesUtils.pas' {DesU},
  Superdate in '..\DE$_Common\Superdate.pas',
  Superobject in '..\DE$_Common\Superobject.pas',
  Supertimezone in '..\DE$_Common\Supertimezone.pas',
  Supertypes in '..\DE$_Common\Supertypes.pas',
  AArray in '..\DE$_Common\AArray.pas',
  ParovaniGenLedger in 'ParovaniGenLedger.pas' {fmSparovaniVDeniku};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Vypisy';
  Application.CreateForm(TfmPrirazeniPnp, fmPrirazeniPnp);
  Application.CreateForm(TDesU, DesU);
  Application.CreateForm(TfmSparovaniVDeniku, fmSparovaniVDeniku);
  Application.Run;
end.
