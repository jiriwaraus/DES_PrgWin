program IFIAbra;

uses
  Forms,
  F1 in 'F1.pas' {fmMain},
  Code in 'Code.pas' {dmCode: TDataModule},
  Login in 'Login.pas' {fmLogin},
  AArray in '..\DE$_Common\AArray.pas',
  AbraEntities in '..\DE$_Common\AbraEntities.pas',
  DesUtils in '..\DE$_Common\DesUtils.pas' {DesU},
  Superdate in '..\DE$_Common\Superdate.pas',
  Superobject in '..\DE$_Common\Superobject.pas',
  Supertimezone in '..\DE$_Common\Supertimezone.pas',
  Supertypes in '..\DE$_Common\Supertypes.pas',
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
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TdmCode, dmCode);
  Application.CreateForm(TfmLogin, fmLogin);
  Application.CreateForm(TDesU, DesU);
  Application.CreateForm(TDesFrxU, DesFrxU);
  Application.Run;
end.
