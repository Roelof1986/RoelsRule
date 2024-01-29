//--------------------------------\\
//  WavCapInOut V2 (January 2024) \\
//  Author: Roelof Emmerink       \\
//  E-mail: rpe86@hotmail.com     \\
//--------------------------------\\
unit wavcapinout_unit1_V2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  openal, crt, math;

const
  Seconds = 1;                            //- We'll record for 5 seconds
  Frequency = 16000;                       //- Recording a frequency of 8000
  SizeInSamples = 16384 DIV (2);
  Format = AL_FORMAT_MONO16;              //- Recording 16-bit mono
  BufferSize = (SizeInSamples*2)*{10}2 { -> .. * (seconds+1) !! }; //- (frequency * 2bytes(16-bit)) * seconds

  WriteBufferSize = ((BufferSize*{10000}{250}125) DIV 2);

Type
  TMyThread = class(TThread)

  private
    fStatusText : string;
    procedure ShowStatus;
  protected
    procedure Execute; override;
  public
    Constructor Create(CreateSuspended : boolean; StackSize : Integer);
  end;

var

  pCaptureDevice: pALCDevice;                  //- Device used to capture audio

  CaptureBuffer: array[0..BufferSize-1] of ALubyte; //- Capture buffer external from openAL, sized as calculated above for 5 second recording
  ProcessingBuffer : array[0..(BufferSize DIV 2)-1] of {Integer}smallint;

  i, k : Longint;

  wSampleNr : Int64;

  pPlaybackDevice: pALCDevice;                 //- Device used to playback audio
  pPlaybackContext: pALCContext;               //- Playback context
  pPlaybackSource: ALuint;                     //- Source for playback (in 3D sound would be located)

  PlayBuffer: array[0..1] of ALInt;                           //- openAL internal playback buffer

  PlayState: ALInt;              //- playback state
  Processed : ALInt;

  Playing : Boolean;

  wDat : Word;

  intDat : {Integer}smallint;

  Phase : SINGLE;

  SampleNr : Int64;

  MODskip : Longint;

  ReadSamples, pReadSamples : Longint;

  Cycles : Int64;

  // --

  Samples: ALInt;                //- count of the number of samples recorded

  pCaptureBuffer, SimSoundBuffer: array[0..BufferSize-1] of ALubyte; //- Capture buffer external from openAL, sized as calculated above for 5 second recording

  WriteBuffer : array[0..WriteBufferSize-1] of {Integer}smallint;

  WriteBufferPos, WriteBufferReadPos : {Longint}Int64;

//  CapDone : Boolean;

  SamplesDone, ProcessedDone : Boolean;

implementation


constructor TMyThread.Create(CreateSuspended : boolean; StackSize : Integer);
begin
  FreeOnTerminate := True;
  Priority := {tpHigher}{tpHighest}{tpNormal}tpTimeCritical;
  inherited Create(CreateSuspended, StackSize);

  //- Find out which extensions are supported and print them (could error check for capture extension here)
  writeln('OpenAL Extensions = ',PChar(alGetString(AL_EXTENSIONS)));

  //- Print device specifiers for default devices
  writeln('ALC_DEFAULT_DEVICE_SPECIFIER = ',PChar(alcGetString(nil, ALC_DEFAULT_DEVICE_SPECIFIER )));
  writeln('ALC_CAPTURE_DEVICE_SPECIFIER = ',PChar(alcGetString(nil, ALC_CAPTURE_DEVICE_SPECIFIER )));

  //- Setup the input capture device (default device)
  writeln('Setting up alcCaptureOpenDevice to use default device');
  pcaptureDevice:=alcCaptureOpenDevice(nil, Frequency, Format, BufferSize);
  if pcaptureDevice=nil then begin
    raise exception.create('Capture device is nil!');
    exit;
  end;

  //- Setup the output player device (default device)
  writeln('Setting up alcOpenDevice to use default device');
  pPlaybackDevice:=alcOpenDevice(nil);
  if pPlaybackDevice=nil then
    raise exception.create('Playback device is nil!');

  //- Setup the output context, not sure why a context is needed, it just is ok?
  writeln('Setting up alcCreateContext');
  pPlaybackContext:=alcCreateContext(pPlaybackDevice,nil);
  writeln('Making the playback context the current context (alcMakeContextCurrent)');
  alcMakeContextCurrent(pPlaybackContext);

  // Generate Buffer(s) for playback
  alGetError(); // clear error code
  alGenBuffers( 2, @PlayBuffer[0] );
  if alGetError() <> AL_NO_ERROR then
    raise exception.create('Ack!! Error creating playback buffer(s)!');

  // Generate Playback Sources - single source, not adjusting locational information for 3D sound
  writeln('Setting up playback source (alGenSources)');
  alGenSources(1, @pPlaybackSource);
  if alGetError() <> AL_NO_ERROR then
    raise exception.create('Ack an error creating a playback source!');

  //- Start capturing data
  alcCaptureStart(PCaptureDevice);

  WriteBufferReadPos := 0;


  WriteBufferPos := {0}{44100}SizeInSamples {DIV 1}*{2}{11}{12}14;

end;

procedure TMyThread.ShowStatus;
// this method is executed by the mainthread and can therefore access all GUI elements.
begin
//  Form1.Caption := fStatusText;
//  Writeln(fStatusText);
end;

procedure TMyThread.Execute;
var
  newStatus : string;
  prop_lrn_cycle : Longint;
begin
  fStatusText := 'TMyThread Starting...';
//  Writeln('TMyThread Starting...');
//  Synchronize(@Showstatus);
  fStatusText := 'TMyThread Running...';
//  Writeln('TMyThread Running...');
  while (not Terminated) {and ([any condition required])} do
    begin

       if Playing then
       repeat
         alGetSourcei(pPlaybackSource, AL_BUFFERS_PROCESSED, Processed);
//           Delay({175}{650}{325}{200}{75}5);
       until (Processed > 0);

         alSourceUnqueueBuffers( pPlaybackSource, 1, @PlayBuffer[0] );

         Writeln('buffer : ', (WriteBufferPos-WriteBufferReadPos)*100 DIV 65000, '%');

         MODskip := ((WriteBufferPos-WriteBufferReadPos)-(SizeInSamples*{15}12) {DIV 2}) DIV {5}2;

         Dec(MODskip);

       pReadSamples := ReadSamples;

       ReadSamples := Min(SizeInSamples, (WriteBufferPos-(WriteBufferReadPos+(SizeInSamples*{8}10)))){SizeInSamples};

       for k := 0 to {BufferSize}(SizeInSamples{ReadSamples} {DIV 2})-1 do
       if k < ReadSamples then
       begin

         if MODskip > -1 then
           MODskip := -1;

         intDat := Round(WriteBuffer[(WriteBufferReadPos+(SizeInSamples*{8}10)) MOD WriteBufferSize]);

         Inc(WriteBufferReadPos);

         Inc(SampleNr);

         if MODskip <> 0 then
         begin
           if MODskip > 0 then
           begin
             if SampleNr MOD (2500000 DIV MODskip) = 0 then
               Inc(WriteBufferReadPos, {MODskip}1)
           end
           else
             if SampleNr MOD (2500000 DIV -MODskip) = 0 then
               Dec(WriteBufferReadPos, {MODskip}1);
         end;

         Move(intDat, wDat, 2);
         SimSoundBuffer[k*2] := wDat MOD 256;
         SimSoundBuffer[k*2+1] := wDat DIV 256;
       end
       else
       begin

         intDat := 0;

         Move(intDat, wDat, 2);
         SimSoundBuffer[k*2] := wDat MOD 256;
         SimSoundBuffer[k*2+1] := wDat DIV 256;

       end;

       //- Load up the playback buffer from our capture buffer
       alBufferData( PlayBuffer[0], Format, @{pCaptureBuffer}SimSoundBuffer, {ReadSamples}SizeInSamples*2, Frequency);

       alSourceQueueBuffers( pPlaybackSource, 1, @PlayBuffer[0] );

       repeat
         alcGetIntegerv(pCaptureDevice, ALC_CAPTURE_SAMPLES, ALsizei(sizeof(ALint)), @samples);

//         if samples>=0 then
//           CapDone := True;

           Delay(1);

//         Sleep(1);

       until (samples>=SizeInSamples*{1.1}0.2);

       alcGetIntegerv(pCaptureDevice, ALC_CAPTURE_SAMPLES, ALsizei(sizeof(ALint)), @samples);

       pCaptureBuffer := CaptureBuffer;

       //- Capture the samples into our capture buffer
       alcCaptureSamples(pCaptureDevice, @CaptureBuffer, samples);

       Move(CaptureBuffer, ProcessingBuffer, BufferSize);

       for i := 0 to (samples {DIV 2})-1 do
       begin

         WriteBuffer[WriteBufferPos MOD WriteBufferSize] := ProcessingBuffer[i];

         Inc(WriteBufferPos);

         Inc(wSampleNr);

       end;

          if Playing then
          repeat
            alGetSourcei(pPlaybackSource, AL_BUFFERS_PROCESSED, Processed);
//            Delay({175}{650}{325}{200}{75}5);
          until (Processed > 0);

//          CapDone := False;

          alSourceUnqueueBuffers( pPlaybackSource, 1, @PlayBuffer[1] );

          Writeln('buffer : ', (WriteBufferPos-WriteBufferReadPos)*100 DIV 65000, '%');

          MODskip := ((WriteBufferPos-WriteBufferReadPos)-(SizeInSamples*{15}12) {DIV 2}) DIV {5}2;

          Dec(MODskip);

          pReadSamples := ReadSamples;

          ReadSamples := Min(SizeInSamples, (WriteBufferPos-(WriteBufferReadPos+(SizeInSamples*{8}10)))){SizeInSamples};

          for k := 0 to {BufferSize}({ReadSamples}SizeInSamples {DIV 2})-1 do
          if k < ReadSamples then
          begin

            if MODskip > -1 then
              MODskip := -1;

            intDat := Round(WriteBuffer[(WriteBufferReadPos+(SizeInSamples*{8}10)) MOD WriteBufferSize]);

            Inc(WriteBufferReadPos);

            Inc(SampleNr);

            if MODskip <> 0 then
            begin
              if MODskip > 0 then
              begin
                if SampleNr MOD (2500000 DIV MODskip) = 0 then
                  Inc(WriteBufferReadPos, {MODskip}1)
              end
              else
                if SampleNr MOD (2500000 DIV -MODskip) = 0 then
                  Dec(WriteBufferReadPos, {MODskip}1);
            end;


            Move(intDat, wDat, 2);
            SimSoundBuffer[k*2] := wDat MOD 256;
            SimSoundBuffer[k*2+1] := wDat DIV 256;
          end
          else
          begin

            intDat := 0;

            Move(intDat, wDat, 2);
            SimSoundBuffer[k*2] := wDat MOD 256;
            SimSoundBuffer[k*2+1] := wDat DIV 256;

          end;

          //- Load up the playback buffer from our capture buffer
          alBufferData( PlayBuffer[1], Format, @{pCaptureBuffer}SimSoundBuffer, {ReadSamples}SizeInSamples*2, Frequency);

          alSourceQueueBuffers( pPlaybackSource, 1, @PlayBuffer[1] );

          //- Play the sound
     //      if Cycles > 1 then
          if NOT Playing then
          begin
          alSourcePlay(ALuint(pPlaybackSource));
          Playing := True;
          end;

       // -----

       repeat
         alcGetIntegerv(pCaptureDevice, ALC_CAPTURE_SAMPLES, ALsizei(sizeof(ALint)), @samples);

//         if samples>=0 then
//           CapDone := True;

             Delay(1);
//         Sleep(1);

       until (samples>=SizeInSamples*{1.1}0.2);

       alcGetIntegerv(pCaptureDevice, ALC_CAPTURE_SAMPLES, ALsizei(sizeof(ALint)), @samples);

       pCaptureBuffer := CaptureBuffer;

       //- Capture the samples into our capture buffer
       alcCaptureSamples(pCaptureDevice, @CaptureBuffer, samples);

       Move(CaptureBuffer, ProcessingBuffer, BufferSize);

       for i := 0 to (samples {DIV 2})-1 do
       begin

         WriteBuffer[WriteBufferPos MOD WriteBufferSize] := ProcessingBuffer[i];

         Inc(WriteBufferPos);

         Inc(wSampleNr);

       end;

    end;
//  Writeln(Terminated);

//- Shutdown/Clean up the playback stuff
pPlaybackContext:=alcGetCurrentContext();
pPlaybackDevice:=alcGetContextsDevice(pPlaybackContext);
alcMakeContextCurrent(nil);
alcDestroyContext(pPlaybackContext);
alcCloseDevice(pPlaybackDevice);

end;

end.

