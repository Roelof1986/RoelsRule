//--------------------------------\\
//  WavCapInOut V2 (January 2024) \\
//  Author: Roelof Emmerink       \\
//  E-mail: rpe86@hotmail.com     \\
//--------------------------------\\
program wavcapinout_4_V2;
{$mode objfpc}

  uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads, cmem,
  {$ENDIF}{$ENDIF}

  Classes, windows, openal, sysutils, wavcapinout_unit1_V2, crt;

var
  MyThread : TMyThread;


  MainProgActive : Boolean;


begin

  IsMultiThread := True;


  MyThread := TMyThread.Create(False, 8*1024*1024);

//  MyThread.Priority(tpHighest);

  REPEAT

(*    if Assigned(MyThread.FatalException) then
      raise MyThread.FatalException; *)

(*    if Assigned(MyThreadA.FatalException) then
      raise MyThreadA.FatalException; *)

    MainProgActive := True;

    Delay(1);

//    Sleep(1);


  until MainProgActive = false;

end.
