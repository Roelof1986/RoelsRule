//--------------------------------\\
//  GravTest (March 2004)         \\
//  Author: Roelof Emmerink       \\
//  E-mail: rpe86@hotmail.com     \\
//--------------------------------\\
program GravityTest;

{$N+}

uses Crt, evBGIDr, Graph;

const   Gravitation = 0.05;
        NrOfBoundaries = 6;

var     Driver, Mode : Integer;

        Key : Char;

        PrevXco, PrevYco, Xco, Yco : SINGLE;
        Velocity : array[1..4] of SINGLE;
        {VelBackup,} Force : array[1..2] of SINGLE;
        ResultantForce : array[1..4] of SINGLE;

        Boundaries : array[1..NrOfBoundaries, 1..4] of Integer;

        Boundary : Word;

        Labda, Mu, BounceAngle, BounceY, LineAngle, Denominator : SINGLE;

        I : Word;

function Sign(X : SINGLE): SINGLE;

begin
  if X <> 0 then
    Sign := X / Abs(X)
  else
    Sign := 1;
end;

begin
  if RegisterBGIdriver(@EGAVGADriver) < 0 then
  begin
    Writeln('EGA/VGA', ': ', GraphErrorMsg(GraphResult));
    Halt(1);
  end;
  Driver := VGA;
  Mode := VGAHi;
  InitGraph(Driver, Mode, '');
  Outtext('Press any key to begin...');
  repeat
    Key := Readkey;
  until Key <> Chr(0);
  ClearDevice;
  SetColor(9);
  Boundaries[1,1] := -100;
  Boundaries[1,2] := GetMaxY;
  Boundaries[1,3] := GetMaxX+100;
  Boundaries[1,4] := GetMaxY;
  Boundaries[2,1] := GetMaxX;
  Boundaries[2,2] := -100;
  Boundaries[2,3] := GetMaxX;
  Boundaries[2,4] := GetMaxY+100;
  Boundaries[3,1] := 0;
  Boundaries[3,2] := -100;
  Boundaries[3,3] := 0;
  Boundaries[3,4] := GetMaxY+100;
  Boundaries[4,1] := -100;
  Boundaries[4,2] := 0;
  Boundaries[4,3] := GetMaxX+100;
  Boundaries[4,4] := 0;
  Boundaries[5,1] := Round(GetMaxX/8);
  Boundaries[5,2] := Round(GetMaxY/1.5);
  Boundaries[5,3] := Round(GetMaxX/1.5);
  Boundaries[5,4] := Round(GetMaxY/8);
  Boundaries[6,1] := Round(GetMaxX/8);
  Boundaries[6,2] := Round(GetMaxY/8);
  Boundaries[6,3] := Round(GetMaxX/1.5);
  Boundaries[6,4] := Round(GetMaxY/1.5);
  for Boundary := 1 to NrOfBoundaries do
    Line(Boundaries[Boundary,1], Boundaries[Boundary,2], Boundaries[Boundary,3], Boundaries[Boundary,4]);
  Randomize;

 { repeat}
  I := 0;
  Xco := GetMaxX/2;
  Yco := GetMaxY/2;
  PrevXco := Xco;
  PrevYco := Yco;
  Velocity[1] := Random*2*Pi{3.2488746643};
  Velocity[2] := Random*100{81.701843262};
  {VelBackup[1] := Velocity[1];
  VelBackup[2] := Velocity[2];}
  SetColor(15);

  repeat
    Key := Chr(0);
    if Keypressed then
      repeat
        Key := Readkey;
      until Ord(Key) > 0;
    case Key of
      Chr(77) : begin
                  Force[1] := 0.5*Pi;
                  Force[2] := 0.1;
                end;
      Chr(75) : begin
                  Force[1] := 1.5*Pi;
                  Force[2] := 0.1;
                end;
      Chr(80) : begin
                  Force[1] := 0;
                  Force[2] := 0.1;
                end;
      Chr(72) : begin
                  Force[1] := Pi;
                  Force[2] := 0.1;
                end;
    end;

    if GetPixel(Round(PrevXco), Round(PrevYco)) = 15 then
      PutPixel(Round(PrevXco), Round(PrevYco), 0);
    if GetPixel(Round(Xco), Round(Yco)) = 0 then
      PutPixel(Round(Xco), Round(Yco), 15);
   { Line(Round(PrevXco), Round(PrevYco), Round(Xco), Round(Yco));}
    PrevXco := Xco;
    PrevYco := Yco;
    ResultantForce[3] := Sin(0) * Gravitation +
                         Sin(Velocity[1]+Pi) * 0.001*(Velocity[2]*Abs(Velocity[2])) +
                         Sin(Force[1]) * Force[2];
    ResultantForce[4] := Cos(0) * Gravitation +
                         Cos(Velocity[1]+Pi) * 0.001*(Velocity[2]*Abs(Velocity[2])) +
                         Cos(Force[1]) * Force[2];
{    ResultantForce[1] := ArcTan(ResultantForce[3] / ResultantForce[4]);
    ResultantForce[2] := Sqrt(Sqr(ResultantForce[3]) + Sqr(ResultantForce[4]));}
                   {+ -0.5*(Yco-400 + Abs(Yco-400)) }
    Velocity[3] := Sin(Velocity[1]) * Velocity[2] +
                   {Sin(ResultantForce[1]) * ResultantForce[2];}
                   ResultantForce[3];
    Velocity[4] := Cos(Velocity[1]) * Velocity[2] +
                   {Cos(ResultantForce[1]) * ResultantForce[2];}
                   ResultantForce[4];
    Velocity[1] := ArcTan(Velocity[3] / Velocity[4]);
    Velocity[2] := Sqrt(Sqr(Velocity[3]) + Sqr(Velocity[4])){*Sign(Velocity[3])}*Sign(Velocity[4]);
    Xco := Xco + Sin(Velocity[1]) * Velocity[2];
    Yco := Yco + Cos(Velocity[1]) * Velocity[2];

    Force[2] := Force[2] * 0.95;

    for Boundary := 1 to NrOfBoundaries do
    begin
     { (Boundaries[1]) + Labda (Boundaries[3] - Boundaries[1])
       (Boundaries[2]) + Labda (Boundaries[4] - Boundaries[2])
                       =
       (PrevXco) + Mu (Xco - PrevXco)
       (PrevYco) + Mu (Yco - PrevYco)

       Labda (Boundaries[3] - Boundaries[1]) - Mu (Xco - PrevXco)
        = (PrevXco) - (Boundaries[1])
       Labda (Boundaries[4] - Boundaries[2]) - Mu (Yco - PrevYco)
        = (PrevYco) - (Boundaries[2])

       Labda (Boundaries[3] - Boundaries[1]) * (Yco - PrevYco) - Mu (Xco - PrevXco) * (Yco - PrevYco)
        = ( (PrevXco) - (Boundaries[1]) ) * (Yco - PrevYco)
       Labda (Boundaries[4] - Boundaries[2]) * (Xco - PrevXco) - Mu (Yco - PrevYco) * (Xco - PrevXco)
        = ( (PrevYco) - (Boundaries[2]) ) * (Xco - PrevXco)

       Labda (Boundaries[3] - Boundaries[1]) * (Yco - PrevYco) - Labda (Boundaries[4] - Boundaries[2]) * (Xco - PrevXco)
        = ( (PrevXco) - (Boundaries[1]) ) * (Yco - PrevYco) - ( (PrevYco) - (Boundaries[2]) ) * (Xco - PrevXco) }

       Denominator := ( (Boundaries[Boundary,3] - Boundaries[Boundary,1]) * (Yco - PrevYco)
                      - (Boundaries[Boundary,4] - Boundaries[Boundary,2]) * (Xco - PrevXco) );

       if Denominator <> 0 then
         Labda := ( ( (PrevXco) - (Boundaries[Boundary,1]) ) * (Yco - PrevYco)
                  - ( (PrevYco) - (Boundaries[Boundary,2]) ) * (Xco - PrevXco) )
                / Denominator
       else
       begin
         Labda := -1;
         Xco := PrevXco;
         Yco := PrevYco;
       end;
     { Labda (Boundaries[3] - Boundaries[1]) * (Boundaries[4] - Boundaries[2])
        - Mu (Xco - PrevXco) * (Boundaries[4] - Boundaries[2])
        = ( (PrevXco) - (Boundaries[1]) ) * (Boundaries[4] - Boundaries[2])
       Labda (Boundaries[4] - Boundaries[2]) * (Boundaries[3] - Boundaries[1])
        - Mu (Yco - PrevYco) * (Boundaries[3] - Boundaries[1])
        = ( (PrevYco) - (Boundaries[2]) ) * (Boundaries[3] - Boundaries[1])

       ( - Mu (Xco - PrevXco) * (Boundaries[4] - Boundaries[2]) ) - ( - Mu (Yco - PrevYco) * (Boundaries[3] - Boundaries[1]) )
        = ( (PrevXco) - (Boundaries[1]) ) * (Boundaries[4] - Boundaries[2])
        - ( (PrevYco) - (Boundaries[2]) ) * (Boundaries[3] - Boundaries[1]) }

        Denominator := ( ( - (Xco - PrevXco) * (Boundaries[Boundary,4] - Boundaries[Boundary,2]) )
                       - ( - (Yco - PrevYco) * (Boundaries[Boundary,3] - Boundaries[Boundary,1]) ) );

        if Denominator <> 0 then
          Mu := ( ( (PrevXco) - (Boundaries[Boundary,1]) ) * (Boundaries[Boundary,4] - Boundaries[Boundary,2])
              - ( (PrevYco) - (Boundaries[Boundary,2]) ) * (Boundaries[Boundary,3] - Boundaries[Boundary,1]) )
              / Denominator
        else
        begin
          Mu := -1;
          Xco := PrevXco;
          Yco := PrevYco;
        end;

    if {Yco > Boundaries[2] OLD}
     ( (Labda >= 0) AND (Labda <= 1) ) AND ( (Mu >= 0) AND (Mu <= 1) )
    then
    begin
      {Yco := Boundaries[2] - (Yco - Boundaries[2]);}
   {  PutPixel(Round(Boundaries[1]+Labda*(Boundaries[3]-Boundaries[1])),
      Round(Boundaries[2]+Labda*(Boundaries[4]-Boundaries[2])), 4);     }
      BounceY := (Yco-(Boundaries[Boundary,2]+Labda*(Boundaries[Boundary,4]-Boundaries[Boundary,2])));
      if BounceY <> 0 then
        BounceAngle := ArcTan((Xco-(Boundaries[Boundary,1]+Labda*(Boundaries[Boundary,3]-Boundaries[Boundary,1])))
         /BounceY)
      else
        BounceAngle := Sign((Xco-(Boundaries[Boundary,1]+Labda*(Boundaries[Boundary,3]-Boundaries[Boundary,1]))))*Pi;
      if Boundaries[Boundary,3]-Boundaries[Boundary,1] <> 0 then
        LineAngle := ArcTan(-(Boundaries[Boundary,4]-Boundaries[Boundary,2])/(Boundaries[Boundary,3]-Boundaries[Boundary,1]))
      else
        LineAngle := Sign(Boundaries[Boundary,4]-Boundaries[Boundary,2])*Pi/2;
      Xco := (Boundaries[Boundary,1]+Labda*(Boundaries[Boundary,3]-Boundaries[Boundary,1]))
       + Sin(2*LineAngle-BounceAngle+Pi)
         * Sqrt(Sqr(Xco-(Boundaries[Boundary,1]+Labda*(Boundaries[Boundary,3]-Boundaries[Boundary,1])))
          +Sqr(Yco-(Boundaries[Boundary,2]+Labda*(Boundaries[Boundary,4]-Boundaries[Boundary,2]))))*
          Sign(Yco-(Boundaries[Boundary,2]+Labda*(Boundaries[Boundary,4]-Boundaries[Boundary,2])));
       Yco := (Boundaries[Boundary,2]+Labda*(Boundaries[Boundary,4]-Boundaries[Boundary,2]))
       + Cos(2*LineAngle-BounceAngle+Pi)
         * Sqrt(Sqr(Xco-(Boundaries[Boundary,1]+Labda*(Boundaries[Boundary,3]-Boundaries[Boundary,1])))
          +Sqr(Yco-(Boundaries[Boundary,2]+Labda*(Boundaries[Boundary,4]-Boundaries[Boundary,2]))))*
          Sign(Yco-(Boundaries[Boundary,2]+Labda*(Boundaries[Boundary,4]-Boundaries[Boundary,2])));
      Velocity[1] := 2*LineAngle-Velocity[1]+Pi;
      {ArcTan((Boundaries[4]-Boundaries[2])/(Boundaries[3]-Boundaries[1]))
       +(ArcTan((Boundaries[4]-Boundaries[2])/(Boundaries[3]-Boundaries[1]))-Velocity[1])}{+Sign(Velocity[1])
       *(Pi-ArcTan((Boundaries[4]-Boundaries[2])/(Boundaries[3]-Boundaries[1])))} {HIER WAS ER IETS MIS}
      Velocity[2] := Sqrt(Sqr(Velocity[2]) / 2)*Sign(Velocity[2]);
   {   Line(Round(PrevXco), Round(PrevYco), Round(Xco), Round(Yco));}
    end;
    end;
    Inc(I);
    Delay(5);
 { until I > 2000;}

  until Key = Chr(27);

  CloseGraph;
end.
