program Vypisy;

uses
  Forms,
  VypisyMain in 'VypisyMain.pas' {fmMain},
  uTVypis in 'uTVypis.pas',
  uTPlatbaZVypisu in 'uTPlatbaZVypisu.pas',
  uTParovatko in 'uTParovatko.pas',
  PrirazeniPNP in 'PrirazeniPNP.pas' {fmPrirazeniPnp},
  Customers in 'Customers.pas' {fmCustomers},
  AbraEntities in '..\DE$_Common\AbraEntities.pas',
  DesUtils in '..\DE$_Common\DesUtils.pas' {DesU},
  Superdate in '..\DE$_Common\Superdate.pas',
  Superobject in '..\DE$_Common\Superobject.pas',
  Supertimezone in '..\DE$_Common\Supertimezone.pas',
  Supertypes in '..\DE$_Common\Supertypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Vypisy';
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TfmPrirazeniPnp, fmPrirazeniPnp);
  Application.CreateForm(TfmCustomers, fmCustomers);
  Application.CreateForm(TDesU, DesU);
  Application.Run;
end.
