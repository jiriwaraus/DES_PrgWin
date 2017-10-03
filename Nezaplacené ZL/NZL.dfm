object fmZL: TfmZL
  Left = 755
  Top = 98
  Caption = 'Nezaplacen'#233' ZL'
  ClientHeight = 592
  ClientWidth = 760
  Color = clBtnFace
  Constraints.MinHeight = 630
  Constraints.MinWidth = 590
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnMain: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 472
    Align = alClient
    TabOrder = 0
    ExplicitWidth = 625
    object lbDo: TLabel
      Left = 10
      Top = 42
      Width = 51
      Height = 13
      Caption = 'Splatno do'
    end
    object lbOd: TLabel
      Left = 10
      Top = 4
      Width = 51
      Height = 13
      Caption = 'Splatno od'
    end
    object btKonec: TButton
      Left = 22
      Top = 434
      Width = 65
      Height = 21
      Caption = '&Konec'
      TabOrder = 1
      OnClick = btKonecClick
    end
    object asgPohledavky: TAdvStringGrid
      Left = 102
      Top = 1
      Width = 657
      Height = 470
      Cursor = crDefault
      Align = alRight
      Anchors = [akLeft, akTop, akRight, akBottom]
      BorderStyle = bsNone
      ColCount = 14
      Ctl3D = True
      DefaultRowHeight = 18
      DrawingStyle = gdsClassic
      FixedCols = 0
      RowCount = 2
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goColSizing, goEditing]
      ParentCtl3D = False
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 0
      HoverRowCells = [hcNormal, hcSelected]
      OnGetAlignment = asgPohledavkyGetAlignment
      OnGetFormat = asgPohledavkyGetFormat
      OnClickSort = asgPohledavkyClickSort
      OnCanSort = asgPohledavkyCanSort
      OnClickCell = asgPohledavkyClickCell
      OnDblClickCell = asgPohledavkyDblClickCell
      OnCanEditCell = asgPohledavkyCanEditCell
      ActiveCellFont.Charset = DEFAULT_CHARSET
      ActiveCellFont.Color = clWindowText
      ActiveCellFont.Height = -11
      ActiveCellFont.Name = 'MS Sans Serif'
      ActiveCellFont.Style = [fsBold]
      ActiveCellColor = 15387318
      ColumnHeaders.Strings = (
        ' z'#225'kazn'#237'k'
        'pohled'#225'vky'
        'po'#269'et ZL'
        'FId        '
        'druh'
        'smlouva'
        'F.Code       '
        '      '
        ' mail'
        'CuId'
        'CId'
        'dny'
        'telefon'
        'mobil SMS')
      ColumnSize.StretchColumn = 0
      ControlLook.FixedGradientFrom = clWhite
      ControlLook.FixedGradientTo = clSilver
      ControlLook.FixedGradientHoverFrom = 13619409
      ControlLook.FixedGradientHoverTo = 12502728
      ControlLook.FixedGradientHoverMirrorFrom = 12502728
      ControlLook.FixedGradientHoverMirrorTo = 11254975
      ControlLook.FixedGradientDownFrom = 8816520
      ControlLook.FixedGradientDownTo = 7568510
      ControlLook.FixedGradientDownMirrorFrom = 7568510
      ControlLook.FixedGradientDownMirrorTo = 6452086
      ControlLook.ControlStyle = csWinXP
      ControlLook.DropDownHeader.Font.Charset = DEFAULT_CHARSET
      ControlLook.DropDownHeader.Font.Color = clWindowText
      ControlLook.DropDownHeader.Font.Height = -11
      ControlLook.DropDownHeader.Font.Name = 'Tahoma'
      ControlLook.DropDownHeader.Font.Style = []
      ControlLook.DropDownHeader.Visible = True
      ControlLook.DropDownHeader.Buttons = <>
      ControlLook.DropDownFooter.Font.Charset = DEFAULT_CHARSET
      ControlLook.DropDownFooter.Font.Color = clWindowText
      ControlLook.DropDownFooter.Font.Height = -11
      ControlLook.DropDownFooter.Font.Name = 'MS Sans Serif'
      ControlLook.DropDownFooter.Font.Style = []
      ControlLook.DropDownFooter.Visible = True
      ControlLook.DropDownFooter.Buttons = <>
      EnableHTML = False
      Filter = <>
      FilterDropDown.Font.Charset = DEFAULT_CHARSET
      FilterDropDown.Font.Color = clWindowText
      FilterDropDown.Font.Height = -11
      FilterDropDown.Font.Name = 'MS Sans Serif'
      FilterDropDown.Font.Style = []
      FilterDropDownClear = '(All)'
      FilterEdit.TypeNames.Strings = (
        'Starts with'
        'Ends with'
        'Contains'
        'Not contains'
        'Equal'
        'Not equal'
        'Clear')
      FixedColWidth = 66
      FixedRowHeight = 18
      FixedRowAlways = True
      FixedFont.Charset = EASTEUROPE_CHARSET
      FixedFont.Color = clWindowText
      FixedFont.Height = -11
      FixedFont.Name = 'MS Sans Serif'
      FixedFont.Style = []
      FloatFormat = '%.2f'
      HoverButtons.Buttons = <>
      HoverButtons.Position = hbLeftFromColumnLeft
      Look = glTMS
      PrintSettings.DateFormat = 'dd/mm/yyyy'
      PrintSettings.Font.Charset = DEFAULT_CHARSET
      PrintSettings.Font.Color = clWindowText
      PrintSettings.Font.Height = -11
      PrintSettings.Font.Name = 'MS Sans Serif'
      PrintSettings.Font.Style = []
      PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
      PrintSettings.FixedFont.Color = clWindowText
      PrintSettings.FixedFont.Height = -11
      PrintSettings.FixedFont.Name = 'MS Sans Serif'
      PrintSettings.FixedFont.Style = []
      PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
      PrintSettings.HeaderFont.Color = clWindowText
      PrintSettings.HeaderFont.Height = -11
      PrintSettings.HeaderFont.Name = 'MS Sans Serif'
      PrintSettings.HeaderFont.Style = []
      PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
      PrintSettings.FooterFont.Color = clWindowText
      PrintSettings.FooterFont.Height = -11
      PrintSettings.FooterFont.Name = 'MS Sans Serif'
      PrintSettings.FooterFont.Style = []
      PrintSettings.PageNumSep = '/'
      RowHeaders.Strings = (
        ' ')
      ScrollWidth = 16
      SearchFooter.ColorTo = 15790320
      SearchFooter.Font.Charset = DEFAULT_CHARSET
      SearchFooter.Font.Color = clWindowText
      SearchFooter.Font.Height = -11
      SearchFooter.Font.Name = 'MS Sans Serif'
      SearchFooter.Font.Style = []
      SortSettings.DefaultFormat = ssAutomatic
      SortSettings.Column = 0
      SortSettings.Show = True
      VAlignment = vtaCenter
      Version = '7.4.2.0'
      ExplicitLeft = 94
      ExplicitTop = -3
      ExplicitWidth = 522
      ColWidths = (
        66
        64
        56
        28
        37
        49
        43
        16
        40
        46
        33
        32
        64
        64)
    end
    object acbRada: TAdvComboBox
      Left = 10
      Top = 96
      Width = 63
      Height = 21
      Color = clWindow
      Version = '1.5.1.0'
      Visible = True
      ButtonWidth = 18
      Style = csDropDownList
      Flat = True
      FlatLineColor = clSilver
      EmptyTextStyle = []
      Ctl3D = False
      DropWidth = 0
      Enabled = True
      ItemIndex = -1
      Items.Strings = (
        'Mn'#237#353'ek'
        'O'#345'ech'
        'Stod'#367'lky'
        #381'i'#382'kov')
      LabelCaption = #344'ada ZL'
      LabelPosition = lpTopLeft
      LabelMargin = 1
      LabelAlwaysEnabled = True
      LabelFont.Charset = DEFAULT_CHARSET
      LabelFont.Color = clWindowText
      LabelFont.Height = -11
      LabelFont.Name = 'MS Sans Serif'
      LabelFont.Style = []
      ParentCtl3D = False
      TabOrder = 2
    end
    object btVyber: TButton
      Left = 22
      Top = 194
      Width = 65
      Height = 21
      Caption = '&Vyber'
      TabOrder = 3
      OnClick = btVyberClick
    end
    object btExport: TButton
      Left = 22
      Top = 226
      Width = 65
      Height = 21
      Caption = '&Export'
      TabOrder = 4
      OnClick = btExportClick
    end
    object btMail: TButton
      Left = 22
      Top = 258
      Width = 65
      Height = 21
      Caption = '&Mail'
      TabOrder = 5
      OnClick = btMailClick
    end
    object acbDruhSmlouvy: TAdvComboBox
      Left = 10
      Top = 134
      Width = 89
      Height = 21
      Color = clWindow
      Version = '1.5.1.0'
      Visible = True
      ButtonWidth = 18
      Style = csDropDownList
      Flat = True
      FlatLineColor = clSilver
      EmptyTextStyle = []
      Ctl3D = False
      DropWidth = 0
      Enabled = True
      ItemIndex = -1
      Items.Strings = (
        '%'
        '0'
        '1'
        '2'
        '3'
        '4'
        '5'
        '7')
      LabelCaption = 'Druh smlouvy'
      LabelPosition = lpTopLeft
      LabelMargin = 1
      LabelAlwaysEnabled = True
      LabelFont.Charset = DEFAULT_CHARSET
      LabelFont.Color = clWindowText
      LabelFont.Height = -11
      LabelFont.Name = 'MS Sans Serif'
      LabelFont.Style = []
      ParentCtl3D = False
      TabOrder = 6
    end
    object cbCast: TCheckBox
      Left = 14
      Top = 166
      Width = 87
      Height = 17
      Caption = 'I '#269#225'ste'#269'n'#283
      Checked = True
      State = cbChecked
      TabOrder = 8
    end
    object btOdpojit: TButton
      Left = 22
      Top = 404
      Width = 65
      Height = 21
      Caption = 'O&dpojit'
      TabOrder = 9
      OnClick = btOdpojitClick
    end
    object rgText: TRadioGroup
      Left = 22
      Top = 325
      Width = 65
      Height = 73
      ItemIndex = 0
      Items.Strings = (
        'Text 1'
        'Text 2'
        'Text 3')
      TabOrder = 7
      OnClick = rgTextClick
    end
    object deDatumOd: TDateTimePicker
      Left = 8
      Top = 20
      Width = 80
      Height = 21
      Date = 43010.950627025460000000
      Time = 43010.950627025460000000
      TabOrder = 10
    end
    object deDatumDo: TDateTimePicker
      Left = 8
      Top = 58
      Width = 79
      Height = 21
      Date = 43010.950936585650000000
      Time = 43010.950936585650000000
      TabOrder = 11
    end
    object btSMS: TButton
      Left = 22
      Top = 290
      Width = 65
      Height = 21
      Caption = '&SMS'
      TabOrder = 12
      OnClick = btSMSClick
    end
  end
  object pnBottom: TPanel
    Left = 0
    Top = 472
    Width = 760
    Height = 120
    Align = alBottom
    TabOrder = 1
    ExplicitWidth = 625
    object mmMail: TMemo
      Left = 1
      Top = 1
      Width = 758
      Height = 118
      Align = alClient
      Lines.Strings = (
        'V'#225#382'en'#253' pane, v'#225#382'en'#225' pan'#237','
        
          'dovolujeme si V'#225's upozornit, '#382'e je XXX dn'#237' po splatnosti z'#225'lohy ' +
          'na p'#345'ipojen'#237' k internetu a st'#225'le od V'#225's postr'#225'd'#225'me jej'#237' '#250'plnou '
        #250'hradu. Dlu'#382'n'#225' '#269#225'stka '#269'in'#237' YYY K'#269'.'#39
        
          'Pot'#283#353'ilo by n'#225's, kdybyste '#269#225'stku z'#225'lohy co nejd'#345#237've uhradili a m' +
          'y V'#225'm nemuseli omezovat poskytovan'#233' slu'#382'by.')
      TabOrder = 0
      ExplicitWidth = 623
    end
  end
  object dlgExport: TSaveDialog
    DefaultExt = '.xls'
    Filter = 'xls|*.xls'
    Options = [ofHideReadOnly, ofNoReadOnlyReturn, ofEnableSizing]
    Left = 150
    Top = 162
  end
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
    Left = 254
    Top = 55
  end
  object idSMTP: TIdSMTP
    SASLMechanisms = <>
    Left = 306
    Top = 55
  end
  object idHTTP: TIdHTTP
    AllowCookies = True
    HandleRedirects = True
    ProtocolVersion = pv1_0
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = 0
    Request.ContentRangeEnd = 0
    Request.ContentRangeStart = 0
    Request.ContentRangeInstanceLength = -1
    Request.ContentType = 'text/html'
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.Password = '1'
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Request.Ranges.Units = 'bytes'
    Request.Ranges = <>
    HTTPOptions = [hoForceEncodeParams]
    Left = 134
    Top = 55
  end
  object IdAntiFreeze1: TIdAntiFreeze
    OnlyWhenIdle = False
    Left = 186
    Top = 55
  end
end
