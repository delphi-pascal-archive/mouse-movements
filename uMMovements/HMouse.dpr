program HMouse;

uses
  Forms,
  Main in 'Main.pas' {Form1},
  uMMovements in 'uMMovements.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
