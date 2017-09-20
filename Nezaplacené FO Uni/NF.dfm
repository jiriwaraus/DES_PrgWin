object fmMain: TfmMain
  Left = 308
  Top = 102
  Caption = 'Nezaplacen'#233' faktury'
  ClientHeight = 646
  ClientWidth = 846
  Color = clBtnFace
  Constraints.MinHeight = 674
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
  object pnBottom: TPanel
    Left = 0
    Top = 526
    Width = 846
    Height = 120
    Align = alBottom
    TabOrder = 0
    object mmMail: TMemo
      Left = 1
      Top = 1
      Width = 844
      Height = 118
      Align = alClient
      Lines.Strings = (
        'V'#225#382'en'#253' z'#225'kazn'#237'ku,'
        
          'upozor'#328'ujeme V'#225's, '#382'e V'#225#353' dluh za p'#345'ipojen'#237' k internetu dos'#225'hl dv' +
          'ou m'#283's'#237#269'n'#237'ch plateb, nebo tuto '#269#225'stku ji'#382' p'#345'es'#225'hl.. '
        
          'V brzk'#233' dob'#283' proto m'#367#382'ete o'#269'ek'#225'vat sankce v podob'#283' omezen'#237' posky' +
          'tovan'#253'ch slu'#382'eb.'
        
          'Bli'#382#353#237' informace m'#367#382'ete v pracovn'#237' dny (9-16 h.) z'#237'skat na '#269#237'sle' +
          ' 227 031 807, nebo kdykoliv na sv'#233'm z'#225'kaznick'#233'm '#250#269'tu na '
        'www.eurosignal.cz'
        '')
      TabOrder = 0
    end
  end
  object pnMain: TPanel
    Left = 0
    Top = 0
    Width = 846
    Height = 526
    Align = alClient
    TabOrder = 1
    object lbDo: TLabel
      Left = 10
      Top = 42
      Width = 65
      Height = 13
      Caption = 'Vystaveno do'
    end
    object lbOd: TLabel
      Left = 10
      Top = 4
      Width = 65
      Height = 13
      Caption = 'Vystaveno od'
    end
    object btKonec: TButton
      Left = 20
      Top = 494
      Width = 71
      Height = 21
      Caption = '&Konec'
      TabOrder = 1
      OnClick = btKonecClick
    end
    object asgPohledavky: TAdvStringGrid
      Left = 102
      Top = 1
      Width = 743
      Height = 524
      Cursor = crDefault
      Align = alRight
      Anchors = [akLeft, akTop, akRight, akBottom]
      BorderStyle = bsNone
      ColCount = 12
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
        ' k'#243'd'
        'po'#269'et FO'
        'pohled'#225'vky'
        '311-325'
        'druh'
        'smlouva'
        '        '
        ' mail'
        'telefon'
        'CuId'
        'CId')
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
      FixedColWidth = 70
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
      ColWidths = (
        70
        38
        64
        64
        54
        36
        49
        17
        38
        49
        37
        33)
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
      LabelCaption = #344'ada faktur'
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
      Left = 20
      Top = 264
      Width = 71
      Height = 21
      Caption = '&Vyber'
      TabOrder = 3
      OnClick = btVyberClick
    end
    object btExport: TButton
      Left = 20
      Top = 294
      Width = 71
      Height = 21
      Caption = '&Export'
      TabOrder = 4
      OnClick = btExportClick
    end
    object aedPocetOd: TAdvEdit
      Left = 10
      Top = 136
      Width = 61
      Height = 17
      TabStop = False
      EditAlign = eaRight
      EditType = etNumeric
      EmptyTextStyle = []
      FlatParentColor = False
      FocusColor = 15387318
      LabelCaption = 'Od po'#269'tu NF'
      LabelPosition = lpTopLeft
      LabelMargin = 3
      LabelFont.Charset = DEFAULT_CHARSET
      LabelFont.Color = clWindowText
      LabelFont.Height = -11
      LabelFont.Name = 'MS Sans Serif'
      LabelFont.Style = []
      Lookup.Font.Charset = DEFAULT_CHARSET
      Lookup.Font.Color = clWindowText
      Lookup.Font.Height = -11
      Lookup.Font.Name = 'Arial'
      Lookup.Font.Style = []
      Lookup.Separator = ';'
      BorderStyle = bsNone
      Color = clWindow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      Text = '1'
      Visible = True
      Version = '3.3.2.3'
    end
    object btMail: TButton
      Left = 20
      Top = 324
      Width = 71
      Height = 21
      Caption = '&Mail'
      TabOrder = 6
      OnClick = btMailClick
    end
    object acbDruhSmlouvy: TAdvComboBox
      Left = 10
      Top = 210
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
      TabOrder = 7
    end
    object cbCast: TCheckBox
      Left = 12
      Top = 238
      Width = 87
      Height = 17
      Caption = 'I '#269#225'ste'#269'n'#283
      Checked = True
      State = cbChecked
      TabOrder = 8
    end
    object aedPocetDo: TAdvEdit
      Left = 10
      Top = 174
      Width = 61
      Height = 17
      TabStop = False
      EditAlign = eaRight
      EditType = etNumeric
      EmptyTextStyle = []
      FlatParentColor = False
      FocusColor = 15387318
      LabelCaption = 'Do po'#269'tu NF'
      LabelPosition = lpTopLeft
      LabelMargin = 3
      LabelFont.Charset = DEFAULT_CHARSET
      LabelFont.Color = clWindowText
      LabelFont.Height = -11
      LabelFont.Name = 'MS Sans Serif'
      LabelFont.Style = []
      Lookup.Font.Charset = DEFAULT_CHARSET
      Lookup.Font.Color = clWindowText
      Lookup.Font.Height = -11
      Lookup.Font.Name = 'Arial'
      Lookup.Font.Style = []
      Lookup.Separator = ';'
      BorderStyle = bsNone
      Color = clWindow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
      Text = '1'
      Visible = True
      Version = '3.3.2.3'
    end
    object btOdpojit: TButton
      Left = 20
      Top = 464
      Width = 71
      Height = 21
      Caption = 'O&dpojit'
      TabOrder = 11
      OnClick = btOdpojitClick
    end
    object rgText: TRadioGroup
      Left = 20
      Top = 390
      Width = 69
      Height = 59
      Caption = 'Mail'
      ItemIndex = 0
      Items.Strings = (
        'Text 1'
        'Text 2')
      TabOrder = 10
      OnClick = rgTextClick
    end
    object btSMS: TButton
      Left = 21
      Top = 351
      Width = 70
      Height = 22
      Caption = 'SMS'
      TabOrder = 12
    end
    object deDatumOd: TDateTimePicker
      Left = 10
      Top = 19
      Width = 81
      Height = 21
      Date = 42997.895638668980000000
      Time = 42997.895638668980000000
      TabOrder = 13
    end
    object deDatumDo: TDateTimePicker
      Left = 10
      Top = 58
      Width = 79
      Height = 21
      Date = 42998.983010243060000000
      Time = 42998.983010243060000000
      TabOrder = 14
    end
  end
  object dlgExport: TSaveDialog
    DefaultExt = '.xls'
    Filter = 'xls|*.xls'
    Options = [ofHideReadOnly, ofNoReadOnlyReturn, ofEnableSizing]
    Left = 118
    Top = 138
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
    Left = 218
    Top = 39
  end
  object idSMTP: TIdSMTP
    SASLMechanisms = <>
    Left = 278
    Top = 47
  end
  object dbMain: TZConnection
    ControlsCodePage = cGET_ACP
    Catalog = ''
    Properties.Strings = (
      'controls_cp=GET_ACP')
    HostName = 'test.iquest.cz'
    Port = 0
    Database = 'eurosignal'
    User = 'eurosignal'
    Password = 'ayQKeWSf9F'
    Protocol = 'mysql-5'
    Left = 170
    Top = 138
  end
  object qrMain: TZQuery
    Connection = dbMain
    SortType = stIgnored
    CachedUpdates = True
    ReadOnly = True
    SQL.Strings = (
      '')
    Params = <>
    ShowRecordTypes = [usUnmodified, usModified, usInserted, usDeleted]
    WhereMode = wmWhereAll
    Left = 214
    Top = 138
  end
  object qrRows: TZQuery
    Connection = dbMain
    SortType = stIgnored
    CachedUpdates = True
    ReadOnly = True
    SQL.Strings = (
      '')
    Params = <>
    ShowRecordTypes = [usUnmodified, usModified, usInserted, usDeleted]
    WhereMode = wmWhereAll
    Left = 274
    Top = 138
  end
  object dbAbra: TZConnection
    ControlsCodePage = cGET_ACP
    Catalog = ''
    Properties.Strings = (
      'controls_cp=GET_ACP')
    ReadOnly = True
    HostName = ''
    Port = 0
    Database = ''
    User = ''
    Password = ''
    Protocol = 'firebird-2.1'
    Left = 170
    Top = 262
  end
  object qrAbra: TZQuery
    Connection = dbAbra
    CachedUpdates = True
    ReadOnly = True
    SQL.Strings = (
      '')
    Params = <>
    Left = 214
    Top = 262
  end
  object qrAbra3: TZQuery
    Connection = dbAbra
    CachedUpdates = True
    ReadOnly = True
    SQL.Strings = (
      '')
    Params = <>
    Left = 302
    Top = 262
  end
  object qrAbra2: TZQuery
    Connection = dbAbra
    CachedUpdates = True
    ReadOnly = True
    SQL.Strings = (
      '')
    Params = <>
    Left = 258
    Top = 262
  end
  object IdAntiFreeze1: TIdAntiFreeze
    OnlyWhenIdle = False
    Left = 166
    Top = 39
  end
  object idHTTP: TIdHTTP
    AllowCookies = True
    HandleRedirects = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = 0
    Request.ContentRangeEnd = 0
    Request.ContentRangeStart = 0
    Request.ContentRangeInstanceLength = -1
    Request.ContentType = 'text/html'
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Request.Ranges.Units = 'bytes'
    Request.Ranges = <>
    HTTPOptions = [hoForceEncodeParams]
    Left = 130
    Top = 39
  end
end
