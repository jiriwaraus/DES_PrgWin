program NezaplaceneFOA;

uses
  Forms,
  NF in 'NF.pas' {fmMain},
  NF2D in 'NF2D.pas' {fmDetail};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TfmDetail, fmDetail);
  Application.Run;
end.
