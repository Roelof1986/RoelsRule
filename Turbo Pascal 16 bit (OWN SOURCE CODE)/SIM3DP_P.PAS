program Sim3DPolyPublic;

{$N+}

uses Crt, evBGIDr, Graph;

const MaxTriangles = 1720;

type IntTriangle = array[1..3] of record
                                    X, Y, Z : Integer;
                                  end;
     RealCo = record
                X, Y, Z : SINGLE;
              end;
     RealTriangle = array[1..3] of RealCo;
     TriangleCosType = array[1..MaxTriangles] of RealTriangle;
     StaticType = array[0..MaxTriangles] of RealTriangle;

var  Driver, Mode : Integer;

     Static : ^StaticType;
     TaCnt, i, j, Segments, Triangles, Radius, Page : Word;
     CoCnt : Byte;
     TempCo : record
                a, b : RealCo;
              end;
     Horizon : array[1..2] of RealCo;
     TriangleCos : ^TriangleCosType;
     Player : record
                Position : record
                             X, Y, Z : SINGLE;
                           end;
                Direction : record
                              XY, ZY : SINGLE;
                            end;
              end;
     PolyPoints : array[1..4] of PointType;
     TriangleSequence : array[1..MaxTriangles] of Word;
     Key : Char;
     ForwardSpeed, SidewardSpeed, LookXYSpeed, LookZYSpeed : SINGLE;

procedure Sort(Lo, Hi : Word);

var i, k, y : Word;
    ListSorted : Boolean;
begin
  k := Hi-1;
  repeat
    ListSorted := True;
    for i := 1 to k do
      if (TriangleCos^[TriangleSequence[i],1].Y
         + TriangleCos^[TriangleSequence[i],2].Y
         + TriangleCos^[TriangleSequence[i],3].Y) / 3
         < (TriangleCos^[TriangleSequence[i+1],1].Y
           + TriangleCos^[TriangleSequence[i+1],2].Y
           + TriangleCos^[TriangleSequence[i+1],3].Y) / 3 then
      begin
        y := TriangleSequence[i];
        TriangleSequence[i] := TriangleSequence[i+1];
        TriangleSequence[i+1] := y;
        ListSorted := False;
      end;
    Dec(k);
  until ListSorted;
end;

function Sign0(X : SINGLE): SINGLE;

begin
  if X <> 0 then
    Sign0 := X / Abs(X)
  else
    Sign0 := 0;
end;

function Sign1(X : SINGLE): SINGLE;

begin
  if X <> 0 then
    Sign1 := X / Abs(X)
  else
    Sign1 := 1;
end;

begin
  ClrScr;
  repeat
    GotoXY(1, 2);
    ClrEol;
    GotoXY(1, 1);
    Writeln('Number of segments in sphere');
    Write('From 4 (superfast) to 43 (slow): ');
    Readln(Segments);
  until (Segments >= 4) AND (Segments <= 43);
  Triangles := Segments*(Segments DIV 2)*2-Segments*2;
  Writeln;
  Write(Triangles, ' Triangles');
  repeat
    GotoXY(1, 7);
    ClrEol;
    GotoXY(1, 6);
    Writeln('Radius of sphere');
    Write('From 1 to 50: ');
    Readln(Radius);
  until (Radius >= 1) AND (Radius <= 50);
  if RegisterBGIdriver(@EGAVGADriver) < 0 then
  begin
    Writeln('EGA/VGA', ': ', GraphErrorMsg(GraphResult));
    Halt(1);
  end;
  Driver := EGA;
  Mode := EGAHi;
  InitGraph(Driver, Mode, '');
  New(Static);
  TaCnt := 1;
  Static^[0,1].X := 1;
  Static^[0,1].Y := 1;
  Static^[0,1].Z := 1;
  for i := 0 to Segments DIV 2 - 1 do
    for j := 0 to Segments - 1 do
      begin
        Static^[TaCnt,1].X := (Sin((j/Segments)*2*Pi)*Sin((i/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,1].Y := (Cos((j/Segments)*2*Pi)*Sin((i/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,1].Z := (Cos((i/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,2].X := (Sin((j/Segments)*2*Pi)*Sin(((i+1)/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,2].Y := (Cos((j/Segments)*2*Pi)*Sin(((i+1)/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,2].Z := (Cos(((i+1)/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,3].X := (Sin(((j+1)/Segments)*2*Pi)*Sin(((i+1)/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,3].Y := (Cos(((j+1)/Segments)*2*Pi)*Sin(((i+1)/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,3].Z := (Cos(((i+1)/((Segments DIV 2)*2))*2*Pi)*Radius);
        if (Static^[TaCnt,2].X <> Static^[TaCnt,3].X) OR (Static^[TaCnt,2].Y <> Static^[TaCnt,3].Y) then
          Inc(TaCnt);
        Static^[TaCnt,1].X := (Sin((j/Segments)*2*Pi)*Sin((i/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,1].Y := (Cos((j/Segments)*2*Pi)*Sin((i/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,1].Z := (Cos((i/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,2].X := (Sin(((j+1)/Segments)*2*Pi)*Sin((i/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,2].Y := (Cos(((j+1)/Segments)*2*Pi)*Sin((i/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,2].Z := (Cos((i/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,3].X := (Sin(((j+1)/Segments)*2*Pi)*Sin(((i+1)/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,3].Y := (Cos(((j+1)/Segments)*2*Pi)*Sin(((i+1)/((Segments DIV 2)*2))*2*Pi)*Radius);
        Static^[TaCnt,3].Z := (Cos(((i+1)/((Segments DIV 2)*2))*2*Pi)*Radius);
        if (Static^[TaCnt,1].X <> Static^[TaCnt,2].X) OR (Static^[TaCnt,1].Y <> Static^[TaCnt,2].Y) then
          Inc(TaCnt);
      end;

  Player.Position.X := 0;
  Player.Position.Y := -100;
  Player.Position.Z := 1;
  Player.Direction.XY := 0;
  Player.Direction.ZY := 0;
  SetColor(15);
  Outtext('Press a move key to start...');
  ForwardSpeed := 0;
  SidewardSpeed := 0;
  LookXYSpeed := 0;
  LookZYSpeed := 0;
  repeat
  if Keypressed then
  begin
    repeat
      Key := Readkey;
    until Key > Chr(0);
  case Key of
    Chr(77) : LookXYSpeed := LookXYSpeed + 0.0032;
    Chr(75) : LookXYSpeed := LookXYSpeed - 0.0032;
    Chr(72) : LookZYSpeed := LookZYSpeed + 0.0032;
    Chr(80) : LookZYSpeed := LookZYSpeed - 0.0032;
    'w'     : ForwardSpeed := ForwardSpeed + 3;
    's'     : ForwardSpeed := ForwardSpeed - 3;
    'a'     : SidewardSpeed := SidewardSpeed - 0.3;
    'd'     : SidewardSpeed := SidewardSpeed + 0.3;
    'r'     : LookXYSpeed := LookXYSpeed + Pi/4;
    'e'     : LookXYSpeed := LookXYSpeed - Pi/8;
    't'     : LookXYSpeed := LookXYSpeed + Pi/8;
    'f'     : LookZYSpeed := LookZYSpeed - (0.4*Pi)/4;
    'g'     : LookZYSpeed := LookZYSpeed + (0.4*Pi)/4;
  end;
  end;
  ForwardSpeed := ForwardSpeed / 1.25;
  SidewardSpeed := SidewardSpeed / 1.25;
  LookXYSpeed := LookXYSpeed / 1.25;
  LookZYSpeed := LookZYSpeed / 1.25;
  Player.Position.X := Sin(Player.Direction.XY)*Cos(Player.Direction.ZY)*ForwardSpeed+Player.Position.X;
  Player.Position.Y := Cos(Player.Direction.XY)*Cos(Player.Direction.ZY)*ForwardSpeed+Player.Position.Y;
  Player.Position.Z := Sin(Player.Direction.ZY)*ForwardSpeed+Player.Position.Z;
  Player.Position.X := Sin(Player.Direction.XY+0.5*Pi)*SidewardSpeed+Player.Position.X;
  Player.Position.Y := Cos(Player.Direction.XY+0.5*Pi)*SidewardSpeed+Player.Position.Y;
  Player.Direction.XY := Player.Direction.XY + LookXYSpeed;
  if Player.Direction.XY > 2*Pi then
    Player.Direction.XY := Player.Direction.XY - 2*Pi
  else
    if Player.Direction.XY < -2*Pi then
      Player.Direction.XY := Player.Direction.XY + 2*Pi;
  Player.Direction.ZY := Player.Direction.ZY + LookZYSpeed;
  if Player.Direction.ZY > 0.4*Pi then
    Player.Direction.ZY := 0.4*Pi
  else
    if Player.Direction.ZY < -0.4*Pi then
      Player.Direction.ZY := -0.4*Pi;
  if (Round(ForwardSpeed*500) <> 0) OR (Round(SidewardSpeed*500) <> 0)
     OR (Round(LookXYSpeed*10000) <> 0) OR (Round(LookZYSpeed*10000) <> 0) then
  begin
  New(TriangleCos);
  for TaCnt := 1 to Triangles do
  for CoCnt := 1 to 3 do
  begin
    TempCo.a.X := Static^[TaCnt,CoCnt].X / Static^[0,1].X - Player.Position.X;
    TempCo.a.Y := Static^[TaCnt,CoCnt].Y / Static^[0,1].Y - Player.Position.Y;
    TempCo.a.Z := Static^[TaCnt,CoCnt].Z / Static^[0,1].Z - Player.Position.Z;
    TempCo.b.X := Sin(ArcTan(TempCo.a.X/TempCo.a.Y)+Pi*Sign1(TempCo.a.X)
    *Sign0(TempCo.a.Y-Abs(TempCo.a.Y))-Player.Direction.XY)
    *Sqrt(Sqr(TempCo.a.X)+Sqr(TempCo.a.Y));
    TempCo.b.Y := Cos(ArcTan(TempCo.a.X/TempCo.a.Y)+Pi*Sign1(TempCo.a.X)
    *Sign0(TempCo.a.Y-Abs(TempCo.a.Y))-Player.Direction.XY)
    *Sqrt(Sqr(TempCo.a.X)+Sqr(TempCo.a.Y));
    TempCo.a.Y := TempCo.b.Y;
    TempCo.b.Z := Sin(ArcTan(TempCo.a.Z/TempCo.a.Y)+Pi*Sign1(TempCo.a.Z)
    *Sign0(TempCo.a.Y-Abs(TempCo.a.Y))-Player.Direction.ZY)
    *Sqrt(Sqr(TempCo.a.Z)+Sqr(TempCo.a.Y));
    TempCo.b.Y := Cos(ArcTan(TempCo.a.Z/TempCo.a.Y)+Pi*Sign1(TempCo.a.Z)
    *Sign0(TempCo.a.Y-Abs(TempCo.a.Y))-Player.Direction.ZY)
    *Sqrt(Sqr(TempCo.a.Z)+Sqr(TempCo.a.Y));
    TriangleCos^[TaCnt,CoCnt] := TempCo.b;
  end;
  for TaCnt := 1 to Triangles do
    TriangleSequence[TaCnt] := TaCnt;
  Sort(1, Triangles);
  Page := NOT Page;
  SetVisualPage(Page);
  Delay(25);
  SetActivePage(NOT Page);
  for CoCnt := 1 to 2 do
  begin
    TempCo.b.X := (CoCnt-1.5)*100000;
    TempCo.b.Z := Sin(Player.Direction.ZY)*1000;
    TempCo.b.Y := Cos(Player.Direction.ZY)*1000;
    Horizon[CoCnt] := TempCo.b;
  end;
  ClearDevice;
  SetFillStyle(1, 9);
  Bar(Round({ArcTan}(Horizon[1].X/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round({ArcTan}(Horizon[1].Z/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxY/2),
      Round({ArcTan}(Horizon[2].X/Horizon[2].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round(-(100/1E-3)/(1.5/GetMaxX)+GetMaxY/2));
  SetFillStyle(1, 2);
  Bar(Round({ArcTan}(Horizon[1].X/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round({ArcTan}(Horizon[1].Z/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxY/2),
      Round({ArcTan}(Horizon[2].X/Horizon[2].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round(-(-100/1E-3)/(1.5/GetMaxX)+GetMaxY/2));
  SetFillStyle(1, 12);
  for TaCnt := 1 to Triangles do
  begin
    if (TriangleCos^[TriangleSequence[TaCnt],1].Y > 0) AND
       (TriangleCos^[TriangleSequence[TaCnt],2].Y > 0) AND
       (TriangleCos^[TriangleSequence[TaCnt],3].Y > 0) then
    begin
      for CoCnt := 0 to 3 do
      begin
        PolyPoints[CoCnt + 1].X := Round({ArcTan}(TriangleCos^[TriangleSequence[TaCnt],(CoCnt MOD 3) + 1].X
          /TriangleCos^[TriangleSequence[TaCnt],(CoCnt MOD 3) + 1].Y)
          /(1.5/GetMaxX)+GetMaxX/2);
        PolyPoints[CoCnt + 1].Y := Round(-{ArcTan}(TriangleCos^[TriangleSequence[TaCnt],(CoCnt MOD 3) + 1].Z
          /TriangleCos^[TriangleSequence[TaCnt],(CoCnt MOD 3) + 1].Y)
          /(1.5/GetMaxX)+GetMaxY/2);
      end;
      FillPoly(4, PolyPoints);
    end;
  end;
  Dispose(TriangleCos);
  end;
  until Key = Chr(27);
  Dispose(Static);
  CloseGraph;
end.