program IFIAbraA;

uses
  Forms,
  F1 in 'F1.pas' {fmMain},
  Code in 'Code.pas' {dmCode: TDataModule},
  Login in 'Login.pas' {fmLogin};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TdmCode, dmCode);
  Application.CreateForm(TfmLogin, fmLogin);
  Application.Run;
end.
