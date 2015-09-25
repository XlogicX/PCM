{{
PCM_PoC
AUTHOR: XlogicX
Copyright (c) 2009 (MIT Terms of use; see end of file)

••••••••••••••••••••••••••••••••••••••••••••••••••••••  Description ••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
This is just a demo program that goes through a few sounds that can be made with the 'PCM' driver
I'm sure a lot more could be done with some creativity, this just exists as a POC


}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

obj
  pcm : "PCM.spin"

var
long    note
long    volume
long    loopcount
long    instrument
long    chan1_stack[100]
long    chan2_stack[100] 

pub main

pcm.start (15, 100)

'Loop through the instruments
'SAW, SINE, TRIANGLE, HUMP, CLIPPED SINE, NOISE1, NOISE2, SQUARE, PULSE1
instrument := 1
repeat while (instrument < 13)
  waitcnt(clkfreq / (2) + cnt)
  pcm.PlayNote (1, pcm#C3, 3, 0, 0, 0, 30, instrument)
  waitcnt(clkfreq / (2) + cnt)
  pcm.PlayNote (1, pcm#E3, 3, 0, 0, 0, 30, instrument) 
  waitcnt(clkfreq / (2) + cnt)
  pcm.PlayNote (1, pcm#G3, 3, 0, 0, 0, 30, instrument)
  instrument++

waitcnt(clkfreq / (1) + cnt)
pcm.PlayNote (1, pcm#C4, 3, 0, 0, 0, 60, 3)
pcm.PlayNote (2, pcm#E4, 3, 0, 0, 0, 60, 3)
pcm.PlayNote (3, pcm#G4, 3, 0, 0, 0, 60, 3)
waitcnt(clkfreq / (1) + cnt)
pcm.PlayNote (1, pcm#C4, 3, 0, 0, 0, 60, 3)
pcm.PlayNote (2, pcm#E4, 3, 0, 0, 0, 60, 3)
pcm.PlayNote (3, pcm#F4s, 3, 0, 0, 0, 60, 3)

waitcnt(clkfreq / (1) + cnt)
pcm.PlayNote (1, pcm#sC6, 5, 0, 0, 0, 60, 8)
pcm.PlayNote (2, pcm#sE6, 5, 0, 0, 0, 60, 8)
pcm.PlayNote (3, pcm#sG6, 5, 0, 0, 0, 60, 8)
waitcnt(clkfreq / (1) + cnt)
pcm.PlayNote (1, pcm#sC6, 5, 0, 0, 0, 60, 8)
pcm.PlayNote (2, pcm#sE6, 5, 0, 0, 0, 60, 8)
pcm.PlayNote (3, pcm#sF6s, 5, 0, 0, 0, 60, 8)




'Jump though quality
waitcnt(clkfreq / (1) + cnt)
repeat 8
  loopcount := 26 
  repeat while (loopcount > 22)
    pcm.PlayNote (1, pcm#sC6, 2, loopcount, 0, 0, 11, 2)
    waitcnt(clkfreq / (10) + cnt)
    loopcount--
  repeat while (loopcount < 27)
    pcm.PlayNote (1, pcm#sC6, 2, loopcount, 0, 0, 11, 2)
    waitcnt(clkfreq / (10) + cnt)
    loopcount++


waitcnt(clkfreq / (1) + cnt)
DownNote (1, pcm#C2, 2, 8, 10, 40, 5)
waitcnt(clkfreq / (10) + cnt)
DownNote (1, pcm#C2, 2, 8, 10, 40, 5)
waitcnt(clkfreq / (10) + cnt)
DownNote (1, pcm#C2, 2, 8, 10, 40, 5)
waitcnt(clkfreq / (10) + cnt)
DownNote (1, pcm#C2, 2, 8, 10, 40, 5)

waitcnt(clkfreq / (2) + cnt)
DownNote (1, pcm#C2, 2, 8, 10, 80, 5)
waitcnt(clkfreq / (20) + cnt)
DownNote (1, pcm#B1, 2, 8, 10, 80, 5)
waitcnt(clkfreq / (20) + cnt)
DownNote (1, pcm#A1s, 2, 8, 10, 80, 5)
waitcnt(clkfreq / (20) + cnt)
DownNote (1, pcm#A1, 2, 8, 10, 80, 5)
waitcnt(clkfreq / (20) + cnt)
DownNote (1, pcm#G1s, 2, 8, 10, 80, 5)
waitcnt(clkfreq / (20) + cnt)
DownNote (1, pcm#G1, 2, 8, 10, 80, 5)
waitcnt(clkfreq / (20) + cnt)
DownNote (1, pcm#G1s, 2, 8, 10, 80, 5)
waitcnt(clkfreq / (20) + cnt)
DownNote (1, pcm#G1, 2, 8, 10, 80, 5)

waitcnt(clkfreq / (1) + cnt)
cognew (pcm.PlayNote (1, pcm#C3, 1, 0, 0, 0, 30, 2), @chan1_stack)
cognew (DownNote (2, pcm#C2, 2, 1, 20, 80, 5), @chan2_stack)

waitcnt(clkfreq / (1) + cnt)
instrument := 12
repeat while (instrument > 0)
  repeat 8
    pcm.PlayNote (1, pcm#C3, 2, 0, 0, 0, 2, instrument)  
    waitcnt(clkfreq / (50) + cnt)
    pcm.PlayNote (1, pcm#E3, 2, 0, 0, 0, 2, instrument)
    waitcnt(clkfreq / (50) + cnt)
    pcm.PlayNote (1, pcm#G3, 2, 0, 0, 0, 2, instrument)
    waitcnt(clkfreq / (50) + cnt)
    pcm.PlayNote (1, pcm#C4, 2, 0, 0, 0, 2, instrument)
    waitcnt(clkfreq / (50) + cnt)
    pcm.PlayNote (1, pcm#E4, 2, 0, 0, 0, 2, instrument)
    waitcnt(clkfreq / (50) + cnt)
    pcm.PlayNote (1, pcm#G4, 2, 0, 0, 0, 2, instrument)
    waitcnt(clkfreq / (50) + cnt)
   
  repeat 8
    waitcnt(clkfreq / (50) + cnt)
    pcm.PlayNote (1, pcm#D3, 2, 0, 0, 0, 2, instrument)  
    waitcnt(clkfreq / (50) + cnt)
    pcm.PlayNote (1, pcm#F3, 2, 0, 0, 0, 2, instrument)
    waitcnt(clkfreq / (50) + cnt)
    pcm.PlayNote (1, pcm#A3, 2, 0, 0, 0, 2, instrument)
    waitcnt(clkfreq / (50) + cnt)
    pcm.PlayNote (1, pcm#D4, 2, 0, 0, 0, 2, instrument)
    waitcnt(clkfreq / (50) + cnt)
    pcm.PlayNote (1, pcm#F4, 2, 0, 0, 0, 2, instrument)
    waitcnt(clkfreq / (50) + cnt)
    pcm.PlayNote (1, pcm#A4, 2, 0, 0, 0, 2, instrument)
    waitcnt(clkfreq / (50) + cnt)
  instrument--

repeat 16
  pcm.PlayNote (1, pcm#C3, 2, 0, 0, 0, 2, 8)  
  waitcnt(clkfreq / (50) + cnt)
  pcm.PlayNote (1, pcm#E3, 2, 0, 0, 0, 2, 7)
  waitcnt(clkfreq / (50) + cnt)
  pcm.PlayNote (1, pcm#G3, 2, 0, 0, 0, 2, 4)
  waitcnt(clkfreq / (50) + cnt)
  pcm.PlayNote (1, pcm#C4, 2, 0, 0, 0, 2, 3)
  waitcnt(clkfreq / (50) + cnt)
  pcm.PlayNote (1, pcm#E4, 2, 0, 0, 0, 2, 2)
  waitcnt(clkfreq / (50) + cnt)
  pcm.PlayNote (1, pcm#G4, 2, 0, 0, 0, 2, 1)
  waitcnt(clkfreq / (50) + cnt)
   
repeat 16
  waitcnt(clkfreq / (50) + cnt)
  pcm.PlayNote (1, pcm#D3, 2, 0, 0, 0, 2, 1)  
  waitcnt(clkfreq / (50) + cnt)
  pcm.PlayNote (1, pcm#F3, 2, 0, 0, 0, 2, 2)
  waitcnt(clkfreq / (50) + cnt)
  pcm.PlayNote (1, pcm#A3, 2, 0, 0, 0, 2, 3)
  waitcnt(clkfreq / (50) + cnt)
  pcm.PlayNote (1, pcm#D4, 2, 0, 0, 0, 2, 4)
  waitcnt(clkfreq / (50) + cnt)
  pcm.PlayNote (1, pcm#F4, 2, 0, 0, 0, 2, 7)
  waitcnt(clkfreq / (50) + cnt)
  pcm.PlayNote (1, pcm#A4, 2, 0, 0, 0, 2, 8)
  waitcnt(clkfreq / (50) + cnt)

DownNote (1, pcm#C0, 0, 2, 180, 30, 20)
 

PUB DownNote (d_chan, d_note, d_vol, d_shape, d_reps, d_hold, d_dur)
{
This function will take your note (d_note) of shape (d_shape) and do a drop sweep affect. It starts at a higher note
and terminates on your specified note.

•how high to start the note is defined by d_reps; which is really just a value for how many pitch lowerings will be
done.
•d_hold specifies how long to sustain each pitch.
•d_dur specifies how long the final note should be maintained (and less noticably, how long each pitch in between
should be maintained).
}

  if d_reps > d_note            '\ Checks to see if the note is out of range and adjusts
    d_reps := d_note - 1        '/
  d_note := d_note - d_reps                             
  repeat d_reps                                  
    pcm.PlayNote(d_chan, d_note, d_vol, 0, 0, 0, d_dur, d_shape)
    waitcnt(clkfreq / d_hold + cnt)              
    d_note++         

{{

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
