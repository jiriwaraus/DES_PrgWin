program IFIAbra;

uses
  Forms,
  F1 in 'F1.pas' {fmMain},
  Code in 'Code.pas' {dmCode: TDataModule},
  Login in 'Login.pas' {fmLogin},
  AArray in '..\DE$_Common\AArray.pas',
  AbraEntities in '..\DE$_Common\AbraEntities.pas',
  DesFrxUtils in '..\DE$_Common\DesFrxUtils.pas' {DesFrxU},
  DesUtils in '..\DE$_Common\DesUtils.pas' {DesU},
  Superdate in '..\DE$_Common\Superdate.pas',
  Superobject in '..\DE$_Common\Superobject.pas',
  Supertimezone in '..\DE$_Common\Supertimezone.pas',
  Supertypes in '..\DE$_Common\Supertypes.pas',
  frxExportSynPDF in 'frxExportSynPDF.pas' {frxExportSynPDF};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TdmCode, dmCode);
  Application.CreateForm(TfmLogin, fmLogin);
  Application.CreateForm(TDesFrxU, DesFrxU);
  Application.CreateForm(TDesU, DesU);

  Application.Run;
end.
