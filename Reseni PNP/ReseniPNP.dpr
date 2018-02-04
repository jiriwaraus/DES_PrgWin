program ReseniPNP;

uses
  Forms,
  AbraEntities in '..\DE$_Common\AbraEntities.pas',
  DesUtils in '..\DE$_Common\DesUtils.pas' {DesU},
  Superdate in '..\DE$_Common\Superdate.pas',
  Superobject in '..\DE$_Common\Superobject.pas',
  Supertimezone in '..\DE$_Common\Supertimezone.pas',
  Supertypes in '..\DE$_Common\Supertypes.pas',
  AArray in '..\DE$_Common\AArray.pas',
  ParovaniGenLedger in 'ParovaniGenLedger.pas' {fmSparovaniVDeniku},
  PrirazeniPNP in 'PrirazeniPNP.pas' {fmPrirazeniPnp};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Vypisy';
  Application.CreateForm(TDesU, DesU);
  Application.CreateForm(TfmSparovaniVDeniku, fmSparovaniVDeniku);
  Application.CreateForm(TfmPrirazeniPnp, fmPrirazeniPnp);
  Application.Run;
end.
