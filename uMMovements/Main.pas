unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
 uses uMMovements;
{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
 MMouse(100,500,1,1);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 Mouse(150,350,5,5,mouse_Right);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 BrakeMMouse(500,500,2,2);
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
MissMouse(600,600,2,2);
end;

end.
