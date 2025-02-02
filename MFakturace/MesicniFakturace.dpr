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
  FImain in 'FImain.pas' {fmMain},
  DesFrxUtils in '..\DE$_Common\frxExport\DesFrxUtils.pas' {DesFrxU},
  frxExportSynPDF in '..\DE$_Common\frxExport\frxExportSynPDF.pas' {frxExportSynPDF},
  SynCommons in '..\DE$_Common\frxExport\SynCommons.pas',
  SynCrypto in '..\DE$_Common\frxExport\SynCrypto.pas',
  SynGdiPlus in '..\DE$_Common\frxExport\SynGdiPlus.pas',
  SynLZ in '..\DE$_Common\frxExport\SynLZ.pas',
  SynPdf in '..\DE$_Common\frxExport\SynPdf.pas',
  SynZip in '..\DE$_Common\frxExport\SynZip.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'M�s��n� fakturace s �T�';
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TDesU, DesU);
  Application.CreateForm(TdmCommon, dmCommon);
  Application.CreateForm(TdmFaktura, dmFaktura);
  Application.CreateForm(TfmLogin, fmLogin);
  Application.CreateForm(TdmMail, dmMail);
  Application.CreateForm(TdmPrevod, dmPrevod);
  Application.CreateForm(TdmTisk, dmTisk);
  Application.CreateForm(TDesFrxU, DesFrxU);
  Application.Run;
end.
