object Form1: TForm1
  Left = 741
  Top = 409
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'uMMovements'
  ClientHeight = 53
  ClientWidth = 381
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 8
    Top = 16
    Width = 75
    Height = 25
    Caption = 'MMouse'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 104
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Mouse'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 200
    Top = 16
    Width = 75
    Height = 25
    Caption = 'BrakeMMouse'
    TabOrder = 2
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 296
    Top = 16
    Width = 75
    Height = 25
    Caption = 'MissMouse'
    TabOrder = 3
    OnClick = Button4Click
  end
end
