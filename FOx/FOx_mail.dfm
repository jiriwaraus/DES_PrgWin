object dmMail: TdmMail
  OldCreateOrder = False
  Height = 64
  Width = 229
  object idMessage: TIdMessage
    AttachmentEncoding = 'MIME'
    BccList = <>
    CCList = <>
    Encoding = meMIME
    FromList = <
      item
      end>
    Recipients = <>
    ReplyTo = <>
    ConvertPreamble = True
    Left = 36
    Top = 8
  end
  object idSMTP: TIdSMTP
    SASLMechanisms = <>
    Left = 98
    Top = 8
  end
  object IdAntiFreeze: TIdAntiFreeze
    OnlyWhenIdle = False
    Left = 162
    Top = 7
  end
end
