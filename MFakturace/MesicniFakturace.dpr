program MesicniFakturace;

uses
  Forms,
  FImain in 'FImain.pas' {fmMain},
  FIcommon in 'FIcommon.pas' {dmCommon: TDataModule},
  FIfaktura in 'FIfaktura.pas' {dmFaktura: TDataModule},
  FImail in 'FImail.pas' {dmMail: TDataModule},
  FItisk in 'FItisk.pas' {dmTisk: TDataModule},
  FIprevod in 'FIprevod.pas' {dmPrevod: TDataModule},
  FIlogin in 'FIlogin.pas' {fmLogin};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Mìsíèní fakturace s ÈTÚ';
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TdmCommon, dmCommon);
  Application.CreateForm(TdmFaktura, dmFaktura);
  Application.CreateForm(TdmMail, dmMail);
  Application.CreateForm(TdmTisk, dmTisk);
  Application.CreateForm(TdmPrevod, dmPrevod);
  Application.CreateForm(TfmLogin, fmLogin);
  Application.Run;
end.
