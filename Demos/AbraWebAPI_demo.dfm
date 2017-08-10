object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 758
  ClientWidth = 996
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object lblUrl: TLabel
    Left = 16
    Top = 10
    Width = 23
    Height = 13
    Caption = 'URL:'
  end
  object lblReqData: TLabel
    Left = 16
    Top = 40
    Width = 26
    Height = 13
    Caption = 'data:'
  end
  object btnGet: TButton
    Left = 8
    Top = 176
    Width = 75
    Height = 25
    Caption = 'GET'
    TabOrder = 0
    OnClick = btnGetClick
  end
  object Memo1: TMemo
    Left = 48
    Top = 37
    Width = 344
    Height = 121
    TabOrder = 1
  end
  object Memo2: TMemo
    Left = 8
    Top = 222
    Width = 977
    Height = 315
    Lines.Strings = (
      '')
    TabOrder = 2
  end
  object btnPost: TButton
    Left = 97
    Top = 176
    Width = 75
    Height = 25
    Caption = 'POST'
    TabOrder = 3
    OnClick = btnPostClick
  end
  object btnPut: TButton
    Left = 192
    Top = 176
    Width = 75
    Height = 25
    Caption = 'PUT'
    TabOrder = 4
    OnClick = btnPutClick
  end
  object editUrl: TEdit
    Left = 48
    Top = 10
    Width = 401
    Height = 21
    TabOrder = 5
    Text = 'http://localhost/DES/periods?where=code+gt+2015'
  end
  object Memo3: TMemo
    Left = 8
    Top = 543
    Width = 881
    Height = 200
    TabOrder = 6
  end
  object btnArrayTest1: TButton
    Left = 504
    Top = 8
    Width = 105
    Height = 25
    Caption = 'ArrayTest1'
    TabOrder = 7
    OnClick = btnArrayTest1Click
  end
  object btnPutAa: TButton
    Left = 416
    Top = 176
    Width = 75
    Height = 25
    Caption = 'PUT AA'
    TabOrder = 8
    OnClick = btnPutAaClick
  end
  object Button1: TButton
    Left = 568
    Top = 176
    Width = 75
    Height = 25
    Caption = 'POST JSON'
    TabOrder = 9
    OnClick = Button1Click
  end
end
