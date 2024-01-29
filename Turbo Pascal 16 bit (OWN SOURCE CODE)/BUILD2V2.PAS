//--------------------------------\\
//  Build 2v2 (Oktober 2004)              \\
//  Author: Roelof Emmerink       \\
//  E-mail: rpe86@hotmail.com     \\
//--------------------------------\\
program LearnAndGenerateBuildingsGraphicCos2v2;

{$N+}

uses Crt, Dos, evBGIDr, Graph;

const
  NeuronsInHiddenLayers = 7;
  Inputs = 2; {<= NeuronsInHiddenLayers}
  Outputs = 3; {<= NeuronsInHiddenLayers}
  HiddenLayers = 5; {>= 1}
  Eta = 0.1;



  MaxTriangles = 1720;

type


     IntTriangle = array[1..3] of record
                                    X, Y, Z : Integer;
                                  end;
     RealCo = record
                X, Y, Z : SINGLE;
              end;
     RealTriangle = array[1..3] of RealCo;
     TriangleCosType = array[1..MaxTriangles] of RealTriangle;
     StaticType = array[0..MaxTriangles] of RealTriangle;


var
  Weight : array[1..HiddenLayers+1,0..NeuronsInHiddenLayers,1..NeuronsInHiddenLayers] of SINGLE;
  i, j, k, w, n, o, l, PriLoop, ChNr, Patterns : Integer;
  Output, ErrorOutput : array[1..HiddenLayers+1,1..NeuronsInHiddenLayers] of SINGLE;
  OutputWished : array[1..1000,1..Outputs] of SINGLE;
  Input : array[1..1000,1..Inputs] of SINGLE;
  Iterations : Longint;
  Z : SINGLE;
  C : Char;
  Fw : file of SINGLE;
  Fp : file of SINGLE;

  IndependentInput : Integer;
  IndependentOutput : Integer;



     Driver, Mode : Integer;

     CoBuffer : array[0..15*2-1,0..15*2-1] of RealCo;
     Static : ^StaticType;
     TaCnt, i2, j2, Segments, Triangles, Radius, Page,
       Layers, CosPerLayer, VPL, VPC : Word;
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
     ForwardSpeed, SidewardSpeed, LookXYSpeed, LookZYSpeed,
     LayerHeight : SINGLE;

     CP : record
            X, Y : Integer;
          end;
     Flag, CPSpeed, AdjustHeight : Boolean;
     Step : Longint;

procedure PropagateForward;

begin
  for i := 1 to NeuronsInHiddenLayers do
  begin
    Z := Weight[1,0,i];
    for j := 1 to Inputs do
      Z := Input[w,j] * Weight[1,j,i] + Z;
    Output[1,i] := 1/(1+Exp(-Z));
  end;
  if HiddenLayers >= 2 then
    for l := 2 to HiddenLayers do
      for i := 1 to NeuronsInHiddenLayers do
      begin
        Z := Weight[l,0,i];
        for j := 1 to NeuronsInHiddenLayers do
          Z := Output[l-1,j] * Weight[l,j,i] + Z;
        Output[l,i] := 1/(1+Exp(-Z));
      end;
  l := HiddenLayers+1;
  for i := 1 to Outputs do
  begin
    Z := Weight[l,0,i];
    for j := 1 to NeuronsInHiddenLayers do
      Z := Output[l-1,j] * Weight[l,j,i] + Z;
    Output[l,i] := 1/(1+Exp(-Z));
  end;
end;

procedure PropagateBack;

begin
  for i := 1 to Outputs do
    ErrorOutput[HiddenLayers+1,i] := (OutputWished[w,i] - Output[HiddenLayers+1,i])
     *Output[HiddenLayers+1,i]*(1-Output[HiddenLayers+1,i]);
  l := HiddenLayers;
  for i := 1 to NeuronsInHiddenLayers do
  begin
    Z := 0;
    for j := 1 to Outputs do
      Z := ErrorOutput[l+1,j] * Weight[l+1,i,j] + Z;
    ErrorOutput[l,i] := Z*Output[l,i]*(1-Output[l,i]);
  end;
  if HiddenLayers >= 2 then
    for l := HiddenLayers-1 downto 1 do
      for i := 1 to NeuronsInHiddenLayers do
      begin
        Z := 0;
        for j := 1 to NeuronsInHiddenLayers do
          Z := ErrorOutput[l+1,j] * Weight[l+1,i,j] + Z;
        ErrorOutput[l,i] := Z*Output[l,i]*(1-Output[l,i]);
      end;
  for j := 1 to NeuronsInHiddenLayers do
  begin
    Weight[1,0,j] := ErrorOutput[1,j] * Eta + Weight[1,0,j];
    for i := 1 to Inputs do
      Weight[1,i,j] := ErrorOutput[1,j] * Input[w,i] * Eta + Weight[1,i,j];
  end;
  if HiddenLayers >= 2 then
    for l := 2 to HiddenLayers do
      for j := 1 to NeuronsInHiddenLayers do
      begin
        Weight[l,0,j] := ErrorOutput[l,j] * Eta + Weight[l,0,j];
        for i := 1 to NeuronsInHiddenLayers do
          Weight[l,i,j] := ErrorOutput[l,j] * Output[l-1,i] * Eta + Weight[l,i,j];
      end;
  l := HiddenLayers+1;
  for j := 1 to Outputs do
  begin
    Weight[l,0,j] := ErrorOutput[l,j] * Eta + Weight[l,0,j];
    for i := 1 to NeuronsInHiddenLayers do
      Weight[l,i,j] := ErrorOutput[l,j] * Output[l-1,i] * Eta + Weight[l,i,j];
  end;
end;

function PowerXN(X : Longint; N : Byte) : Longint;
begin
  if x=0 then PowerXN:=0;
  if n=0
     then PowerXN:= 1
     else PowerXN:= x * PowerXN(x, n-1);
end;

procedure ViewValue(Value : SINGLE; Digits : Byte);

var i, Digit : Byte;
    LimitedValue : Longint;
    NonZeroDisplayed : Boolean;

begin
  NonZeroDisplayed := False;
  LimitedValue := Round(Value*PowerXN(10,Digits));
  for i := Digits+1 downto 1 do
  begin
    Digit := (LimitedValue MOD PowerXN(10,i)) DIV PowerXN(10,i-1);
    case Digit of
      0 : if NonZeroDisplayed OR (i = 1) then
            Outtext('0')
          else
            Outtext(' ');
      1 : begin
            NonZeroDisplayed := True;
            Outtext('1');
          end;
      2 : begin
            NonZeroDisplayed := True;
            Outtext('2');
          end;
      3 : begin
            NonZeroDisplayed := True;
            Outtext('3');
          end;
      4 : begin
            NonZeroDisplayed := True;
            Outtext('4');
          end;
      5 : begin
            NonZeroDisplayed := True;
            Outtext('5');
          end;
      6 : begin
            NonZeroDisplayed := True;
            Outtext('6');
          end;
      7 : begin
            NonZeroDisplayed := True;
            Outtext('7');
          end;
      8 : begin
            NonZeroDisplayed := True;
            Outtext('8');
          end;
      9 : begin
            NonZeroDisplayed := True;
            Outtext('9');
          end;
    end;
  end;
end;

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
  if RegisterBGIdriver(@EGAVGADriver) < 0 then
  begin
    Writeln('EGA/VGA', ': ', GraphErrorMsg(GraphResult));
    Halt(1);
  end;
  Driver := EGA;
  Mode := EGAHi;
  Assign(Fw, 'Weights.bpn');
  Assign(Fp, 'Patterns.bpn');
  Randomize;
  ClrScr;
  Writeln('Load saved weights? (Y/N)');
  repeat
    C := Readkey;
  until (C = 'y') OR (C = 'Y') OR (C = 'n') OR (C = 'N');
  if (C = 'y') OR (C = 'Y') then
  begin
    Reset(Fw);
    for l := 1 to HiddenLayers+1 do
      for i := 0 to NeuronsInHiddenLayers do
        for j := 1 to NeuronsInHiddenLayers do
          begin
            Read(Fw, Z);
            Weight[l,i,j] := Z;
          end;
    Close(Fw);
  end
  else
  begin
    for l := 1 to HiddenLayers+1 do
      for i := 1 to NeuronsInHiddenLayers do
        for j := 1 to NeuronsInHiddenLayers do
          Weight[l,i,j] := (Random-0.5){*(1/NeuronsInHiddenLayers)};
  end;
  ClrScr;
  Writeln('Load saved patterns? (Y/N)');
  repeat
    C := Readkey;
  until (C = 'y') OR (C = 'Y') OR (C = 'n') OR (C = 'N');
  if (C = 'y') OR (C = 'Y') then
  begin
    Reset(Fp);
    Read(Fp, Z);
    Patterns := Round(Z);
    Read(Fp, Z);
    Layers := Round(Z);
    VPL := Round(Z);
    Read(Fp, Z);
    CosPerLayer := Round(Z);
    VPC := Round(Z);
    for w := 1 to Patterns do
      for i := 1 to Inputs do
      begin
        Read(Fp, Z);
        Input[w,i] := Z;
      end;
    for w := 1 to Patterns do
      for i := 1 to Outputs do
      begin
        Read(Fp, Z);
        OutputWished[w,i] := Z;
      end;
    Close(Fp);
  end
  else
  begin
    ClrScr;
    Write('Number of layers (min. 2, max. 15): ');
    repeat
      Readln(Layers);
      GotoXY(29, 1);
      ClrEol;
    until (Layers >= 2) AND (Layers <= 15);
    VPL := Layers;
    ClrScr;
    Write('Number of coordinates per layer (min. 2, max. 15): ');
    repeat
      Readln(CosPerLayer);
      GotoXY(44, 1);
      ClrEol;
    until (CosPerLayer >= 2) AND (CosPerLayer <= 15);
    VPC := CosPerLayer;
    InitGraph(Driver, Mode, '');
    w := 1;
    for i := 0 to Layers-1 do
    begin
      if i > 0 then
        for k := i*CosPerLayer+1 to (i+1)*CosPerLayer do
        begin
          OutputWished[k,1] := OutputWished[k-CosPerLayer,1];
          OutputWished[k,2] := OutputWished[k-CosPerLayer,2];
          OutputWished[k,3] := OutputWished[k-CosPerLayer,3];
        end;
      for j := 0 to CosPerLayer-1 do
      begin
      CP.X := Round(OutputWished[w,1]*GetMaxY+(GetMaxX-GetMaxY));
      CP.Y := Round(GetMaxY-OutputWished[w,2]*GetMaxY);
      Flag := False;
      C := Chr(1);
      CPSpeed := True;
      repeat
      if Keypressed then
        repeat
          C := ReadKey;
        until Ord(C) > 0;
        if Ord(C) > 0 then
        begin
        if CPSpeed then
          Step := 10
        else
          Step := 1;
        case Ord(C) of
          32 : CPSpeed := NOT CPSpeed;
          122 OR 90 : AdjustHeight := NOT AdjustHeight;
          13 : Flag := True;
        end;
        if AdjustHeight then
        case Ord(C) of
          80 : if LayerHeight >= Step/GetMaxY then
                 LayerHeight := LayerHeight - Step/GetMaxY
               else
                 LayerHeight := 0;
          72 : if LayerHeight <= 1-Step/GetMaxY then
                 LayerHeight := LayerHeight + Step/GetMaxY
               else
                 LayerHeight := 1;
        end
        else
        case Ord(C) of
          75 : if CP.X-Step >= GetMaxX-GetMaxY then
                 Dec(CP.X, Step)
               else
                 CP.X := GetMaxX-GetMaxY;
          77 : if CP.X+Step <= GetMaxX then
                 Inc(CP.X, Step)
               else
                 CP.X := GetMaxX;
          80 : if CP.Y+Step <= GetMaxY then
                 Inc(CP.Y, Step)
               else
                 CP.Y := GetMaxY;
          72 : if CP.Y-Step >= 0 then
                 Dec(CP.Y, Step)
               else
                 CP.Y := 0;
        end;

        if CPSpeed then
          Step := 10
        else
          Step := 1;
        OutputWished[w,1] := Round(((CP.X-(GetMaxX-GetMaxY))/GetMaxY)*100)/100;
        OutputWished[w,2] := Round(((GetMaxY-CP.Y)/GetMaxY)*100)/100;
        SetActivePage(NOT Page);
        ClearDevice;
        if j = 0 then
          OuttextXY(0, 0, '1st co-ordinate of layer');
        if AdjustHeight then
        begin
          OuttextXY(0, 25, 'Adjust Z of layer');
          for k := i*CosPerLayer+1 to (i+1)*CosPerLayer do
            OutputWished[k,3] := Round(LayerHeight*100)/100;
        end;
        MoveTo(0, 50);
        OutText('(');
        ViewValue(OutputWished[w,1], 2);
        OutText(', ');
        ViewValue(OutputWished[w,2], 2);
        OutText(', ');
        ViewValue(OutputWished[w,3], 2);
        OutText(')');
        if j > 0 then
        begin
          for k := i*CosPerLayer+1 to w-1 do
            Line(Round(OutputWished[k,1]*GetMaxY+(GetMaxX-GetMaxY)), Round(GetMaxY-OutputWished[k,2]*GetMaxY),
                 Round(OutputWished[k+1,1]*GetMaxY+(GetMaxX-GetMaxY)), Round(GetMaxY-OutputWished[k+1,2]*GetMaxY));
          if j = CosPerLayer-1 then
            Line(Round(OutputWished[w,1]*GetMaxY+(GetMaxX-GetMaxY)), Round(GetMaxY-OutputWished[w,2]*GetMaxY),
                 Round(OutputWished[w-CosPerLayer+1,1]*GetMaxY+(GetMaxX-GetMaxY)),
                 Round(GetMaxY-OutputWished[w-CosPerLayer+1,2]*GetMaxY));
        end
        else
          PutPixel(CP.X, CP.Y, 15);
{3d venstertje}
  New(Static);
  TaCnt := 1;
  Static^[0,1].X := 1;
  Static^[0,1].Y := 1;
  Static^[0,1].Z := 1;
  for i2 := 0 to VPL-1 do
    for j2 := 0 to VPC-1 do
    begin
      CoBuffer[i2,j2].X := OutputWished[i2*CosPerLayer+j2+1,1]-0.5;
      CoBuffer[i2,j2].Y := OutputWished[i2*CosPerLayer+j2+1,2]-0.5;
      CoBuffer[i2,j2].Z := OutputWished[i2*CosPerLayer+j2+1,3]-0.5;
    end;
  for i2 := 0 to VPL-2 do
    for j2 := 0 to VPC-1 do
    begin
      Static^[TaCnt,1].X := 0.05*Round(20*CoBuffer[i2,j2].X);
      Static^[TaCnt,1].Y := 0.05*Round(20*CoBuffer[i2,j2].Y);
      Static^[TaCnt,1].Z := 0.05*Round(20*CoBuffer[i2,j2].Z);
      Static^[TaCnt,2].X := 0.05*Round(20*CoBuffer[i2,(j2+1) MOD VPC].X);
      Static^[TaCnt,2].Y := 0.05*Round(20*CoBuffer[i2,(j2+1) MOD VPC].Y);
      Static^[TaCnt,2].Z := 0.05*Round(20*CoBuffer[i2,(j2+1) MOD VPC].Z);
      Static^[TaCnt,3].X := 0.05*Round(20*CoBuffer[i2+1,j2].X);
      Static^[TaCnt,3].Y := 0.05*Round(20*CoBuffer[i2+1,j2].Y);
      Static^[TaCnt,3].Z := 0.05*Round(20*CoBuffer[i2+1,j2].Z);
      Inc(TaCnt);
      Static^[TaCnt,1].X := 0.05*Round(20*CoBuffer[i2,(j2+1) MOD VPC].X);
      Static^[TaCnt,1].Y := 0.05*Round(20*CoBuffer[i2,(j2+1) MOD VPC].Y);
      Static^[TaCnt,1].Z := 0.05*Round(20*CoBuffer[i2,(j2+1) MOD VPC].Z);
      Static^[TaCnt,2].X := 0.05*Round(20*CoBuffer[i2+1,j2].X);
      Static^[TaCnt,2].Y := 0.05*Round(20*CoBuffer[i2+1,j2].Y);
      Static^[TaCnt,2].Z := 0.05*Round(20*CoBuffer[i2+1,j2].Z);
      Static^[TaCnt,3].X := 0.05*Round(20*CoBuffer[i2+1,(j2+1) MOD VPC].X);
      Static^[TaCnt,3].Y := 0.05*Round(20*CoBuffer[i2+1,(j2+1) MOD VPC].Y);
      Static^[TaCnt,3].Z := 0.05*Round(20*CoBuffer[i2+1,(j2+1) MOD VPC].Z);
      Inc(TaCnt);
    end;
  Triangles := TaCnt-1;

  Player.Position.X := 1.25;
  Player.Position.Y := -2.5;
  Player.Position.Z := 1;
  Player.Direction.XY := -Pi/7;
  Player.Direction.ZY := -Pi/10;


  ForwardSpeed := 0;
  SidewardSpeed := 0;
  LookXYSpeed := 0;
  LookZYSpeed := 0;
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
{  Page := NOT Page;
  SetVisualPage(Page);
  Delay(25);
  SetActivePage(NOT Page);}
  for CoCnt := 1 to 2 do
  begin
    TempCo.b.X := (CoCnt-1.5)*100000;
    TempCo.b.Z := Sin(Player.Direction.ZY)*1000;
    TempCo.b.Y := Cos(Player.Direction.ZY)*1000;
    Horizon[CoCnt] := TempCo.b;
  end;
{  ClearDevice;
  SetFillStyle(1, 9);
  Bar(Round((Horizon[1].X/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round((Horizon[1].Z/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxY/2),
      Round((Horizon[2].X/Horizon[2].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round(-(100/1E-3)/(1.5/GetMaxX)+GetMaxY/2));
  SetFillStyle(1, 2);
  Bar(Round((Horizon[1].X/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round((Horizon[1].Z/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxY/2),
      Round((Horizon[2].X/Horizon[2].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round(-(-100/1E-3)/(1.5/GetMaxX)+GetMaxY/2));}
  SetFillStyle(1, 12);
  for TaCnt := 1 to Triangles do
  begin
    if (TriangleCos^[TriangleSequence[TaCnt],1].Y > 0) AND
       (TriangleCos^[TriangleSequence[TaCnt],2].Y > 0) AND
       (TriangleCos^[TriangleSequence[TaCnt],3].Y > 0) then
    begin
      for CoCnt := 0 to 3 do
      begin
        PolyPoints[CoCnt + 1].X := Round((TriangleCos^[TriangleSequence[TaCnt],(CoCnt MOD 3) + 1].X
          /TriangleCos^[TriangleSequence[TaCnt],(CoCnt MOD 3) + 1].Y)
          /(1.5/GetMaxX)+GetMaxX/5);
        PolyPoints[CoCnt + 1].Y := Round(-(TriangleCos^[TriangleSequence[TaCnt],(CoCnt MOD 3) + 1].Z
          /TriangleCos^[TriangleSequence[TaCnt],(CoCnt MOD 3) + 1].Y)
          /(1.5/GetMaxX)+GetMaxY/2);
      end;
      FillPoly(4, PolyPoints);
    end;
  end;
  Page := NOT Page;
  SetVisualPage(Page);
  Delay(8);
  Dispose(TriangleCos);

  Dispose(Static);
{3d venstertje}

      end;
      C := Chr(0);
      until Flag;
      Input[w,1] := Int(i)/Int(Layers-1);
      Input[w,2] := Int(j)/Int(CosPerLayer-1);
      Inc(w);
      end;
    end;
    Patterns := w-1;
    CloseGraph;
  end;
  ClrScr;
  Writeln('(T)rain or (U)se Network?');
  repeat
    C := Readkey;
  until (C = 't') OR (C = 'T') OR (C = 'u') OR (C = 'U');
  if (C = 't') OR (C = 'T') then
  begin
  ClrScr;
  Writeln('List (N)umbers or draw (G)raphic?');
  repeat
    C := Readkey;
  until (C = 'n') OR (C = 'N') OR (C = 'g') OR (C = 'G');
  if (C = 'g') OR (C = 'G') then
  begin
    ClrScr;
    Writeln('Please wait...');
    Delay(200);
    InitGraph(Driver, Mode, '');
  end;
  Iterations := 0;
  repeat
  for w := 1 to Patterns do
  begin
  PropagateForward;
  PropagateBack;
  end;
  if Iterations / 1000 = Round(Iterations / 1000) then
  begin
  if (C = 'g') OR (C = 'G') then
  begin
  New(Static);
  TaCnt := 1;
  Static^[0,1].X := 1;
  Static^[0,1].Y := 1;
  Static^[0,1].Z := 1;
  w := 1000;
  for i2 := 0 to VPL-1 do
    for j2 := 0 to VPC-1 do
    begin
      Input[w,1] := i2/(VPL-1);
      Input[w,2] := j2/(VPC-1);
      PropagateForward;
      CoBuffer[i2,j2].X := Output[HiddenLayers+1,1]-0.5;
      CoBuffer[i2,j2].Y := Output[HiddenLayers+1,2]-0.5;
      CoBuffer[i2,j2].Z := Output[HiddenLayers+1,3]-0.5;
    end;
  for i := 0 to VPL-2 do
    for j := 0 to VPC-1 do
    begin
      Static^[TaCnt,1].X := 0.05*Round(20*CoBuffer[i,j].X);
      Static^[TaCnt,1].Y := 0.05*Round(20*CoBuffer[i,j].Y);
      Static^[TaCnt,1].Z := 0.05*Round(20*CoBuffer[i,j].Z);
      Static^[TaCnt,2].X := 0.05*Round(20*CoBuffer[i,(j+1) MOD VPC].X);
      Static^[TaCnt,2].Y := 0.05*Round(20*CoBuffer[i,(j+1) MOD VPC].Y);
      Static^[TaCnt,2].Z := 0.05*Round(20*CoBuffer[i,(j+1) MOD VPC].Z);
      Static^[TaCnt,3].X := 0.05*Round(20*CoBuffer[i+1,j].X);
      Static^[TaCnt,3].Y := 0.05*Round(20*CoBuffer[i+1,j].Y);
      Static^[TaCnt,3].Z := 0.05*Round(20*CoBuffer[i+1,j].Z);
      Inc(TaCnt);
      Static^[TaCnt,1].X := 0.05*Round(20*CoBuffer[i,(j+1) MOD VPC].X);
      Static^[TaCnt,1].Y := 0.05*Round(20*CoBuffer[i,(j+1) MOD VPC].Y);
      Static^[TaCnt,1].Z := 0.05*Round(20*CoBuffer[i,(j+1) MOD VPC].Z);
      Static^[TaCnt,2].X := 0.05*Round(20*CoBuffer[i+1,j].X);
      Static^[TaCnt,2].Y := 0.05*Round(20*CoBuffer[i+1,j].Y);
      Static^[TaCnt,2].Z := 0.05*Round(20*CoBuffer[i+1,j].Z);
      Static^[TaCnt,3].X := 0.05*Round(20*CoBuffer[i+1,(j+1) MOD VPC].X);
      Static^[TaCnt,3].Y := 0.05*Round(20*CoBuffer[i+1,(j+1) MOD VPC].Y);
      Static^[TaCnt,3].Z := 0.05*Round(20*CoBuffer[i+1,(j+1) MOD VPC].Z);
      Inc(TaCnt);
    end;
  Triangles := TaCnt-1;

  Player.Position.X := 1;
  Player.Position.Y := -2;
  Player.Position.Z := 1;
  Player.Direction.XY := -Pi/7;
  Player.Direction.ZY := -Pi/7;


  ForwardSpeed := 0;
  SidewardSpeed := 0;
  LookXYSpeed := 0;
  LookZYSpeed := 0;
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
{ if (Round(ForwardSpeed*500) <> 0) OR (Round(SidewardSpeed*500) <> 0)
     OR (Round(LookXYSpeed*10000) <> 0) OR (Round(LookZYSpeed*10000) <> 0) then
  begin}
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
{  SetFillStyle(1, 9);
  Bar(Round((Horizon[1].X/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round((Horizon[1].Z/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxY/2),
      Round((Horizon[2].X/Horizon[2].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round(-(100/1E-3)/(1.5/GetMaxX)+GetMaxY/2));
  SetFillStyle(1, 2);
  Bar(Round((Horizon[1].X/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round((Horizon[1].Z/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxY/2),
      Round((Horizon[2].X/Horizon[2].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round(-(-100/1E-3)/(1.5/GetMaxX)+GetMaxY/2));}
  OutTextXY(0, 0, 'Training...');
  OutTextXY(0, 25, 'Press any key to stop...');
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
{  end;}
  Dispose(Static);

  end
  else
  begin
  for w := 1 to Patterns do
  begin
    PropagateForward;
    if w = 1 then
    begin
      ClrScr;
      Write('Layer      ' : 14);
      Write('Co-ordinate' : 14);
      Write('X          ' : 14);
      Write('Y          ' : 14);
      Write('Z          ' : 14);
      Writeln;
      Write('input      ' : 14);
      Write('input      ' : 14);
      Write('outputerror' : 14);
      Write('outputerror' : 14);
      Write('outputerror' : 14);
      Writeln;
      Writeln;
      Write('I*100%     ' : 14);
      Write('I*100%     ' : 14);
      Write('deltaO*100%' : 14);
      Write('deltaO*100%' : 14);
      Write('deltaO*100%' : 14);
      Writeln;
      Writeln;
      Writeln;
    end;
    Write(Round(Input[w,1]*100) : 8);
    Write(Round(Input[w,2]*100) : 14);
    Write(Round(Output[HiddenLayers+1,1]*100-OutputWished[w,1]*100) : 14);
    Write(Round(Output[HiddenLayers+1,2]*100-OutputWished[w,2]*100) : 14);
    Write(Round(Output[HiddenLayers+1,3]*100-OutputWished[w,3]*100) : 14);
    Writeln;
  end;
  end;
  end;
  Inc(Iterations);
  until Keypressed;
  if (C = 'g') OR (C = 'G') then
    CloseGraph;
  Rewrite(Fw);
  for l := 1 to HiddenLayers+1 do
  for i := 0 to NeuronsInHiddenLayers do
    for j := 1 to NeuronsInHiddenLayers do
      begin
        Z := Weight[l,i,j];
        Write(Fw, Z);
      end;
  Close(Fw);
  Rewrite(Fp);
  Z := Patterns;
  Write(Fp, Z);
  Z := Layers;
  Write(Fp, Z);
  Z := CosPerLayer;
  Write(Fp, Z);
  for w := 1 to Patterns do
    for i := 1 to Inputs do
    begin
      Z := Input[w,i];
      Write(Fp, Z);
    end;
  for w := 1 to Patterns do
    for i := 1 to Outputs do
    begin
      Z := OutputWished[w,i];
      Write(Fp, Z);
    end;
  Close(Fp);
  end
  else
  begin



  ClrScr;
{  repeat
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
  until (Radius >= 1) AND (Radius <= 50);}
  InitGraph(Driver, Mode, '');
  New(Static);
  TaCnt := 1;
  Static^[0,1].X := 1;
  Static^[0,1].Y := 1;
  Static^[0,1].Z := 1;
  w := 1000;
  for i2 := 0 to VPL-1 do
    for j2 := 0 to VPC-1 do
    begin
      Input[w,1] := i2/(VPL-1);
      Input[w,2] := j2/(VPC-1);
      PropagateForward;
      CoBuffer[i2,j2].X := Output[HiddenLayers+1,1]-0.5;
      CoBuffer[i2,j2].Y := Output[HiddenLayers+1,2]-0.5;
      CoBuffer[i2,j2].Z := Output[HiddenLayers+1,3]-0.5;
    end;
  for i := 0 to VPL-2 do
    for j := 0 to VPC-1 do
    begin
      Static^[TaCnt,1].X := 0.05*Round(20*CoBuffer[i,j].X);
      Static^[TaCnt,1].Y := 0.05*Round(20*CoBuffer[i,j].Y);
      Static^[TaCnt,1].Z := 0.05*Round(20*CoBuffer[i,j].Z);
      Static^[TaCnt,2].X := 0.05*Round(20*CoBuffer[i,(j+1) MOD VPC].X);
      Static^[TaCnt,2].Y := 0.05*Round(20*CoBuffer[i,(j+1) MOD VPC].Y);
      Static^[TaCnt,2].Z := 0.05*Round(20*CoBuffer[i,(j+1) MOD VPC].Z);
      Static^[TaCnt,3].X := 0.05*Round(20*CoBuffer[i+1,j].X);
      Static^[TaCnt,3].Y := 0.05*Round(20*CoBuffer[i+1,j].Y);
      Static^[TaCnt,3].Z := 0.05*Round(20*CoBuffer[i+1,j].Z);
      Inc(TaCnt);
      Static^[TaCnt,1].X := 0.05*Round(20*CoBuffer[i,(j+1) MOD VPC].X);
      Static^[TaCnt,1].Y := 0.05*Round(20*CoBuffer[i,(j+1) MOD VPC].Y);
      Static^[TaCnt,1].Z := 0.05*Round(20*CoBuffer[i,(j+1) MOD VPC].Z);
      Static^[TaCnt,2].X := 0.05*Round(20*CoBuffer[i+1,j].X);
      Static^[TaCnt,2].Y := 0.05*Round(20*CoBuffer[i+1,j].Y);
      Static^[TaCnt,2].Z := 0.05*Round(20*CoBuffer[i+1,j].Z);
      Static^[TaCnt,3].X := 0.05*Round(20*CoBuffer[i+1,(j+1) MOD VPC].X);
      Static^[TaCnt,3].Y := 0.05*Round(20*CoBuffer[i+1,(j+1) MOD VPC].Y);
      Static^[TaCnt,3].Z := 0.05*Round(20*CoBuffer[i+1,(j+1) MOD VPC].Z);
      Inc(TaCnt);
    end;
  Triangles := TaCnt-1;

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
    'w'     : ForwardSpeed := ForwardSpeed + 1;
    's'     : ForwardSpeed := ForwardSpeed - 1;
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
  Bar(Round((Horizon[1].X/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round((Horizon[1].Z/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxY/2),
      Round((Horizon[2].X/Horizon[2].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round(-(100/1E-3)/(1.5/GetMaxX)+GetMaxY/2));
  SetFillStyle(1, 2);
  Bar(Round((Horizon[1].X/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxX/2),
      Round((Horizon[1].Z/Horizon[1].Y)/(1.5/GetMaxX)+GetMaxY/2),
      Round((Horizon[2].X/Horizon[2].Y)/(1.5/GetMaxX)+GetMaxX/2),
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
        PolyPoints[CoCnt + 1].X := Round((TriangleCos^[TriangleSequence[TaCnt],(CoCnt MOD 3) + 1].X
          /TriangleCos^[TriangleSequence[TaCnt],(CoCnt MOD 3) + 1].Y)
          /(1.5/GetMaxX)+GetMaxX/2);
        PolyPoints[CoCnt + 1].Y := Round(-(TriangleCos^[TriangleSequence[TaCnt],(CoCnt MOD 3) + 1].Z
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
  end;
end.
