unit uMMovements;

  //Human-like mouse movements
  //Original idea - SRL community(http://villavu.com)
  //Ported to Delphi by CynicRus; CynicRus@gmail.com
  //Если понравилось, то вы можете сказать спасибо сюда:
  //WMR: R413181153275
  //WMZ: Z395281134621

  // If you like it, you may donate to PayPal
  //CynicRus@gmail.com

   {uMMovements is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    uMMovements is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with uMMovements.  If not, see <http://www.gnu.org/licenses/>.  }
 interface
  uses
   Windows;

 type
   TPointArray = array of TPoint;

   TBox = record
     x1, y1, x2, y2: Integer;
   end;

 TClickType = (mouse_Left=1, mouse_Right=0, mouse_Middle=2);
     PMouseInput = ^TMouseInput;
     tagMOUSEINPUT = packed record
       dx: Longint;
       dy: Longint;
       mouseData: DWORD;
       dwFlags: DWORD;
       time: DWORD;
       dwExtraInfo: DWORD;
     end;
     TMouseInput = tagMOUSEINPUT;

     PKeybdInput = ^TKeybdInput;
     tagKEYBDINPUT = packed record
       wVk: WORD;
       wScan: WORD;
       dwFlags: DWORD;
       time: DWORD;
       dwExtraInfo: DWORD;
     end;
     TKeybdInput = tagKEYBDINPUT;

     PHardwareInput = ^THardwareInput;
     tagHARDWAREINPUT = packed record
       uMsg: DWORD;
       wParamL: WORD;
       wParamH: WORD;
     end;
     THardwareInput = tagHARDWAREINPUT;
     PInput = ^TInput;
     tagINPUT = packed record
       Itype: DWORD;
       case Integer of
         0: (mi: TMouseInput);
         1: (ki: TKeybdInput);
         2: (hi: THardwareInput);
     end;
     TInput = tagINPUT;

   const
     INPUT_MOUSE = 0;
     INPUT_KEYBOARD = 1;
     INPUT_HARDWARE = 2;
 //WinApi
 function SendInput(cInputs: UINT; var pInputs: TInput; cbSize: Integer): UINT; stdcall; external user32 name 'SendInput';

 //Internal functions
 procedure GetMousePosition(out x,y: integer);
 procedure MoveMouse(x,y: integer);
 procedure HoldMouse(x,y: integer; button: TClickType);
 procedure ReleaseMouse(x,y: integer; button: TClickType);
 function  IsMouseButtonHeld( button : TClickType) : boolean;
 procedure ClickMouse(button: TClickType);
 //Mouse movements implementation
 procedure WindMouse(xs, ys, xe, ye, gravity, wind, minWait, maxWait, maxStep, targetArea: extended);
 procedure MMouse(x, y, rx, ry: integer);
 procedure Mouse(mousex, mousey, ranx, rany: Integer; button: TClickType);
 procedure SleepAndMoveMouse(Time: Integer);
 procedure DragMouse(StartX, StartY, SRandX, SRandY, EndX, EndY, ERandX, ERandY: Integer);

 //Human-like mouse movements
 procedure BrakeWindMouse(xs, ys, xe, ye, gravity, wind, minWait, maxWait, targetArea: extended);
 procedure BrakeMMouse(eX, eY, ranX, ranY: Integer);
 procedure ShiftWindMouse(xs, ys, xe, ye, gravity, wind, minWait, maxWait, maxStep, targetArea: extended);
 procedure MissMouse(eX, eY, ranX, ranY: Integer);

 var
   MouseSpeed: integer=10;

 implementation
function RandomRange(const AFrom, ATo : Integer) : Integer ;
    var
      a : Integer;
    begin
      if ( AFrom <= ATo ) then
        a := AFrom
      else
        a := ATo;
      Result := a + Random(Abs(ATo - AFrom));
    end;
function Min(a,b:Extended ):Extended ;
{$IFNDEF TARGET_x86}
begin
 if a < b then
        result := a
    else
        result := b ;
{$ELSE}
asm
  cmp eax,edx
  ja @@bMin
  ret
@@bMin:
  mov eax,edx
  {$ENDIF}
end;

function Hypot(const X, Y: Extended): Extended;
{$IFNDEF TARGET_x86}
begin
  Result := Sqrt(Sqr(X) + Sqr(Y));
{$ELSE}
asm
        FLD     X
        FMUL    ST,ST
        FLD     Y
        FMUL    ST,ST
        FADDP   ST,ST
        FSQRT
        FWAIT
{$ENDIF}
end;

 procedure GetMousePosition(out x,y: integer);
 var
  MousePos: Windows.TPoint;
 begin
   Windows.GetCursorPos(MousePos);
   x:=MousePos.X;
   y:=MousePos.Y;
 end;

 procedure MoveMouse(x,y: integer);
 begin
   Windows.SetCursorPos(x, y);
 end;

 procedure HoldMouse(x,y: integer; button: TClickType);
 var
   Input : TInput;
 begin
   Input.Itype:= INPUT_MOUSE;
   FillChar(Input,Sizeof(Input),0);
   Input.mi.dx:= x;
   Input.mi.dy:= y;
   case button of
     Mouse_Left: Input.mi.dwFlags:= MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_LEFTDOWN;
     Mouse_Middle: Input.mi.dwFlags:= MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_MIDDLEDOWN;
     Mouse_Right: Input.mi.dwFlags:= MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_RIGHTDOWN;
   end;
   SendInput(1,Input, sizeof(Input));
 end;

 procedure ReleaseMouse(x,y: integer; button: TClickType);
 var
   Input : TInput;
   Rect : TRect;
 begin
   Input.Itype:= INPUT_MOUSE;
   FillChar(Input,Sizeof(Input),0);
   Input.mi.dx:= x + Rect.left;
   Input.mi.dy:= y + Rect.Top;
    case button of
      Mouse_Left: Input.mi.dwFlags:= MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_LEFTUP;
      Mouse_Middle: Input.mi.dwFlags:= MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_MIDDLEUP;
      Mouse_Right: Input.mi.dwFlags:= MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_RIGHTUP;
    end;
   SendInput(1,Input, sizeof(Input));
 end;

 function  IsMouseButtonHeld( button : TClickType) : boolean;
 begin
   case button of
      mouse_Left : Result := (GetAsyncKeyState(VK_LBUTTON) <> 0);
      mouse_Middle : Result := (GetAsyncKeyState(VK_MBUTTON) <> 0);
      mouse_Right : Result := (GetAsyncKeyState(VK_RBUTTON) <> 0);
   end;
 end;

 procedure ClickMouse(button: TClickType);
 var
   a,b,c : integer;
 begin
   { Eventually, should be made to just use Integers }
   GetMousePosition(b, c);
   HoldMouse(b, c, Button);
   repeat
     Sleep(20 + Random(30));
     a := a + 1;
   until (a > 4);
   GetMousePosition(b, c);
   ReleaseMouse(b, c, Button);
   Sleep(50+Random(50));
 end;
 {Moves the mouse along a spline defined by
     by Benland100
     Convert to Delphi by Cynic}
 procedure WindMouse(xs, ys, xe, ye, gravity, wind, minWait, maxWait, maxStep, targetArea: extended);
 var
   veloX, veloY, windX, windY, veloMag, dist, randomDist, lastDist, step: extended;
   lastX, lastY: integer;
   sqrt2, sqrt3, sqrt5: extended;
 begin
   Velox:=0;
   VeloY:=0;
   windX:=0;
   windY:=0;
   try
     sqrt2:= sqrt(2);
     sqrt3:= sqrt(3);
     sqrt5:= sqrt(5);
     while hypot(xs - xe, ys - ye) > 1 do
     begin
       dist:= hypot(xs - xe, ys - ye);
       wind:= min(wind, dist);
       if dist >= targetArea then
       begin
         windX:= windX / sqrt3 + (random(round(wind) * 2 + 1) - wind) / sqrt5;
         windY:= windY / sqrt3 + (random(round(wind) * 2 + 1) - wind) / sqrt5;
       end else
       begin
         windX:= windX / sqrt2;
         windY:= windY / sqrt2;
         if (maxStep < 3) then
         begin
           maxStep:= random(3) + 3.0;
         end else
         begin
           maxStep:= maxStep / sqrt5;
         end;
       end;
       veloX:= veloX + windX;
       veloY:= veloY + windY;
       veloX:= veloX + gravity * (xe - xs) / dist;
       veloY:= veloY + gravity * (ye - ys) / dist;
       if hypot(veloX, veloY) > maxStep then
       begin
         randomDist:= maxStep / 2.0 + random(round(maxStep) div 2);
         veloMag:= sqrt(veloX * veloX + veloY * veloY);
         veloX:= (veloX / veloMag) * randomDist;
         veloY:= (veloY / veloMag) * randomDist;
       end;
       lastX:= Round(xs);
       lastY:= Round(ys);
       xs:= xs + veloX;
       ys:= ys + veloY;
       if (lastX <> Round(xs)) or (lastY <> Round(ys)) then
         MoveMouse(Round(xs), Round(ys));
       step:= hypot(xs - lastX, ys - lastY);
       Sleep(round((maxWait - minWait) * (step / maxStep) + minWait));
       lastdist:= dist;
     end;
     if (Round(xe) <> Round(xs)) or (Round(ye) <> Round(ys)) then
       MoveMouse(Round(xe), Round(ye));
   except
   end;
 end;

 procedure MMouse(x, y, rx, ry: integer);
 var
   cx, cy: integer;
   randSpeed: Extended;
 begin
   GetMousePosition(cx, cy);
   randSpeed:= (random(MouseSpeed) / 2.0 + MouseSpeed) / 10.0;
   if randSpeed = 0.0 then
     randSpeed := 0.1;
   X := x + random(rx);
   Y := y + random(ry);
   WindMouse(cx,cy,x,y,9.0,3.0,10.0/randSpeed,15.0/randSpeed,10.0*randSpeed,10.0*randSpeed);
 end;

 procedure Mouse(mousex, mousey, ranx, rany: Integer; button: TClickType);
 begin
   MMouse(mousex, mousey, ranx, rany);
   Sleep(60 + Random(30));
   ClickMouse(button);
   Sleep(50 + Random(50));
 end;

 procedure SleepAndMoveMouse(Time: Integer);
 var
   Moving: Boolean;
   mx, my: Integer;
   x, y, xv, yv: Extended;
   gx, gy: Extended;
   T: Integer;
 begin
   GetMousePosition(mx, my);
   x := mx;
   y := my;
   if (Random(2) = 0) then
     Moving := False
   else
     Moving := True;
   gx := 130 + Random(500);
   gy := 130 + Random(300);
   T := GetTickCount;
   repeat
     Sleep(10);
     if (Moving) then
     begin
       if (gx > x) then
         xv := xv + 0.1
       else
         xv := xv - 0.1;
       if (gy > y) then
         yv := yv + 0.1
       else
         yv := yv - 0.1;
       x := x + xv;
       y := y + yv;
       MoveMouse(Round(x), Round(y));
     end;
     if (Random(100) = 0) then
       Moving := not Moving;
     if (Random(30) = 0) then
     begin
       gx := 130 + Random(500);
       gy := 130 + Random(300);
     end;
   until (Abs(GetTickCount - T) >= Time);
 end;

 procedure DragMouse(StartX, StartY, SRandX, SRandY, EndX, EndY, ERandX, ERandY: Integer);
 begin
   MMouse(StartX, StartY, SRandX, SRandY);
   Sleep(150 + Random(20));
   GetMousePosition(StartX, StartY);
   HoldMouse(StartX, StartY, mouse_left);
   Sleep(250 + Random(320));
   MMouse(EndX, EndY, ERandX, ERandY);
   Sleep(250 + Random(120));
   GetMousePosition(EndX, EndY);
   ReleaseMouse(EndX, EndY, mouse_left);
 end;

 function Distance(x1,y1,x2,y2 : integer) : integer;
 begin
   Result := Round(Sqrt(Sqr(x2-x1) + Sqr(y2-y1)));
 end;
 {*******************************************************************************
 procedure Procedure BrakeWindMouse(xs, ys, xe, ye, gravity, wind, minWait,
   maxWait, targetArea: extended);
 By: Flight
 Description: Mouse movement based on distance to determine speed.
              Default brake at 15%.
 *******************************************************************************}
 Procedure BrakeWindMouse(xs, ys, xe, ye, gravity, wind, minWait, maxWait, targetArea: extended);
 var
   veloX,veloY,windX,windY,veloMag,dist,randomDist,lastDist: extended;
   lastX,lastY,MSP,W,maxStep,D,TDist: integer;
   sqrt2,sqrt3,sqrt5,PDist: extended;
 begin
   veloX:=0;
   veloY:=0;
   windX:=0;
   windY:=0;
   MSP  := MouseSpeed;
   sqrt2:= sqrt(2);
   sqrt3:= sqrt(3);
   sqrt5:= sqrt(5);

   TDist := Distance(Round(xs), Round(ys), Round(xe), Round(ye));
   if (TDist < 1) then
     TDist := 1;
   repeat

     dist:= hypot(xs - xe, ys - ye);
     wind:= min(wind, dist);
     if (dist < 1) then
       dist := 1;
     PDist := (dist/TDist);
     if (PDist < 0.01) then
       PDist := 0.01;

     {
       These constants seem smooth to me, but
       feel free to modify these settings however
       you wish.
     }

     if (PDist >= 0.15) then                    //15% (or higher) dist to destination
     begin
       D := Round(Round((Round(dist)*0.3))/5);
       if (D < 20) then
         D := 20;
         //D := RandomRange(15, 25);                        {Original}
     end else if (PDist < 0.15) then
     begin
       if ((PDist <= 0.15) and (PDist >= 0.10)) then         //10%-15%
         D := RandomRange(8, 13)
       else if (PDist < 0.10) then                           //< 10%
         D := RandomRange(4, 7);
     end;

     if (D <= Round(dist)) then
       maxStep := D
     else
       maxStep := Round(dist);

     if dist >= targetArea then
     begin
       windX:= windX / sqrt3 + (random(round(wind) * 2 + 1) - wind) / sqrt5;
       windY:= windY / sqrt3 + (random(round(wind) * 2 + 1) - wind) / sqrt5;
     end else
     begin
       windX:= windX / sqrt2;
       windY:= windY / sqrt2;
     end;

     veloX:= veloX + windX;
     veloY:= veloY + windY;
     veloX:= veloX + gravity * (xe - xs) / dist;
     veloY:= veloY + gravity * (ye - ys) / dist;

     if hypot(veloX, veloY) > maxStep then
     begin
       randomDist:= maxStep / 2.0 + random(round(maxStep) div 2);
       veloMag:= sqrt(veloX * veloX + veloY * veloY);
       veloX:= (veloX / veloMag) * randomDist;
       veloY:= (veloY / veloMag) * randomDist;
     end;

     lastX:= Round(xs);
     lastY:= Round(ys);
     xs:= xs + veloX;
     ys:= ys + veloY;

     if (lastX <> Round(xs)) or (lastY <> Round(ys)) then
       MoveMouse(Round(xs), Round(ys));

     W := (Random(Round(100/MSP)))*6;
     if (W < 5) then
       W := 5;
     W := Round(W*1.2);
     Sleep(W);
     lastdist:= dist;
   until(hypot(xs - xe, ys - ye) < 1);

   if (Round(xe) <> Round(xs)) or (Round(ye) <> Round(ys)) then
     MoveMouse(Round(xe), Round(ye));
     MouseSpeed :=MSP;
 end;

 Procedure BrakeMMouse(eX, eY, ranX, ranY: Integer);
 var
   randSpeed: extended;
   X,Y,MS: integer;
 begin
   MS := MouseSpeed;
   randSpeed := (random(MouseSpeed) / 2.0 + MouseSpeed) / 10.0;
   GetMousePosition(X, Y);
   BrakeWindMouse(X, Y, eX, eY, 9, 5, 10.0 / randSpeed, 15.0 / randSpeed, 10.0 * randSpeed);
   MouseSpeed := MS;
 end;

 {*******************************************************************************
 procedure ShiftWindMouse(xs, ys, xe, ye, gravity, wind, minWait, maxWait, maxStep,
   targetArea: extended);
 By: Flight
 Description: Mouse movement that shifts speed after every mouse 'step'
 *******************************************************************************}
 procedure ShiftWindMouse(xs, ys, xe, ye, gravity, wind, minWait, maxWait, maxStep, targetArea: extended);
 var
   veloX,veloY,windX,windY,veloMag,dist,randomDist,lastDist,step: extended;
   lastX,lastY,MS: integer;
   sqrt2,sqrt3,sqrt5: extended;
 begin
   veloX:=0;
   veloY:=0;
   windX:=0;
   windY:=0;
   MS := MouseSpeed;
   sqrt2:= sqrt(2);
   sqrt3:= sqrt(3);
   sqrt5:= sqrt(5);
   while hypot(xs - xe, ys - ye) > 1 do
   begin
     dist:= hypot(xs - xe, ys - ye);
     wind:= min(wind, dist);
     if dist >= targetArea then
     begin
       windX:= windX / sqrt3 + (random(round(wind) * 2 + 1) - wind) / sqrt5;
       windY:= windY / sqrt3 + (random(round(wind) * 2 + 1) - wind) / sqrt5;
     end else
     begin
       windX:= windX / sqrt2;
       windY:= windY / sqrt2;
       if (maxStep < 3) then
       begin
         maxStep:= random(3) + 3.0;
       end else
       begin
         maxStep:= maxStep / sqrt5;
       end;
     end;
     veloX:= veloX + windX;
     veloY:= veloY + windY;
     veloX:= veloX + gravity * (xe - xs) / dist;
     veloY:= veloY + gravity * (ye - ys) / dist;
     if hypot(veloX, veloY) > maxStep then
     begin
       randomDist:= maxStep / 2.0 + random(round(maxStep) div 2);
       veloMag:= sqrt(veloX * veloX + veloY * veloY);
       veloX:= (veloX / veloMag) * randomDist;
       veloY:= (veloY / veloMag) * randomDist;
     end;
     lastX:= Round(xs);
     lastY:= Round(ys);
     xs:= xs + veloX;
     ys:= ys + veloY;

     case Random(2) of
       1: MouseSpeed := (MS + (RandomRange(2, 5)));
       2: MouseSpeed := (MS - (RandomRange(2, 5)));
     end;
     if (MouseSpeed < 4) then
       MouseSpeed := 4;

     if (lastX <> Round(xs)) or (lastY <> Round(ys)) then
       MoveMouse(Round(xs), Round(ys));

     step:= hypot(xs - lastX, ys - lastY);
     sleep(round((maxWait - minWait) * (step / maxStep) + minWait));
     lastdist:= dist;
     MouseSpeed := MS;
   end;

   case Random(2) of
     1: MouseSpeed := (MS + (RandomRange(2, 5)));
     2: MouseSpeed := (MS - (RandomRange(2, 5)));
   end;
   if (MouseSpeed < 4) then
       MouseSpeed := 4;

   if (Round(xe) <> Round(xs)) or (Round(ye) <> Round(ys)) then
     MoveMouse(Round(xe), Round(ye));
    MouseSpeed := MS;
 end;

 {*******************************************************************************
 procedure MissMouse(eX, eY, ranX, ranY: Integer);
 By: Flight
 Description: Makes use of ShiftWindMouse; it also initially misses the target
              point (miss area determined by dist & speed) then corrects itself.
 *******************************************************************************}
 Procedure MissMouse(eX, eY, ranX, ranY: Integer);
 var
   randSpeed: extended;
   X,Y,X2,Y2,A,Dist,MP: integer;
 begin
   A := MouseSpeed;
   GetMousePosition(X, Y);
   Dist := Distance(X, Y, eX, eY);
   MP := Round(Dist/150);
   if MP < 0 then
     MP := 1;
   randSpeed := (random(MouseSpeed) / 2.0 + MouseSpeed) / 10.0;
   X2 := RandomRange(eX-(A*MP), eX+(A*MP));
   Y2 := RandomRange(eY-(A*MP), eY+(A*MP));
   ShiftWindMouse(X, Y, X2, Y2, 11, 8, 10.0 / randSpeed, 12.0 / randSpeed, 10.0 * randSpeed, 10.0 * randSpeed);
   GetMousePosition(X, Y);
   MMouse(eX, eY, ranX, ranY);
   MouseSpeed := A;
 end;

 procedure FastClick(button: TClickType);
 var
   x, y: integer;
 begin
   GetMousePosition(x, y);
   HoldMouse(x, y, button);
   Sleep(RandomRange(60, 150));
   GetMousePosition(x, y);
   ReleaseMouse(x, y, button);
 end;

 end.

