unit FOx_mail;

interface

uses
  Forms, Controls, SysUtils, Classes, DateUtils, Math, FOx_main,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdMessage, IdMessageClient, IdMessageParts, IdText,
  IdSMTPBase, IdSMTP, IdAttachmentFile, IdAntiFreezeBase, IdAntiFreeze, IdExplicitTLSClientServerBase;

type
  TdmMail = class(TDataModule)
    idMessage: TIdMessage;
    idSMTP: TIdSMTP;
    IdAntiFreeze: TIdAntiFreeze;
  private
    procedure FOxMail(Radek: integer);                // pošle jeden doklad
  public
    procedure PosliFOx;
  end;

var
  dmMail: TdmMail;

implementation

{$R *.dfm}

uses FOx_common;

// ------------------------------------------------------------------------------------------------

procedure TdmMail.PosliFOx;
// použije data z asgMain
var
  Radek: integer;
begin
  with fmMain do try
    dmCommon.Zprava('Rozesílání dokladù.');
    with asgMain do begin
      dmCommon.Zprava(Format('Poèet dokladù k rozeslání: %d', [Trunc(ColumnSum(0, 1, RowCount-1))]));
      Screen.Cursor := crHourGlass;
      apnMail.Visible := False;
      apbProgress.Position := 0;
      apbProgress.Visible := True;
// hlavní smyèka
      for Radek := 1 to RowCount-1 do begin
        Row := Radek;
        apbProgress.Position := Round(100 * Radek / RowCount-1);
        Application.ProcessMessages;
        if Prerusit then begin
          Prerusit := False;
          apbProgress.Position := 0;
          apbProgress.Visible := False;
          btVytvorit.Enabled := True;
          asgMain.Visible := True;
          lbxLog.Visible := False;
          Break;
        end;
        if Ints[0, Radek] = 1 then FOxMail(Radek);
      end;  // for
    end;
// konec hlavní smyèky
  finally
    apbProgress.Position := 0;
    apbProgress.Visible := False;
    apnMail.Visible := True;
    asgMain.Visible := False;
    lbxLog.Visible := True;
    if idSMTP.Connected then idSMTP.Disconnect;
    Screen.Cursor := crDefault;
    dmCommon.Zprava('Rozesílání dokladù ukonèeno');
  end;
end;

// ------------------------------------------------------------------------------------------------

procedure TdmMail.FOxMail(Radek: integer);
var
  OutDir,
  MailStr,
  PDFFile: AnsiString;
begin
  with fmMain, asgMain do begin
    OutDir := Format('%s\%4d\%2.2d', [PDFDir, aseRok.Value, aseMesic.Value]);
    if rbInternet.Checked then CisloFO := Format('FO4-%4.4d', [Ints[2, Radek]])
    else CisloFO := Format('FO2-%4.4d', [Ints[2, Radek]]);
// musí existovat PDF soubor s fakturou
    PDFFile := Format('%s\%s.pdf', [OutDir, CisloFO]);
    if not FileExists(PDFFile) then begin
      dmCommon.Zprava(Format('Soubor %s neexistuje. Pøeskoèeno.', [PDFFile]));
      Exit;
    end;
// alespoò nìjaká kontrola mailové adresy
    if Pos('@', Cells[5, Radek]) = 0 then begin
      dmCommon.Zprava(Format('Neplatná mailová adresa "%s". Pøeskoèeno.', [Cells[6, Radek]]));
      Exit;
    end;
    MailStr := Cells[5, Radek];
    MailStr := StringReplace(MailStr, ',', ';', [rfReplaceAll]);    // èárky za støedníky
    with idMessage do begin
      Clear;
//      ContentType := 'text/plain';
//      Charset := 'Windows-1250';
// více mailových adres oddìlených støedníky se rozdìlí
      while Pos(';', MailStr) > 0 do begin
        Recipients.Add.Address := Trim(Copy(MailStr, 1, Pos(';', MailStr)-1));
        MailStr := Copy(MailStr, Pos(';', MailStr)+1, Length(MailStr));
      end;
      Recipients.Add.Address := Trim(MailStr);
      From.Address := 'uctarna@eurosignal.cz';
      ReceiptRecipient.Text := 'uctarna@eurosignal.cz';
      Subject := Format('Družstvo EUROSIGNAL, daòový doklad k zaplacenému kreditu %s/%d', [CisloFO, aseRok.Value]);
      with TIdText.Create(idMessage.MessageParts, nil) do begin
        Body.Text := Format('Daòový doklad %s/%d k zaplacenému kreditu je v pøiloženém PDF dokumentu.'
         + ' Poslední verze programu Adobe Reader, kterým mùžete PDF dokumenty zobrazit i vytisknout,'
         + ' je zdarma ke stažení na http://get.adobe.com/reader/otherversions/.', [CisloFO, aseRok.Value])
         + sLineBreak + sLineBreak
         +'S pozdravem'
         + sLineBreak + sLineBreak
         + 'Družstvo Eurosignal';
        ContentType := 'text/plain';
        Charset := 'utf-8';
      end;
      ContentType := 'multipart/mixed';
{
      Body.Add(Format('Daòový doklad %s/%d k zaplacenému kreditu je v pøiloženém PDF dokumentu.'
      + ' Poslední verze programu Adobe Reader, kterým mùžete PDF dokumenty zobrazit i vytisknout,'
      + ' je zdarma ke stažení na http://get.adobe.com/reader/otherversions/.', [CisloFO, aseRok.Value]));
      Body.Add(' ');
      Body.Add('Pokud dostanete tuto zprávu bez pøílohy, napište nám, prosím, my se to pokusíme napravit.');
      Body.Add(' ');
      Body.Add(' ');
      Body.Add('Pøejeme pìkný den');
      Body.Add(' ');
      Body.Add('Družstvo Eurosignal');
}
      TIdAttachmentFile.Create(MessageParts, PDFFile);
// pøidá se pøíloha, je-li vybrána a zákazníkovi se posílá reklama
      if (Ints[6, Radek] = 0) and (fePriloha.FileName <> '') then TIdAttachmentFile.Create(MessageParts, fePriloha.FileName);
      with idSMTP do begin
        Port := 25;
        if Username = '' then AuthType := satNone
        else AuthType := satDefault;
      end;
      try
        if not idSMTP.Connected then idSMTP.Connect;
        idSMTP.Send(idMessage);
        dmCommon.Zprava(Format('%s (%s): Soubor %s byl odeslán na adresu %s.',
         [Cells[4, Radek], Cells[1, Radek], PDFFile, Cells[5, Radek]]));
        Ints[0, Radek] := 0;
      except on E: exception do
        dmCommon.Zprava(Format('%s (%s): Soubor %s se nepodaøilo odeslat na adresu %s.' + #13#10 + 'Chyba: %s',
         [Cells[4, Radek], Cells[1, Radek], PDFFile, Cells[5, Radek], E.Message]));
      end;
      Application.ProcessMessages;
    end;
  end;  // with fmMain
end;  // procedury ZLMail

end.
