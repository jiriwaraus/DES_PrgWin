object fmPrirazeniPnp: TfmPrirazeniPnp
  Left = 133
  Top = 0
  Caption = 'P'#345'i'#345'azen'#237' PNP'
  ClientHeight = 676
  ClientWidth = 1294
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  OnShow = FormShow
  DesignSize = (
    1294
    676)
  PixelsPerInch = 96
  TextHeight = 13
  object asgPNP: TAdvStringGrid
    Left = -3
    Top = 47
    Width = 1292
    Height = 622
    Cursor = crDefault
    Anchors = [akLeft, akTop, akBottom]
    BorderStyle = bsNone
    ColCount = 17
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
    OnGetCellColor = asgPNPGetCellColor
    OnGetAlignment = asgPNPGetAlignment
    OnCanSort = asgPNPCanSort
    OnClickCell = asgPnpClickCell
    ActiveCellFont.Charset = DEFAULT_CHARSET
    ActiveCellFont.Color = clWindowText
    ActiveCellFont.Height = -11
    ActiveCellFont.Name = 'MS Sans Serif'
    ActiveCellFont.Style = [fsBold]
    ActiveCellColor = 15387318
    ColumnHeaders.Strings = (
      #268#237'slo v'#253'pisu'
      'P'#345'epl. (pnp)'
      'Z'#225'kazn'#237'k'
      'Text'
      #344#225'dek v'#253'pisu ID'
      'Firm ID'
      #268#237'slo dokladu'
      'ID dokladu'
      'VS dokladu'
      'Datum'
      'P'#345'edpis'
      'Zaplaceno'
      'Nezaplac.'
      'akce'
      'zaplaceno'
      'nezaplac.')
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
    FilterDropDown.TextChecked = 'Checked'
    FilterDropDown.TextUnChecked = 'Unchecked'
    FilterDropDownClear = '(All)'
    FilterEdit.TypeNames.Strings = (
      'Starts with'
      'Ends with'
      'Contains'
      'Not contains'
      'Equal'
      'Not equal'
      'Clear')
    FixedColWidth = 81
    FixedRowHeight = 18
    FixedRowAlways = True
    FixedFont.Charset = EASTEUROPE_CHARSET
    FixedFont.Color = clWindowText
    FixedFont.Height = -11
    FixedFont.Name = 'MS Sans Serif'
    FixedFont.Style = [fsBold]
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
    SearchFooter.FindNextCaption = 'Find &next'
    SearchFooter.FindPrevCaption = 'Find &previous'
    SearchFooter.Font.Charset = DEFAULT_CHARSET
    SearchFooter.Font.Color = clWindowText
    SearchFooter.Font.Height = -11
    SearchFooter.Font.Name = 'MS Sans Serif'
    SearchFooter.Font.Style = []
    SearchFooter.HighLightCaption = 'Highlight'
    SearchFooter.HintClose = 'Close'
    SearchFooter.HintFindNext = 'Find next occurrence'
    SearchFooter.HintFindPrev = 'Find previous occurrence'
    SearchFooter.HintHighlight = 'Highlight occurrences'
    SearchFooter.MatchCaseCaption = 'Match case'
    SortSettings.DefaultFormat = ssAutomatic
    SortSettings.Column = 0
    SortSettings.Show = True
    VAlignment = vtaCenter
    Version = '7.4.2.0'
    ColWidths = (
      81
      75
      121
      119
      80
      80
      91
      77
      77
      65
      64
      72
      72
      39
      72
      72
      5)
  end
  object btnNactiPnp: TButton
    Left = 8
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Na'#269'ti data'
    TabOrder = 1
    OnClick = btnNactiPnpClick
  end
  object btnPriradPnp: TButton
    Left = 392
    Top = 16
    Width = 161
    Height = 25
    Caption = 'P'#345'i'#345'a'#271' doklady k PNP platb'#225'm'
    TabOrder = 2
    OnClick = btnPriradPnpClick
  end
  object btnNactiPnpAlt: TButton
    Left = 1168
    Top = 16
    Width = 89
    Height = 25
    Caption = 'alternativn'#237' data'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    Visible = False
    OnClick = btnNactiPnpAltClick
  end
  object chbNacistPnp: TCheckBox
    Left = 96
    Top = 24
    Width = 289
    Height = 17
    Caption = 'vyhledat i doklady s '#269#225'stkou men'#353#237' ne'#382' p'#345'eplatek'
    Checked = True
    State = cbChecked
    TabOrder = 4
  end
  object btnShowParovaniDeniku: TButton
    Left = 729
    Top = 16
    Width = 120
    Height = 25
    Caption = 'P'#225'rov'#225'n'#237' v den'#237'ku'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = btnShowParovaniDenikuClick
  end
  object Button1: TButton
    Left = 863
    Top = 16
    Width = 130
    Height = 25
    Caption = 'Seskupen'#237' v den'#237'ku'
    TabOrder = 6
    OnClick = Button1Click
  end
end
