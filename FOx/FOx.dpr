program FOx;

uses
  Forms,
  FOx_mail in 'FOx_mail.pas' {dmMail: TDataModule},
  FOx_main in 'FOx_main.pas' {fmMain},
  FOx_common in 'FOx_common.pas' {dmCommon: TDataModule},
  FOx_tisk in 'FOx_tisk.pas' {dmTisk: TDataModule},
  FOx_prevod in 'FOx_prevod.pas' {dmPrevod: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TdmMail, dmMail);
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TdmCommon, dmCommon);
  Application.CreateForm(TdmTisk, dmTisk);
  Application.CreateForm(TdmPrevod, dmPrevod);
  Application.Run;
end.
