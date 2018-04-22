program MesicniFakturace;

uses
  Forms,
  AArray in '..\DE$_Common\AArray.pas',
  AbraEntities in '..\DE$_Common\AbraEntities.pas',
  DesUtils in '..\DE$_Common\DesUtils.pas' {DesU},
  Superdate in '..\DE$_Common\Superdate.pas',
  Superobject in '..\DE$_Common\Superobject.pas',
  Supertimezone in '..\DE$_Common\Supertimezone.pas',
  Supertypes in '..\DE$_Common\Supertypes.pas',
  FIcommon in 'FIcommon.pas' {dmCommon: TDataModule},
  FIfaktura in 'FIfaktura.pas' {dmFaktura: TDataModule},
  FIlogin in 'FIlogin.pas' {fmLogin},
  FImail in 'FImail.pas' {dmMail: TDataModule},
  FIprevod in 'FIprevod.pas' {dmPrevod: TDataModule},
  FItisk in 'FItisk.pas' {dmTisk: TDataModule},
  frxExportSynPDF in 'frxExportSynPDF.pas' {frxExportSynPDF},
  DesFrxUtils in 'DesFrxUtils.pas' {DesFrxU},
  FImain in 'FImain.pas' {fmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Mìsíèní fakturace s ÈTÚ';
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TDesU, DesU);
  Application.CreateForm(TdmCommon, dmCommon);
  Application.CreateForm(TdmFaktura, dmFaktura);
  Application.CreateForm(TfmLogin, fmLogin);
  Application.CreateForm(TdmMail, dmMail);
  Application.CreateForm(TdmPrevod, dmPrevod);
  Application.CreateForm(TdmTisk, dmTisk);
  Application.Run;
end.
