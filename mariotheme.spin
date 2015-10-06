{{
Sequencer
AUTHOR: XlogicX
Copyright (c) 2009 (MIT Terms of use; see end of file)

••••••••••••••••••••••••••••••••••••••••••••••••••••••  Description ••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
PoC that plays the Mario overworld theme. The part of the music that is supposed to be triplets sucks in this implementation.
NES gamepad driver is not mine, it's the one included in Andres Hydra, I'm not including it becuase I forget what the liscensing was

B button starts the song
A button cycles through instruments
Up/Down increase/decrease volume
Left/Right slow down / increase tempo


}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  NES1_RIGHT  = %00000001_00000000
  NES1_LEFT   = %00000010_00000000
  NES1_DOWN   = %00000100_00000000
  NES1_UP     = %00001000_00000000
  NES1_START  = %00010000_00000000
  NES1_SELECT = %00100000_00000000
  NES1_B      = %01000000_00000000
  NES1_A      = %10000000_00000000

  N        = 254

  SQUARE   = 8

obj
  pcm : "PCM.spin"
  game  : "gamepad_drv_001.spin"              'instantiate a nintendo phearness  

var
long    volume
long    index
byte    instrument
byte    tempinst

pub main

game.start
pcm.start (15, 100)

repeat
  game.read
    if(game.button(NES1_B))
        Sequencer (6)        

PUB Sequencer (delay)
  index := 0
  instrument := SQUARE
  tempinst := SQUARE
  repeat while !(Song[index] == 255)
    instrument := tempinst

   game.read
    if(game.button(NES1_A))     'Instrument Cycle
      instrument--
      if instrument == 0
        instrument := 10 
    if(game.button(NES1_DOWN))  'Volume UP
      volume++
        if volume > 8
          volume := 8
    if(game.button(NES1_UP))    'Volume DOWN
      volume--
        if volume < 0
          volume := 0

    if(game.button(NES1_RIGHT))
      delay++
    if(game.button(NES1_LEFT))
      delay--      

    if Song[index] == 254
      tempinst := instrument
      instrument := 11
    pcm.PlayNote (1, Song[index], volume, 0, 0, 0, 15, instrument)
    waitcnt(clkfreq / delay + cnt)
    index++
    if index == 255
      index := 0

DAT
              
Song    byte  pcm#E3, pcm#E3, N, pcm#E3
        byte  N, pcm#C3, pcm#E3, N
        byte  pcm#G3, N, N, N
        byte  pcm#G2, N, N, N

        byte pcm#C3, N, N, pcm#G2
        byte N, N, pcm#E2, N 
        byte N, pcm#A2, N, pcm#B2
        byte N, pcm#A2s, pcm#A2, N

        byte N, pcm#G2, pcm#E3, pcm#G3
        byte pcm#A3s, N, pcm#F3, pcm#G3
        byte N, pcm#E3, N, pcm#C3
        byte pcm#D3, pcm#B2, N, N

        byte pcm#C3, N, N, pcm#G2
        byte N, N, pcm#E2, N 
        byte N, pcm#A2, N, pcm#B2
        byte N, pcm#A2s, pcm#A2, N

        byte N, pcm#G2, pcm#E3, pcm#G3
        byte pcm#A3s, N, pcm#F3, pcm#G3
        byte N, pcm#E3, N, pcm#C3
        byte pcm#D3, pcm#B2, N, N


        
        byte N, N, pcm#G3, pcm#F3s
        byte pcm#F3, pcm#D3s, N, pcm#E3
        byte N, pcm#G2s, pcm#A2, pcm#C3
        byte N, pcm#A2, pcm#C3, pcm#D3

        byte N, N, pcm#G3, pcm#F3s
        byte pcm#F3, pcm#D3s, N, pcm#E3
        byte N, pcm#C4, N, pcm#C4
        byte pcm#C4, N, N, N

        byte N, N, pcm#G3, pcm#F3s
        byte pcm#F3, pcm#D3s, N, pcm#E3
        byte N, pcm#G2s, pcm#A2, pcm#C3
        byte N, pcm#A2, pcm#C3, pcm#D3

        byte N, N, pcm#D3s, N
        byte N, pcm#D3, N, N
        byte pcm#C3, N, N, N
        byte N, N, N, N

        byte N, N, pcm#G3, pcm#F3s
        byte pcm#F3, pcm#D3s, N, pcm#E3
        byte N, pcm#G2s, pcm#A2, pcm#C3
        byte N, pcm#A2, pcm#C3, pcm#D3

        byte N, N, pcm#G3, pcm#F3s
        byte pcm#F3, pcm#D3s, N, pcm#E3
        byte N, pcm#C4, N, pcm#C4
        byte pcm#C4, N, N, N

        byte N, N, pcm#G3, pcm#F3s
        byte pcm#F3, pcm#D3s, N, pcm#E3
        byte N, pcm#G2s, pcm#A2, pcm#C3
        byte N, pcm#A2, pcm#C3, pcm#D3

        byte N, N, pcm#D3s, N
        byte N, pcm#D3, N, N
        byte pcm#C3, N, N, N
        byte N, N, N, N 

        byte pcm#C3, pcm#C3, N, pcm#C3
        byte N, pcm#C3, pcm#D3, N
        byte pcm#E3, pcm#C3, N, pcm#A2
        byte pcm#G2, N, N, N

        byte pcm#C3, pcm#C3, N, pcm#C3
        byte N, pcm#C3, pcm#D3, pcm#E3
        byte N, N, N, N
        byte N, N, N, N       

        byte pcm#C3, pcm#C3, N, pcm#C3
        byte N, pcm#C3, pcm#D3, N
        byte pcm#E3, pcm#C3, N, pcm#A2
        byte pcm#G2, N, N, N

        byte  255
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
