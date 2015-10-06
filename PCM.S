{{
PCM Driver - 1-16 bit (can be modified on the fly for effects)
AUTHOR: XlogicX
Copyright (c) 2009 (MIT Terms of use; see end of file)
LAST MODIFIED: 9.24.15
VERSION 2.5
NOTE, this code is a mix of the Spin language, and Assembly.
The Assembly is what is doing the work
The Spin is effectively the API to play a note
If used in Propeller IDE, the correct file extension would be .spin

••••••••••••••••••••••••••••••••••••••••••••••••••••••  Description ••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
This is a 16-bit, 4-channel, sample based audio driver.
Meant to be used at 80 Mhz

xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx     Usage    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
You will be using the higher level API call of PlayNote.
It takes input of what Channel, frequency/note, volume, bit quality, garbledness, ors, duration, and sample / waveshape you will want to play

This is the format: PlayNote (chan, pitch, vol, Wqual, garb, dur, waveshape)

-chan can take values 1, 2, 3, and 4
-The pitch field starts at 1; the highest frequency. The larger this number gets, the lower the pitch will be
-the vol field starts at 0, the loudest. 1 is half as loud, 2 is half that, and so on. Although more precision could be desired,
 I prefer the low clock usage of a simple right shift, instead of complicated division; clocks eat at my higher frequencies.
-the quality field starts at 0 for the highest quality. The lowest quality goes up to 29, it is basically a square wave at 1-bit
 quality. For this very reason, I will probably not include a sample for a square wave; it's just pointless.
-the duration field is used for how long to play the note, the larger the value, the longer the note will be played
-the waveshape field allows you to pick a sample. The first sample in the data area would be number 1, the next number 2, and so
 on.
-the garble field, uhh, I don't know, it garbles the sound up a little.
-the ors field applies a user specified OR mask to audio

Sample data format:
-Each sample is made up of 128 16-bit (2 byte) values.
-You will notice that they are in the format of $XXXX_XXXX, ...
-There are actually 64 of those separated by commas, each one includes 2 16 bit samples
-The decompression engine sorts that all out automatically.
  Tenor and Alto waves: Don't expect to get above 1khz with the 128 piece samples using my code...I know, :(. However, a hack for
  that is samples that have the same wave shape with less pieces packed a few times into the sample
        -Waves that end in _tenor have the named waveshape repeat twice (so it would be 64 pieces two times)
        -Waves that end in _alto have the named waveshape repeat three times (so it would be about 43 pieces 3 times)

Explanation for gratuitous Note CON section:
As you can see, I have conversions for bass, tenor, alto, and soprano notes. There are pros and cons for which you decide to use
-On the Bass end:
  Pro: This is where the sound has the most 'piece' resloution, it has 128 pieces of data per shape, which means it has the
       least sub-harmonics. This is most noticeable in a low frequency sine wave
  Con: Limited upper range; you can't get any higher than 2,982 Hz
  Con: Precision is reduced; an A note in the 3rd octave is 220Hz, however, the closest value the bass values can play is 213Hz
-On the soprano end:
  Pro: Great upper range; highest pitch is 23,860Hz.
  Pro: Precision is also great compared to bass end; the 220Hz A note is executed as 220.93.
  Con: Greatly reduced piece quality; there would only be 16 pieces/values for each shape
-Discussion: Does any of this matter? Kind of, but not greatly. If you want notes in an upper range and for them to be in tune,
 then go with soprano. It's actually harder to hear degraded audio at higher notes anyway (I tested this). If you need really
 low bassy notes to sound clear without subharmonics, you will want to opt for the bass and tenor samples. The quality is most
 notable in smoother/slower changing wave shapes though, such as sine and triangle. On the other end, if your using square
 waves, I don't see a reason not to use soprano for all of the notes. Another note to make is that the notes do tend to get
 out of tune the higher the notes get (for any of the range of samples).
-Columns commented in CON section: I have a column for what the actual frequency of the note should be. A column for what
 frequency the driver is actually playing, and another column of "tolerance" showing a ratio of how close they are in
 relation. Anything in the thousandth digit and even hundredth digit is probably fine to an extent, but I wouldn't recommend
 using the notes that have values in the tenth digit, unless you want your music to sound horrible.

***************************************************   Change History   ***********************************************************

Ver 2.5 [9-3-2009]:
  •Had to re-write everything when I found out about crta and frqa; it does PWM for me, seamlessly. The main assembly code now
   does PCM, successfully.

}}

CON

'Notes
'
'               Theory          Actual                  Tolerance                        
'               (hz)            (hz)                     ┣──────────Why bother even calling it a note if there is a number here
'                                                        ┣┣─────────Will start to sound way out of tune
'Bass Notes                                              ↓↓↓────────You want this low                                          
  C0  = 182     '16.35          16.38                   .00231
  C0s = 172     '17.32          17.34                   .00119
  D0  = 163     '18.35          18.29                   .00284
  D0s = 153     '19.45          19.49                   .00226
  E0  = 145     '20.6           20.56                   .00148
  F0  = 137     '21.83          21.77                   .00273
  F0s = 129     '23.12          23.12                   .00003
  G0  = 122     '24.5           24.44                   .00215
  G0s = 115     '25.96          25.93                   .00094
  A0  = 108     '27.5           27.61                   .00422
  A0s = 102     '29.14          29.24                   .00345
  B0  = 97      '30.87          30.74                   .00396

  C1  = 91      '32.7           32.77                   .00231
  C1s = 86      '34.65          34.68                   .00090
  D1  = 81      '36.71          36.82                   .00304
  D1s = 77      '38.89          38.73                   .00401
  E1  = 72      '41.2           41.42                   .00543
  F1  = 68      '43.65          43.86                   .00482
  F1s = 64      '46.25          46.6                    .00757
  G1  = 61      '49             48.89                   .00215
  G1s = 57      '51.91          52.32                   .00795
  A1  = 55      '55             55.23                   .00422
  A1s = 51      '58.27          58.48                   .00362
  B1  = 48      '61.74          62.13                   .00639

  C2  = 46      '65.41          64.83                   .00881
  C2s = 43      '69.3           69.36                   .00090
  D2  = 41      '73.42          72.74                   .00927
  D2s = 38      '77.78          78.48                   .00903
  E2  = 36      '82.41          82.84                   .00530
  F2  = 34      '87.31          87.72                   .00471
  F2s = 32      '92.5           93.20                   .00757
  G2  = 30      '98             99.41                   .01428
  G2s = 29      '103.83         102.84                  .00955
  A2  = 27      '110            110.46                  .00422
  A2s = 26      '116.54         114.71                  .01591
  B2  = 24      '123.47         124.27                  .00647

  C3  = 23      '130.81         129.67                  0.00873                 
  C3s = 22      '138.59         135.57                  0.02226
  D3  = 20      '146.83         149.12                  0.01542
  D3s = 19      '155.56         156.97                  0.00903
  E3  = 18      '164.81         165.69                  0.00537
  F3  = 17      '174.61         175.44                  0.00476
  F3s = 16      '185            186.41                  0.00757
  G3  = 15      '196            198.83                  0.01428
  G3s = 14      '207.65         213.04                  0.02531
  A3  = 14      '220            213.04                  0.03266
  A3s = 13      '233.08         229.42                  0.01591
  B3  = 12      '246.94         248.54                  0.00647
                                                        
  C4  = 11      '261.63         271.14                  0.03509
  C4s = 11      '277.18         271.14                  0.02226
  D4  = 10      '293.66         298.25                  0.01542
  D4s = 10      '311.13         298.25                  0.04316
  E4  = 9       '329.63         331.39                  0.00533
  F4  = 9       '349.23         331.39                  0.05381
  F4s = 8       '369.99         372.82                  0.00760
  G4  = 8       '392            372.82                  0.05144
  G4s = 7       '415.3          426.08                  0.02531
  A4  = 7       '440            426.08                  0.03266
  A4s = 6       '466.16         497.09                  0.06224
  B4  = 6       '493.88         497.09                  0.00647
                                                        
  C5  = 6       '523.25         497.09                  0.05261
  C5s = 5       '554.37         596.51                  0.07065
  D5  = 5       '587.33         596.51                  0.01540
  D5s = 5       '622.25         596.51                  0.04314
  E5  = 5       '659.26         596.51                  0.10518
  F5  = 4       '698.46         745.64                  0.06328
  F5s = 4       '739.99         745.64                  0.00758
  G5  = 4       '783.99         745.64                  0.05142
  G5s = 4       '830.61         745.64                  0.11395
  A5  = 3       '880            994.19                  0.11486
  A5s = 3       '932.33         994.19                  0.06223
  B5  = 3       '987.77         994.19                  0.00646
                                                        
  C6  = 3       '1046.5         994.19                  0.05261
  C6s = 3       '1108.73        994.19                  0.11520
  D6  = 3       '1174.66        994.19                  0.18152
  D6s = 2       '1244.51        1491.29                 0.16548
  E6  = 2       '1318.51        1491.29                 0.11586
  F6  = 2       '1396.91        1491.29                 0.06329
  F6s = 2       '1479.98        1491.29                 0.00758
  G6  = 2       '1567.98        1491.29                 0.05142
  G6s = 2       '1661.22        1491.29                 0.11395
  A6  = 2       '1760           1491.29                 0.18019
  A6s = 2       '1864.66        1491.29                 0.25037
  B6  = 2       '1975.53        1491.29                 0.32471
                                                        
  C7  = 1       '2093           2982.58                 0.29826
  C7s = 1       '2217.46        2982.58                 0.25653
  D7  = 1       '2349.32        2982.58                 0.21232
  D7s = 1       '2489.02        2982.58                 0.16548
  E7  = 1       '2637.02        2982.58                 0.11586
  F7  = 1       '2793.83        2982.58                 0.06328
  F7s = 1       '2959.96        2982.58                 0.00758
  G7  = 1       '3135.96        2982.58                 0.05142
  G7s = 1       '3322.44        2982.58                 0.11395
  A7  = 1       '3520           2982.58                 0.18019
  A7s = 1       '3729.31        2982.58                 0.25036
  B7  = 1       '3951.07        2982.58                 0.32471
                                                        
  C8  = 1       '4186.01        2982.58                 0.40349
  C8s = 1       '4434.92        2982.58                 0.48694
  D8  = 1       '4698.64        2982.58                 0.57536
  D8s = 1       '4978.03        2982.58                 0.66903
                

'Tenor Notes                                          
  tC0  = 365    '16.35          16.34                   0.00043
  tC0s = 344    '17.32          17.34                   0.00118
  tD0  = 325    '18.35          18.35                   0.00023
  tD0s = 307    '19.45          19.43                   0.00100
  tE0  = 290    '20.6           20.56                   0.00148
  tF0  = 273    '21.83          21.85                   0.00093
  tF0s = 258    '23.12          23.12                   0.00000
  tG0  = 243    '24.5           24.54                   0.00195
  tG0s = 230    '25.96          25.93                   0.00094
  tA0  = 217    '27.5           27.48                   0.00039
  tA0s = 205    '29.14          29.09                   0.00143
  tB0  = 193    '30.87          30.90                   0.00121

  tC1  = C0     '32.7           32.77                   0.00230
  tC1s = C0s    '34.65          34.68                   0.00089
  tD1  = D0     '36.71          36.82                   0.00304
  tD1s = D0s    '38.89          38.98                   0.00251
  tE1  = E0     '41.2           41.13                   0.00148
  tF1  = F0     '43.65          43.54                   0.00249
  tF1s = F0s    '46.25          46.24                   0.00018
  tG1  = G0     '49             48.89                   0.00215
  tG1s = G0s    '51.91          51.87                   0.00075
  tA1  = A0     '55             55.23                   0.00421
  tA1s = A0s    '58.27          58.48                   0.00362
  tB1  = B0     '61.74          61.49                   0.00395

  tC2  = C1     '65.41          65.55                   0.00215
  tC2s = C1s    '69.3           69.36                   0.00089
  tD2  = D1     '73.42          73.64                   0.00304
  tD2s = D1s    '77.78          77.46                   0.00400
  tE2  = E1     '82.41          82.84                   0.00530
  tF2  = F1     '87.31          87.72                   0.00470
  tF2s = F1s    '92.5           93.20                   0.00757
  tG2  = G1     '98             97.78                   0.00215
  tG2s = G1s    '103.83         104.65                  0.00785
  tA2  = A1     '110            110.46                  0.00421
  tA2s = A1s    '116.54         116.96                  0.00362
  tB2  = B1     '123.47         124.27                  0.00647

  tC3  = C2     '130.81         129.67                  0.00873
  tC3s = C2s    '138.59         138.72                  0.00097
  tD3  = D2     '146.83         145.49                  0.00919
  tD3s = D2s    '155.56         156.97                  0.00903
  tE3  = E2     '164.81         165.69                  0.00536
  tF3  = F2     '174.61         175.44                  0.00476
  tF3s = F2s    '185            186.41                  0.00757
  tG3  = G2     '196            198.83                  0.01427
  tG3s = G2s    '207.65         205.69                  0.00950
  tA3  = A2     '220            220.93                  0.00421
  tA3s = A2s    '233.08         229.42                  0.01591
  tB3  = B2     '246.94         248.54                  0.00647

  tC4  = C3     '261.63         259.35                  0.00877
  tC4s = C3s    '277.18         271.14                  0.02226
  tD4  = D3     '293.66         298.25                  0.01541
  tD4s = D3s    '311.13         313.95                  0.00900
  tE4  = E3     '329.63         331.39                  0.00533
  tF4  = F3     '349.23         350.89                  0.00473
  tF4s = F3s    '369.99         372.82                  0.00759
  tG4  = G3     '392            397.67                  0.01427
  tG4s = G3s    '415.3          426.08                  0.02530
  tA4  = A3     '440            426.08                  0.03266
  tA4s = A3s    '466.16         458.85                  0.01591
  tB4  = B3     '493.88         497.09                  0.00647

  tC5  = C4     '523.25         542.28                  0.03510
  tC5s = C4s    '554.37         542.28                  0.02228
  tD5  = D4     '587.33         596.51                  0.01539
  tD5s = D4s    '622.25         596.51                  0.04313
  tE5  = E4     '659.26         662.79                  0.00533
  tF5  = F4     '698.46         662.79                  0.05380
  tF5s = F4s    '739.99         745.64                  0.00758
  tG5  = G4     '783.99         745.64                  0.05142
  tG5s = G4s    '830.61         852.16                  0.02529
  tA5  = A4     '880            852.16                  0.03266
  tA5s = A4s    '932.33         994.19                  0.06222
  tB5  = B4     '987.77         994.19                  0.00646

  tC6  = C5     '1046.5         994.19                  0.05261
  tC6s = C5s    '1108.73        1193.03                 0.07066
  tD6  = D5     '1174.66        1193.03                 0.01539
  tD6s = D5s    '1244.51        1193.03                 0.04314
  tE6  = E5     '1318.51        1193.03                 0.10517
  tF6  = F5     '1396.91        1491.29                 0.06328
  tF6s = F5s    '1479.98        1491.29                 0.00758
  tG6  = G5     '1567.98        1491.29                 0.05142
  tG6s = G5s    '1661.22        1491.29                 0.11394
  tA6  = A5     '1760           1988.38                 0.11486
  tA6s = A5s    '1864.66        1988.38                 0.06222
  tB6  = B5     '1975.53        1988.38                 0.00646
            
  tC7  = C6     '2093           1988.38                 0.05261
  tC7s = C6s    '2217.46        1988.38                 0.11520
  tD7  = D6     '2349.32        1988.38                 0.18152
  tD7s = D6s    '2489.02        2982.58                 0.16548
  tE7  = E6     '2637.02        2982.58                 0.11585
  tF7  = F6     '2793.83        2982.58                 0.06328
  tF7s = F6s    '2959.96        2982.58                 0.00758
  tG7  = G6     '3135.96        2982.58                 0.05142
  tG7s = G6s    '3322.44        2982.58                 0.11394
  tA7  = A6     '3520           2982.58                 0.18018
  tA7s = A6s    '3729.31        2982.58                 0.25036
  tB7  = B6     '3951.07        2982.58                 0.32471
            
  tC8  = C7     '4186.01        5965.16                 0.29825
  tC8s = C7s    '4434.92        5965.16                 0.25653
  tD8  = D7     '4698.64        5965.16                 0.21231
  tD8s = D7s    '4978.03        5965.16                 0.16548


'Alto Notes                                         
  aC0  = 730    '16.35          16.34                   0.00043
  aC0s = 689    '17.32          17.31                   0.00026
  aD0  = 650    '18.35          18.35                   0.00023
  aD0s = 613    '19.45          19.46                   0.00062
  aE0  = 579    '20.6           20.60                   0.00024
  aF0  = 547    '21.83          21.81                   0.00089
  aF0s = 516    '23.12          23.12                   0.00000
  aG0  = 487    '24.5           24.49                   0.00000
  aG0s = 460    '25.96          25.93                   0.00094
  aA0  = 434    '27.5           27.48                   0.00039
  aA0s = 409    '29.14          29.16                   0.00101
  aB0  = 386    '30.87          30.90                   0.00121

  aC1  = tC0    '32.7           32.68                   0.00043
  aC1s = tC0s   '34.65          34.68                   0.00089
  aD1  = tD0    '36.71          36.70                   0.00000
  aD1s = tD0s   '38.89          38.86                   0.00074
  aE1  = tE0    '41.2           41.13                   0.00148
  aF1  = tF0    '43.65          43.70                   0.00116
  aF1s = tF0s   '46.25          46.24                   0.00018
  aG1  = tG0    '49             49.09                   0.00195
  aG1s = tG0s   '51.91          51.87                   0.00075
  aA1  = tA0    '55             54.97                   0.00039
  aA1s = tA0s   '58.27          58.19                   0.00125
  aB1  = tB0    '61.74          61.81                   0.00121

  aC2  = C0     '65.41          65.55                   0.00215
  aC2s = C0s    '69.3           69.36                   0.00089
  aD2  = D0     '73.42          73.64                   0.00304
  aD2s = D0s    '77.78          77.97                   0.00251
  aE2  = E0     '82.41          82.27                   0.00160
  aF2  = F0     '87.31          87.08                   0.00261
  aF2s = F0s    '92.5           92.48                   0.00018
  aG2  = G0     '98             97.78                   0.00215
  aG2s = G0s    '103.83         103.74                  0.00084
  aA2  = A0     '110            110.46                  0.00421
  aA2s = A0s    '116.54         116.96                  0.00362
  aB2  = B0     '123.47         122.99                  0.00387
            
  aC3  = C1     '130.81         131.10                  0.00223
  aC3s = C1s    '138.59         138.72                  0.00097
  aD3  = D1     '146.83         147.28                  0.00310
  aD3s = D1s    '155.56         154.93                  0.00400
  aE3  = E1     '164.81         165.69                  0.00536
  aF3  = F1     '174.61         175.44                  0.00476
  aF3s = F1s    '185            186.41                  0.00757
  aG3  = G1     '196            195.57                  0.00215
  aG3s = G1s    '207.65         209.30                  0.00790
  aA3  = A1     '220            220.93                  0.00421
  aA3s = A1s    '233.08         233.92                  0.00362
  aB3  = B1     '246.94         248.54                  0.00647
            
  aC4  = C2     '261.63         259.35                  0.00877
  aC4s = C2s    '277.18         277.44                  0.00097
  aD4  = D2     '293.66         290.98                  0.00919
  aD4s = D2s    '311.13         313.95                  0.00900
  aE4  = E2     '329.63         331.39                  0.00533
  aF4  = F2     '349.23         350.89                  0.00473
  aF4s = F2s    '369.99         372.82                  0.00759
  aG4  = G2     '392            397.67                  0.01427
  aG4s = G2s    '415.3          411.39                  0.00950
  aA4  = A2     '440            441.86                  0.00421
  aA4s = A2s    '466.16         458.85                  0.01591
  aB4  = B2     '493.88         497.09                  0.00647
            
  aC5  = C3     '523.25         518.70                  0.00875
  aC5s = C3s    '554.37         542.28                  0.02228
  aD5  = D3     '587.33         596.51                  0.01539
  aD5s = D3s    '622.25         627.91                  0.00901
  aE5  = E3     '659.26         662.79                  0.00533
  aF5  = F3     '698.46         701.78                  0.00473
  aF5s = F3s    '739.99         745.64                  0.00758
  aG5  = G3     '783.99         795.35                  0.01428
  aG5s = G3s    '830.61         852.16                  0.02529
  aA5  = A3     '880            852.16                  0.03266
  aA5s = A3s    '932.33         917.71                  0.01592
  aB5  = B3     '987.77         994.19                  0.00646
            
  aC6  = C4     '1046.5         1084.57                 0.03510
  aC6s = C4s    '1108.73        1084.57                 0.02227
  aD6  = D4     '1174.66        1193.03                 0.01539
  aD6s = D4s    '1244.51        1193.03                 0.04314
  aE6  = E4     '1318.51        1325.59                 0.00534
  aF6  = F4     '1396.91        1325.59                 0.05380
  aF6s = F4s    '1479.98        1491.29                 0.00758
  aG6  = G4     '1567.98        1491.29                 0.05142
  aG6s = G4s    '1661.22        1704.33                 0.02529
  aA6  = A4     '1760           1704.33                 0.03266
  aA6s = A4s    '1864.66        1988.38                 0.06222
  aB6  = B4     '1975.53        1988.38                 0.00646
            
  aC7  = C5     '2093           1988.38                 0.05261
  aC7s = C5s    '2217.46        2386.06                 0.07066
  aD7  = D5     '2349.32        2386.06                 0.01539
  aD7s = D5s    '2489.02        2386.06                 0.04314
  aE7  = E5     '2637.02        2386.06                 0.10517
  aF7  = F5     '2793.83        2982.58                 0.06328
  aF7s = F5s    '2959.96        2982.58                 0.00758
  aG7  = G5     '3135.96        2982.58                 0.05142
  aG7s = G5s    '3322.44        2982.58                 0.11394
  aA7  = A5     '3520           3976.77                 0.11486
  aA7s = A5s    '3729.31        3976.77                 0.06222
  aB7  = B5     '3951.07        3976.77                 0.00646
            
  aC8  = C6     '4186.01        3976.77                 0.05261
  aC8s = C6s    '4434.92        3976.77                 0.11520
  aD8  = D6     '4698.64        3976.77                 0.18152
  aD8s = D6s    '4978.03        5965.16                 0.16548



'soprano Notes                                   
  sC0  = 1459   '16.35          16.35                   0.00025
  sC0s = 1378   '17.32          17.31                   0.00026
  sD0  = 1300   '18.35          18.35                   0.00023
  sD0s = 1227   '19.45          19.44                   0.00018
  sE0  = 1158   '20.6           20.60                   0.00024
  sF0  = 1093   '21.83          21.83                   0.00000
  sF0s = 1032   '23.12          23.12                   0.00000
  sG0  = 974    '24.5           24.49                   0.00000
  sG0s = 919    '25.96          25.96                   0.00014
  sA0  = 868    '27.5           27.48                   0.00039
  sA0s = 819    '29.14          29.13                   0.00020
  sB0  = 773    '30.87          30.86                   0.00000

  sC1  = aC0    '32.7           32.68                   0.00043
  sC1s = aC0s   '34.65          34.63                   0.00055
  sD1  = aD0    '36.71          36.70                   0.00000
  sD1s = aD0s   '38.89          38.86                   0.00074
  sE1  = aE0    '41.2           41.21                   0.00024
  sF1  = aF0    '43.65          43.62                   0.00066
  sF1s = aF0s   '46.25          46.24                   0.00018
  sG1  = aG0    '49             48.99                   0.00000
  sG1s = aG0s   '51.91          51.87                   0.00075
  sA1  = aA0    '55             54.97                   0.00039
  sA1s = aA0s   '58.27          58.33                   0.00118
  sB1  = aB0    '61.74          61.81                   0.00121

  sC2  = tC0    '65.41          65.37                   0.00058
  sC2s = tC0    '69.3           69.36                   0.00089
  sD2  = tD0    '73.42          73.41                   0.00000
  sD2s = tD0    '77.78          77.72                   0.00074
  sE2  = tE0    '82.41          82.27                   0.00160
  sF2  = tF0    '87.31          87.40                   0.00104
  sF2s = tF0    '92.5           92.48                   0.00018
  sG2  = tG0    '98             98.19                   0.00195
  sG2s = tG0    '103.83         103.74                  0.00084
  sA2  = tA0    '110            109.95                  0.00039
  sA2s = tA0    '116.54         116.39                  0.00125
  sB2  = tB0    '123.47         123.63                  0.00129
            
  sC3  = C0     '130.81         131.10                  0.00223
  sC3s = C0s    '138.59         138.72                  0.00097
  sD3  = D0     '146.83         147.28                  0.00310
  sD3s = D0s    '155.56         155.95                  0.00251
  sE3  = E0     '164.81         164.55                  0.00154
  sF3  = F0     '174.61         174.16                  0.00255
  sF3s = F0s    '185            184.96                  0.00018
  sG3  = G0     '196            195.57                  0.00215
  sG3s = G0s    '207.65         207.48                  0.00080
  sA3  = A0     '220            220.93                  0.00421
  sA3s = A0s    '233.08         233.92                  0.00362
  sB3  = B0     '246.94         245.98                  0.00387
            
  sC4  = C1     '261.63         262.20                  0.00219
  sC4s = C1s    '277.18         277.44                  0.00097
  sD4  = D1     '293.66         294.57                  0.00310
  sD4s = D1s    '311.13         309.87                  0.00403
  sE4  = E1     '329.63         331.39                  0.00533
  sF4  = F1     '349.23         350.89                  0.00473
  sF4s = F1s    '369.99         367.08                  0.00790
  sG4  = G1     '392            391.15                  0.00215
  sG4s = G1s    '415.3          418.60                  0.00790
  sA4  = A1     '440            441.86                  0.00421
  sA4s = A1s    '466.16         467.85                  0.00362
  sB4  = B1     '493.88         497.09                  0.00647
            
  sC5  = C2     '523.25         518.70                  0.00875
  sC5s = C2s    '554.37         554.89                  0.00095
  sD5  = D2     '587.33         581.96                  0.00921
  sD5s = D2s    '622.25         627.91                  0.00901
  sE5  = E2     '659.26         662.79                  0.00533
  sF5  = F2     '698.46         701.78                  0.00473
  sF5s = F2s    '739.99         745.64                  0.00758
  sG5  = G2     '783.99         795.35                  0.01428
  sG5s = G2s    '830.61         822.78                  0.00951
  sA5  = A2     '880            883.72                  0.00421
  sA5s = A2s    '932.33         917.71                  0.01592
  sB5  = B2     '987.77         994.19                  0.00646
            
  sC6  = C3     '1046.5         1037.41                 0.00875
  sC6s = C3s    '1108.73        1084.57                 0.02227
  sD6  = D3     '1174.66        1193.03                 0.01539
  sD6s = D3s    '1244.51        1255.82                 0.00900
  sE6  = E3     '1318.51        1325.59                 0.00534
  sF6  = F3     '1396.91        1403.56                 0.00474
  sF6s = F3s    '1479.98        1491.29                 0.00758
  sG6  = G3     '1567.98        1590.71                 0.01428
  sG6s = G3s    '1661.22        1704.33                 0.02529
  sA6  = A3     '1760           1704.33                 0.03266
  sA6s = A3s    '1864.66        1835.43                 0.01592
  sB6  = B3     '1975.53        1988.38                 0.00646
            
  sC7  = C4     '2093           2169.15                 0.03510
  sC7s = C4s    '2217.46        2386.06                 0.07066
  sD7  = D4     '2349.32        2386.06                 0.01539
  sD7s = D4s    '2489.02        2386.06                 0.04314
  sE7  = E4     '2637.02        2651.18                 0.00534
  sF7  = F4     '2793.83        2651.18                 0.05380
  sF7s = F4s    '2959.96        2982.58                 0.00758
  sG7  = G4     '3135.96        2982.58                 0.05142
  sG7s = G4s    '3322.44        3408.66                 0.02529
  sA7  = A4     '3520           3408.66                 0.03266
  sA7s = A4s    '3729.31        3976.77                 0.06222
  sB7  = B4     '3951.07        3976.77                 0.00646
            
  sC8  = C5     '4186.01        3976.77                 0.05261
  sC8s = C5s    '4434.92        4772.13                 0.07066
  sD8  = D5     '4698.64        4772.13                 0.01539
  sD8s = D5s    '4978.03        4772.13                 0.04314

  
DAT
'Channels
'They are initialized as empty, but this is the area that the 32-bit wave shapes will go.
chan1         long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0 
chan2         long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
chan3         long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
chan4         long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
              long      $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0 

'these are all of the 128 piece 16-bit sample wave shapes.                                                                                       
 
sawwave       long      $0200_0400, $0600_0800, $0A00_0C00, $0E00_1000, $1200_1400, $1600_1800, $1A00_1C00, $1E00_2000, $2200_2400
              long      $2600_2800, $2A00_2C00, $2E00_3000, $3200_3400, $3600_3800, $3A00_3C00, $3E00_4000, $4200_4400, $4600_4800
              long      $4A00_4C00, $4E00_5000, $5200_5400, $5600_5800, $5A00_5C00, $5E00_6000, $6200_6400, $6600_6800, $6A00_6C00
              long      $6E00_7000, $7200_7400, $7600_7800, $7A00_7C00, $7E00_8000, $8200_8400, $8600_8800, $8A00_8C00, $8E00_9000
              long      $9200_9400, $9600_9800, $9A00_9C00, $9E00_A000, $A200_A400, $A600_A800, $AA00_AC00, $AE00_B000, $B200_B400
              long      $B600_B800, $BA00_BC00, $BE00_C000, $C200_C400, $C600_C800, $CA00_CC00, $CE00_D000, $D200_D400, $D600_D800
              long      $DA00_DC00, $DE00_E000, $E200_E400, $E600_E800, $EA00_EC00, $EE00_F000, $F200_F400, $F600_F800, $FA00_FC00
              long      $FE00_FFFF

sinewave      long      $8324_896A, $8FAB_95E2, $9C0B_A223, $A826_AE11, $B3DE_B98C, $BF17_C47A, $C9B4_CEBF, $D39B_D842, $DCB4_E0EC
              long      $E4E8_E8A6, $EC24_EF5F, $F255_F504, $F76C_F98A, $FB5D_FCE3, $FE1D_FF09, $FFA7_FFF6, $FFF6_FFA7, $FF09_FE1D
              long      $FCE3_FB5D, $F98A_F76C, $F504_F255, $EF5F_EC24, $E8A6_E4E8, $E0EC_DCB4, $D842_D39B, $CEBF_C9B4, $C47A_BF17
              long      $B98C_B3DE, $AE11_A826, $A223_9C0B, $95E2_8FAB, $896A_8324, $7CDB_7695, $7054_6A1D, $63F4_5DDC, $57D9_51EE
              long      $4C21_4673, $40E8_3B85, $364B_3140, $2C64_27BD, $234B_1F13, $1B17_1759, $13DB_10A0, $0DAA_0AFB, $0893_0675
              long      $04A2_031C, $01E2_00F6, $0058_0009, $0009_0058, $00F6_01E2, $031C_04A2, $0675_0893, $0AFB_0DAA, $10A0_13DB
              long      $1759_1B17, $1F13_234B, $27BD_2C64, $3140_364B, $3B85_40E8, $4673_4C21, $51EE_57D9, $5DDC_63F4, $6A1D_7054
              long      $7695_7CDB

triangle      long      $0200_0600, $0A00_0E00, $1200_1600, $1A00_1E00, $2200_2600, $2A00_2E00, $3200_3600, $3A00_3E00, $4200_4600
              long      $4A00_4E00, $5200_5600, $5A00_5E00, $6200_6600, $6A00_6E00, $7200_7600, $7A00_7E00, $8200_8600, $8A00_8E00
              long      $9200_9600, $9A00_9E00, $A200_A600, $AA00_AE00, $B200_B600, $BA00_BE00, $C200_C600, $CA00_CE00, $D200_D600
              long      $DA00_DE00, $E200_E600, $EA00_EE00, $F200_F600, $FA00_FE00, $FFFF_FC00, $F800_F400, $F000_EC00, $E800_E400
              long      $E000_DC00, $D800_D400, $D000_CC00, $C800_C400, $C000_BC00, $B800_B400, $B000_AC00, $A800_A400, $A000_9C00
              long      $9800_9400, $9000_8C00, $8800_8400, $8000_7C00, $7800_7400, $7000_6C00, $6800_6400, $6000_5C00, $5800_5400
              long      $5000_4C00, $4800_4400, $4000_3C00, $3800_3400, $3000_2C00, $2800_2400, $2000_1C00, $1800_1400, $1000_0C00
              long      $0800_0400

hump          long      $0648_0C8F, $12D5_1917, $1F56_2590, $2BC4_31F1, $3817_3E33, $4447_4A50, $504D_563E, $5C22_61F7, $67BD_6D74
              long      $7319_78AD, $7E2E_839C, $88F5_8E39, $9368_987F, $9D7F_A267, $A736_ABEB, $B085_B504, $B968_BDAE, $C1D8_C5E4
              long      $C9D1_CD9F, $D14D_D4DB, $D848_DB94, $DEBE_E1C5, $E4AA_E76B, $EA09_EC83, $EED8_F109, $F314_F4FA, $F6BA_F853
              long      $F9C7_FB14, $FC3B_FD3A, $FE13_FEC4, $FF4E_FFB1, $FFEC_FFFF, $FFEC_FFB1, $FF4E_FEC4, $FE13_FD3A, $FC3B_FB14
              long      $F9C7_F853, $F6BA_F4FA, $F314_F109, $EED8_EC83, $EA09_E76B, $E4AA_E1C5, $DEBE_DB94, $D848_D4DB, $D14D_CD9F
              long      $C9D1_C5E4, $C1D8_BDAE, $B968_B504, $B085_ABEB, $A736_A267, $9D7F_987F, $9368_8E39, $88F5_839C, $7E2E_78AD
              long      $7319_6D74, $67BD_61F7, $5C22_563E, $504D_4A50, $4447_3E33, $3817_31F1, $2BC4_2590, $1F56_1917, $12D5_0C8F
              long      $0648_0000

clipped_sine  long      $84B6_8E1F, $9781_9F80, $AA11_B335, $BC39_C51A, $CDCD_D652, $DEA3_E6B7, $EE8E_F61F, $FD69_FFFE, $FFFE_FFFE
              long      $FFFE_FFFE, $FFFE_FFFE, $FFFE_FFFE, $FFFE_FFFE, $FFFE_FFFE, $FFFE_FFFE, $FFFE_FFFE, $FFFE_FFFE, $FFFE_FFFE
              long      $FFFE_FFFE, $FFFE_FFFE, $FFFE_FFFE, $FFFE_FFFE, $FFFE_FFFE, $FFFE_FFFE, $FFFE_FD69, $F61F_EE8E, $E6B7_DEA3
              long      $D652_CDCD, $C51A_BC39, $B335_AA11, $9F80_9781, $8E1F_84B6, $7B49_71E0, $687E_5F2C, $55EE_4CCA, $43C6_3AE5
              long      $3232_29AD, $215C_1948, $1171_09E0, $0296_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000
              long      $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000
              long      $0000_0000, $0000_0000, $0000_0296, $09E0_1171, $1948_215C, $29AD_3232, $3AE5_43C6, $4CCA_55EE, $5F2C_687E
              long      $71E0_7B49

'inpsired by digits of PI
noise         long      $7AB7_FFFF, $E663_7E80, $F4B3_95B7, $FFFF_FFFF, $422B_6E37, $16BC_7CD6, $B363_1E88, $9EB4_F289, $8144_0D9A
              long      $D0AD_42AB, $7FA6_3BE1, $33E2_77C8, $151A_AE41, $D712_572D, $630F_9F6C, $FFFF_442A, $6EFA_698B, $9679_293B
              long      $78BE_59A4, $7505_0EEB, $FBAC_FFFF, $DD53_82A6, $322F_DCA2, $83FA_31EC, $CDE8_0775, $38E4_4EA5, $5BA4_882D
              long      $11BF_6818, $535B_8CE8, $EB59_372F, $917D_53DE, $ECD7_DA49, $FFFF_CB7C, $259C_7246, $23D3_D18B, $FFFF_E69C
              long      $0071_7742, $D662_1239, $5388_3967, $4BD7_2D59, $A929_1BFF, $FFFF_E73B, $78C9_5065, $9531_6605, $6BB1_2E4E
              long      $3B68_F3AB, $7812_75B9, $CAAD_2608, $BF10_6D22, $477D_4C23, $7489_0708, $5F56_DD43, $219A_367D, $B53B_57C9
              long      $18E3_0883, $504E_90A3, $138B_54D5, $F5D3_2BD0, $9643_BC38, $0855_9E41, $4E25_0A1F, $38BE_8B18, $6C89_2D4E
              long      $6BB9_5E09

noise2        long      $4EE4_8344, $B31A_F88D, $7132_C6E1, $A9DC_F4D5, $3D7F_63D6, $EEB7_0643, $67E5_7DDB, $969E_D8C8, $9649_620F
              long      $3A85_AAE8, $774E_9732, $97F3_36A9, $F919_0433, $87D4_1675, $4566_4BC3, $D6E9_E472, $9D32_A941, $7BC9_A361
              long      $F882_763B, $839A_5F3C, $BC7A_A19F, $B5ED_0CC1, $2816_05D0, $75C3_0CB9, $D0C4_4919, $6F76_53B2, $7342_2341
              long      $BA6B_D170, $BAA2_83FD, $50BA_33CE, $0A0E_42AC, $A789_581E, $D630_37C5, $DE32_E7FD, $D26A_75D7, $C3A8_BFD3
              long      $F9D8_2CDD, $BB26_DADA, $5AFB_2B17, $227B_0FDD, $D653_F04D, $991C_8CCF, $E0F3_2398, $F099_ED5C, $A619_31C6
              long      $0815_B711, $AF01_3965, $DC88_45D6, $733E_E66F, $CA1E_6E2D, $F17F_79F8, $E167_6566, $04B2_8447, $0B17_C4E1
              long      $DF76_FD0E, $643A_0059, $E0BA_9446, $198C_2A71, $4C7D_ECF2, $ED4F_1E56, $0677_3289, $F5DD_07C5, $8907_4555
              long      $C67A_8E33 

sqaure        long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF
              long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF
              long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF
              long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001                                                                                                            

pulse1        long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF
              long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001 
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001

pulse2        long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001 
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001                                          

'lolz at wave that does nothing
nothing       long      $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000                         
              long      $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000
              long      $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000
              long      $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000
              long      $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000
              long      $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000
              long      $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000, $0000_0000
              long      $0000_0000

'Tenor Waves
sine_tenor    long      $8324_896A, $9C0B_A223, $B3DE_B98C, $C9B4_CEBF, $DCB4_E0EC, $EC24_EF5F, $F76C_F98A, $FE1D_FF09, $FFF6_FFA7
              long      $FCE3_FB5D, $F504_F255, $E8A6_E4E8, $D842_D39B, $C47A_BF17, $AE11_A826, $95E2_8FAB, $7CDB_7695, $63F4_5DDC
              long      $4C21_4673, $364B_3140, $234B_1F13, $13DB_10A0, $0893_0675, $01E2_00F6, $0009_0058, $031C_04A2, $0AFB_0DAA
              long      $1759_1B17, $27BD_2C64, $3B85_40E8, $51EE_57D9, $6A1D_7054, $8324_896A, $9C0B_A223, $B3DE_B98C, $C9B4_CEBF
              long      $DCB4_E0EC, $EC24_EF5F, $F76C_F98A, $FE1D_FF09, $FFF6_FFA7, $FCE3_FB5D, $F504_F255, $E8A6_E4E8, $D842_D39B
              long      $C47A_BF17, $AE11_A826, $95E2_8FAB, $7CDB_7695, $63F4_5DDC, $4C21_4673, $364B_3140, $234B_1F13, $13DB_10A0
              long      $0893_0675, $01E2_00F6, $0009_0058, $031C_04A2, $0AFB_0DAA, $1759_1B17, $27BD_2C64, $3B85_40E8, $51EE_57D9
              long      $6A1D_7054

saw_tenor     long      $0200_0600, $0A00_0E00, $1200_1600, $1A00_1E00, $2200_2600, $2A00_2E00, $3200_3600, $3A00_3E00, $4200_4600
              long      $4A00_4E00, $5200_5600, $5A00_5E00, $6200_6600, $6A00_6E00, $7200_7600, $7A00_7E00, $8200_8600, $8A00_8E00
              long      $9200_9600, $9A00_9E00, $A200_A600, $AA00_AE00, $B200_B600, $BA00_BE00, $C200_C600, $CA00_CE00, $D200_D600
              long      $DA00_DE00, $E200_E600, $EA00_EE00, $F200_F600, $FA00_FE00, $0200_0600, $0A00_0E00, $1200_1600, $1A00_1E00
              long      $2200_2600, $2A00_2E00, $3200_3600, $3A00_3E00, $4200_4600, $4A00_4E00, $5200_5600, $5A00_5E00, $6200_6600
              long      $6A00_6E00, $7200_7600, $7A00_7E00, $8200_8600, $8A00_8E00, $9200_9600, $9A00_9E00, $A200_A600, $AA00_AE00
              long      $B200_B600, $BA00_BE00, $C200_C600, $CA00_CE00, $D200_D600, $DA00_DE00, $E200_E600, $EA00_EE00, $F200_F600
              long      $FA00_FE00

'inpsired by digits of PI
noise_tenor   long      $7AB7_E663, $F4B3_FFFF, $422B_16BC, $B363_9EB4, $8144_D0AD, $7FA6_33E2, $151A_D712, $630F_FFFF, $6EFA_9679
              long      $78BE_7505, $FBAC_DD53, $322F_83FA, $CDE8_38E4, $5BA4_11BF, $535B_EB59, $917D_ECD7, $FFFF_259C, $23D3_FFFF
              long      $0071_D662, $5388_4BD7, $A929_FFFF, $78C9_9531, $6BB1_3B68, $7812_CAAD, $BF10_477D, $7489_5F56, $219A_B53B
              long      $18E3_504E, $138B_F5D3, $9643_0855, $4E25_38BE, $6C89_6BB9, $7AB7_E663, $F4B3_FFFF, $422B_16BC, $B363_9EB4
              long      $8144_D0AD, $7FA6_33E2, $151A_D712, $630F_FFFF, $6EFA_9679, $78BE_7505, $FBAC_DD53, $322F_83FA, $CDE8_38E4
              long      $5BA4_11BF, $535B_EB59, $917D_ECD7, $FFFF_259C, $23D3_FFFF, $0071_D662, $5388_4BD7, $A929_FFFF, $78C9_9531
              long      $6BB1_3B68, $7812_CAAD, $BF10_477D, $7489_5F56, $219A_B53B, $18E3_504E, $138B_F5D3, $9643_0855, $4E25_38BE
              long      $6C89_6BB9                                                                                                              

sqaure_tenor  long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF
              long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF
              long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF
              long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001                                                                                                              

'Alto Waves
saw_alto      long      $0200_0A00, $1200_1A00, $2200_2A00, $3200_3A00, $4200_4A00, $5200_5A00, $6200_6A00, $7200_7A00, $8200_8A00
              long      $9200_9A00, $A200_AA00, $B200_BA00, $C200_CA00, $D200_DA00, $E200_EA00, $F200_FA00, $0200_0A00, $1200_1A00
              long      $2200_2A00, $3200_3A00, $4200_4A00, $5200_5A00, $6200_6A00, $7200_7A00, $8200_8A00, $9200_9A00, $A200_AA00
              long      $B200_BA00, $C200_CA00, $D200_DA00, $E200_EA00, $F200_FA00, $0200_0A00, $1200_1A00, $2200_2A00, $3200_3A00
              long      $4200_4A00, $5200_5A00, $6200_6A00, $7200_7A00, $8200_8A00, $9200_9A00, $A200_AA00, $B200_BA00, $C200_CA00
              long      $D200_DA00, $E200_EA00, $F200_FA00, $0200_0A00, $1200_1A00, $2200_2A00, $3200_3A00, $4200_4A00, $5200_5A00
              long      $6200_6A00, $7200_7A00, $8200_8A00, $9200_9A00, $A200_AA00, $B200_BA00, $C200_CA00, $D200_DA00, $E200_EA00
              long      $F200_FA00                                                                                                

sine_alto     long      $8324_9C0B, $B3DE_C9B4, $DCB4_EC24, $F76C_FE1D, $FFF6_FCE3, $F504_E8A6, $D842_C47A, $AE11_95E2, $7CDB_63F4
              long      $4C21_364B, $234B_13DB, $0893_01E2, $0009_031C, $0AFB_1759, $27BD_3B85, $51EE_6A1D, $8324_9C0B, $B3DE_C9B4
              long      $DCB4_EC24, $F76C_FE1D, $FFF6_FCE3, $F504_E8A6, $D842_C47A, $AE11_95E2, $7CDB_63F4, $4C21_364B, $234B_13DB
              long      $0893_01E2, $0009_031C, $0AFB_1759, $27BD_3B85, $51EE_6A1D, $8324_9C0B, $B3DE_C9B4, $DCB4_EC24, $F76C_FE1D
              long      $FFF6_FCE3, $F504_E8A6, $D842_C47A, $AE11_95E2, $7CDB_63F4, $4C21_364B, $234B_13DB, $0893_01E2, $0009_031C
              long      $0AFB_1759, $27BD_3B85, $51EE_6A1D, $8324_9C0B, $B3DE_C9B4, $DCB4_EC24, $F76C_FE1D, $FFF6_FCE3, $F504_E8A6
              long      $D842_C47A, $AE11_95E2, $7CDB_63F4, $4C21_364B, $234B_13DB, $0893_01E2, $0009_031C, $0AFB_1759, $27BD_3B85
              long      $51EE_6A1D                                                                                                

'inpsired by digits of PI
noise_alto    long      $7AB7_F4B3, $422B_B363, $8144_7FA6, $151A_630F, $6EFA_78BE, $FBAC_322F, $CDE8_5BA4, $535B_917D, $FFFF_23D3
              long      $0071_5388, $A929_78C9, $6BB1_7812, $BF10_7489, $219A_18E3, $138B_9643, $4E25_6C89, $7AB7_F4B3, $422B_B363
              long      $8144_7FA6, $151A_630F, $6EFA_78BE, $FBAC_322F, $CDE8_5BA4, $535B_917D, $FFFF_23D3, $0071_5388, $A929_78C9
              long      $6BB1_7812, $BF10_7489, $219A_18E3, $138B_9643, $4E25_6C89, $7AB7_F4B3, $422B_B363, $8144_7FA6, $151A_630F
              long      $6EFA_78BE, $FBAC_322F, $CDE8_5BA4, $535B_917D, $FFFF_23D3, $0071_5388, $A929_78C9, $6BB1_7812, $BF10_7489
              long      $219A_18E3, $138B_9643, $4E25_6C89, $7AB7_F4B3, $422B_B363, $8144_7FA6, $151A_630F, $6EFA_78BE, $FBAC_322F
              long      $CDE8_5BA4, $535B_917D, $FFFF_23D3, $0071_5388, $A929_78C9, $6BB1_7812, $BF10_7489, $219A_18E3, $138B_9643
              long      $4E25_6C89                                                                                                

sqaure_alto   long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $FFFF_FFFF, $FFFF_FFFF
              long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF
              long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF
              long      $FFFF_FFFF, $FFFF_FFFF, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001
              
'soprano Waves
saw_sop       long      $0200_1200, $2200_3200, $4200_5200, $6200_7200, $8200_9200, $A200_B200, $C200_D200, $E200_F200, $0200_1200
              long      $2200_3200, $4200_5200, $6200_7200, $8200_9200, $A200_B200, $C200_D200, $E200_F200, $0200_1200, $2200_3200
              long      $4200_5200, $6200_7200, $8200_9200, $A200_B200, $C200_D200, $E200_F200, $0200_1200, $2200_3200, $4200_5200
              long      $6200_7200, $8200_9200, $A200_B200, $C200_D200, $E200_F200, $0200_1200, $2200_3200, $4200_5200, $6200_7200
              long      $8200_9200, $A200_B200, $C200_D200, $E200_F200, $0200_1200, $2200_3200, $4200_5200, $6200_7200, $8200_9200
              long      $A200_B200, $C200_D200, $E200_F200, $0200_1200, $2200_3200, $4200_5200, $6200_7200, $8200_9200, $A200_B200
              long      $C200_D200, $E200_F200, $0200_1200, $2200_3200, $4200_5200, $6200_7200, $8200_9200, $A200_B200, $C200_D200
              long      $E200_F200

sine_sop      long      $8324_B3DE, $DCB4_F76C, $FFF6_F504, $D842_AE11, $7CDB_4C21, $234B_0893, $0009_0AFB, $27BD_51EE, $8324_B3DE
              long      $DCB4_F76C, $FFF6_F504, $D842_AE11, $7CDB_4C21, $234B_0893, $0009_0AFB, $27BD_51EE, $8324_B3DE, $DCB4_F76C
              long      $FFF6_F504, $D842_AE11, $7CDB_4C21, $234B_0893, $0009_0AFB, $27BD_51EE, $8324_B3DE, $DCB4_F76C, $FFF6_F504
              long      $D842_AE11, $7CDB_4C21, $234B_0893, $0009_0AFB, $27BD_51EE, $8324_B3DE, $DCB4_F76C, $FFF6_F504, $D842_AE11
              long      $7CDB_4C21, $234B_0893, $0009_0AFB, $27BD_51EE, $8324_B3DE, $DCB4_F76C, $FFF6_F504, $D842_AE11, $7CDB_4C21
              long      $234B_0893, $0009_0AFB, $27BD_51EE, $8324_B3DE, $DCB4_F76C, $FFF6_F504, $D842_AE11, $7CDB_4C21, $234B_0893
              long      $0009_0AFB, $27BD_51EE, $8324_B3DE, $DCB4_F76C, $FFF6_F504, $D842_AE11, $7CDB_4C21, $234B_0893, $0009_0AFB
              long      $27BD_51EE

'inpsired by digits of PI
noise_sop     long      $7AB7_422B, $8144_151A, $6EFA_FBAC, $CDE8_535B, $FFFF_0071, $A929_6BB1, $BF10_219A, $138B_4E25, $7AB7_422B
              long      $8144_151A, $6EFA_FBAC, $CDE8_535B, $FFFF_0071, $A929_6BB1, $BF10_219A, $138B_4E25, $7AB7_422B, $8144_151A
              long      $6EFA_FBAC, $CDE8_535B, $FFFF_0071, $A929_6BB1, $BF10_219A, $138B_4E25, $7AB7_422B, $8144_151A, $6EFA_FBAC
              long      $CDE8_535B, $FFFF_0071, $A929_6BB1, $BF10_219A, $138B_4E25, $7AB7_422B, $8144_151A, $6EFA_FBAC, $CDE8_535B
              long      $FFFF_0071, $A929_6BB1, $BF10_219A, $138B_4E25, $7AB7_422B, $8144_151A, $6EFA_FBAC, $CDE8_535B, $FFFF_0071
              long      $A929_6BB1, $BF10_219A, $138B_4E25, $7AB7_422B, $8144_151A, $6EFA_FBAC, $CDE8_535B, $FFFF_0071, $A929_6BB1
              long      $BF10_219A, $138B_4E25, $7AB7_422B, $8144_151A, $6EFA_FBAC, $CDE8_535B, $FFFF_0071, $A929_6BB1, $BF10_219A
              long      $138B_4E25                                                                                                

sqaure_sap    long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $FFFF_FFFF
              long      $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $FFFF_FFFF, $FFFF_FFFF
              long      $FFFF_FFFF, $FFFF_FFFF, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF
              long      $FFFF_FFFF, $0000_0001, $0000_0001, $0000_0001, $0000_0001, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF
              long      $0000_0001, $0000_0001, $0000_0001, $0000_0001, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001
              long      $0000_0001, $0000_0001, $0000_0001, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001, $0000_0001
              long      $0000_0001, $0000_0001, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $FFFF_FFFF, $0000_0001, $0000_0001, $0000_0001
              long      $0000_0001                                                                                                
              
VAR           
                      'par offset
long    freq                        'variable that controls wave frequency (has limits of how low it can be [8])
long    freq2         '4             x
long    freq3         '8             x
long    freq4         '12            x
long    volume        '16            lower value equals larger volume
long    volume2       '20            x
long    volume3       '24            x
long    volume4       '28            x
long    quality       '32            0 = 16-bit, 1 = 15-bit, 2 = 14-bit....
long    data_adr      '36            address of channel data starting location
long    garble        '40            garble effect
long    comp_flag     '44            this is an or mask to apply to audio
long    duration      '48            how long to play the note / times to play sample
long    duration2     '52            x
long    duration3     '56            x
long    duration4     '60            x
long    shape         '64            what type or shape of wave (sine, saw, etc...)
long    shape2        '68            x
long    shape3        '72            x
long    shape4        '76            x
long    DeComFlags    '80            flag for what channels to decode

long    mix1_adr      '84            'memory location to the mix channels
long    mix2_adr      '88            x
long    mix3_adr      '92            x
long    mix4_adr      '96            x
long    mix_out_adr   '100           x

long    ch1_done      '104           'flags for channel being done playing
long    ch2_done      '108           x
long    ch3_done      '112           x
long    ch4_done      '116           x

long    pin           '120           'what pin to send the audio to

long    pitch_bal                    'variable used to even out duration based on pitch
long    dur_div                      'what number equals a second with dur parameter. For example, if dur_div is 100, a
                                     'value of 50 passed to the dur param would be half a second.
long    w_note2

long    split1
long    split2
PUB Start (audio_pin, d_div)
 
  data_adr    := @chan1         'put address of starting address chan1 in data_adr
  pin := audio_pin
  dur_div := d_div
 
  'some initialization of values, arbitrary values.
  
  freq      := $0010
  freq2     := $0010
  freq3     := $0010
  freq4     := $0010
  quality   := 13

  cognew(@DeCom, @freq)         ' start the decoder cog

  mix1_adr :=  data_adr
  mix2_adr :=  data_adr + $200
  mix3_adr :=  data_adr + $400
  mix4_adr :=  data_adr + $600

  cognew(@Mixer, @freq)         'start the mixer cog
 
  cognew(@PCM, @freq)           'start the PCM cog
 
PlayNote(1, 1, 0, 0, 0, 0, $1, 6) 
PlayNote(2, 1, 0, 0, 0, 0, $1, 6)
PlayNote(3, 1, 0, 0, 0, 0, $1, 6)
PlayNote(4, 1, 0, 0, 0, 0, $1, 6) 



PUB PlayNote (chan, pitch, vol, Wqual, garb, ors, dur, waveshape)

  'dur convert
  pitch_bal := pitch
  pitch_bal := 2982 / pitch_bal
  dur := (dur * pitch_bal) / dur_div
  
  case chan
    1:
      freq       := pitch
      volume     := vol
      quality    := Wqual
      garble     := garb
      comp_flag   := ors
      duration   := dur
      shape      := waveshape
      DecomFlags := %0001
      ch1_done   := 0
      return
    2:
      freq2       := pitch
      volume2     := vol
      quality    := Wqual
      garble     := garb
      comp_flag   := ors        
      duration2   := dur
      shape2      := waveshape
      DecomFlags := %0010
      ch2_done   := 0
      return
    3:
      freq3       := pitch
      volume3     := vol
      quality    := Wqual
      garble     := garb
      comp_flag   := ors             
      duration3   := dur
      shape3      := waveshape
      DecomFlags := %0100
      ch3_done   := 0
      return
    4:
      freq4       := pitch
      volume4     := vol
      quality    := Wqual
      garble     := garb
      comp_flag   := ors             
      duration4   := dur
      shape4      := waveshape
      DecomFlags := %1000
      ch4_done   := 0
      
DAT

              org       0
{{
                                            **********************************
--------------------------------------------* Decompression Assembly Engine: *------------------------------------------------------
                                            **********************************
                                            
Function:     This engine will request which channels you want decompressed, will check the shape to decompress, and will store the
              Decompressed wave in main memory.
How it works: 1. The engine grabs the memory locations for the shape selected for each channel, it also gets address of the flags
              2. Engine enters main loop.
                        -Are there any requests to decompress (are any flags set)?
                                (no)>  check again until there is
                                (yes)> if there is a request for channel 1
                                                ->get shape for channel 1 from memory
                                                ->decompress it
                                                ->store it back to main memory
                                       ...
                                       ...
                                       do this for all for channels
                                reset flags to 0
                                go back to beginning of loop, waiting for another cog to set some flags
Flag register: The flag register is only 4 bits (nibble). They are arranged as: Ch4, Ch3, Ch2, Ch1
                        Example 1: Flag is set to $7 (0111), this means the engine will process ch1, ch2, and ch3
                        Example 2: Flag is set to $A (1010), this means the engine will process ch2 and ch4          
Shape vars   : These 4 variables from spin (shape, shape2, shape3, shape4) get passed to the engine as (asmshape, asmshape2,
                        asmshape3, asmshape4).
                        If I wanted a 'hump' wave on channel 3, I would have to set shape3 to '4' (or whatever number in
                        the wave index it would be in), and I would have to set the flag to x1xx (where the value of the x
                        bits don't matter).
Additional
Note          : It is important to set the shape before flagging (with a delay after setting the shape). If you flagged,
                        the engine may run with the old shape before the other cog would get to the next instruction of
                        changing the shape
}}

''DeCom Engine:
''
''Initilization: get address of shapes and flag
              ''puts address in all variables
              
DeCom         mov       asmshape, par           
              mov       asmshape2, par
              mov       asmshape3, par
              mov       asmshape4, par
              mov       flags, par
              mov       chanadr1, par

              ''indexes them
              add       asmshape, #64
              add       asmshape2, #68
              add       asmshape3, #72
              add       asmshape4, #76
              add       flags, #80
              add       chanadr1, #36
              rdlong    chanadr1, chanadr1
              
              add       chanadr2, chanadr1
              add       chanadr3, chanadr1
              add       chanadr4, chanadr1
              add       waveadr,  chanadr1

''
''Main Loop
:start        rdlong    flags_v, flags          'grab the flags from main memory
              ''are there requests on the flags?
              cmp       flags_v, #0   wz
        if_z  jmp       #:start                 'restart/recheck if there are no requests
              ''do chan1?
:_shape1      mov       temp, flags_v           'get a scratch flag register
              and       temp, #%0001            'mask it with first mask (0 bit)
              cmp       temp, #%0001  wz      'if 0 bit set, subtracting them will = 0, setting the z flag
        if_z  jmp       #:shape1

              ''do chan2? 
:_shape2      mov       temp, flags_v           'get another scratch flag register
              and       temp, #%0010            'mask it with the mask (1 bit)
              cmp       temp, #%0010  wz      'if 1 bit set, subtracting them will = 0, setting the z flag
        if_z  jmp       #:shape2

              ''do chan3? 
:_shape3      mov       temp, flags_v           'get another scratch flag register
              and       temp, #%0100            'mask it with the mask (2 bit)
              cmp       temp, #%0100  wz      'if 2 bit set, subtracting them will = 0, setting the z flag
        if_z  jmp       #:shape3

              ''do chan4? 
:_shape4      mov       temp, flags_v           'get another scratch flag register
              and       temp, #%1000            'mask it with the mask (3 bit)
              cmp       temp, #%1000  wz       'if 3 bit set, subtracting them will = 0, setting the z flag
        if_z  jmp       #:shape4        

:end          mov       flags_v, #0             'you're done, clear flags
              wrlong    flags_v, flags          'update decom flag in main memory for next pass
              jmp       #:start                       


''
''Subroutines to get shape and decompress them:
''----------Shape 1---------------
''get/adjust address of first shape
:shape1       rdlong    asmshape_v, asmshape      'get current shape number
              mov       count, asmshape_v         'Start counter equal to the shape number in spin
              mov       asmshape_v, waveadr       'get first address of first shape
:shape1_l     add       asmshape_v, #256          'this jumps to the next shape in address land
              djnz      count, #:shape1_l         'Will jump down as many shapes[the address of] as the shape number you give
              sub       asmshape_v, #256          'jump back up a shape (since the loop has to run atleast once)
              add       wavemem_1, asmshape_v     'add the new shape jumping index to the starting point of the shape address (if any)
''      decompress it
              mov       count, #64
              ''put address of wave parts into local wave values
:dec1         rdlong    wave1a, wavemem_1        'puts the value in wave1a
              rdlong    wave1b, wavemem_1        'puts same value in wave1b
              ''format each wave value for 32-bit PWM engine
              and       wave1a, PCMValMask       'masks wave1a so value is in MSB
              shl       wave1b, #16              'shfts wave1b so data is in MSB
              add       wavemem_1, #4            'moves index pointer to next value in memory
              ''stores the values in the 2k main memory data area for full 32-bit up-sampled shapes.
              wrlong    wave1a, chanadr1         'write 1st part to memory
              add       chanadr1, #4             'go to next 32-bit address
              wrlong    wave1b, chanadr1         'write the 2nd part
              add       chanadr1, #4             'go to the next 32-bit address
              djnz      count, #:dec1            'go to next set of chunks in shape index if not at the end        
              sub       chanadr1, chanrst
              mov       wavemem_1, #0
              jmp       #:_shape2                'check next shape
''              
''----------Shape 2---------------
:shape2       rdlong    asmshape2_v, asmshape2    'get current shape number
              mov       count, asmshape2_v        '\
              mov       asmshape2_v, waveadr      ' \
:shape2_l     add       asmshape2_v, #256         '  \
              djnz      count, #:shape2_l         '   \
              sub       asmshape2_v, #256         '    \
              add       wavemem_2, asmshape2_v    '     Same thing for shape 2
'decompress it
              mov       count, #64
              'puts address of waves parts into local wave values
:dec2         rdlong    wave2a, wavemem_2        'puts the value in wave1a
              rdlong    wave2b, wavemem_2        'puts same value in wave1b
              'formats each wave value for 32-bit PWM engine
              and       wave2a, PCMValMask       'masks wave1a so value is in MSB
              shl       wave2b, #16              'shfts wave1b so data is in MSB
              add       wavemem_2, #4            'moves index pointer to next value in memory
              'stores the values in the 2k main memory data area for full 32-bit up-sampled shapes.
              wrlong    wave2a, chanadr2         'write 1st part to memory
              add       chanadr2, #4             'go to next 32-bit address
              wrlong    wave2b, chanadr2         'write the 2nd part
              add       chanadr2, #4             'go to the next 32-bit address
              djnz      count, #:dec2            'go to next set of chunks in shape index if not at the end          
              sub       chanadr2, chanrst
              mov       wavemem_2, #0 
              jmp       #:_shape3                'check next shape

''----------Shape 3--------------- 
:shape3       rdlong    asmshape3_v, asmshape3    'get current shape number
              mov       count, asmshape3_v        '\                          
              mov       asmshape3_v, waveadr      ' \                         
:shape3_l     add       asmshape3_v, #256         '  \                        
              djnz      count, #:shape3_l         '   \                       
              sub       asmshape3_v, #256         '    \                      
              add       wavemem_3, asmshape3_v    '     Same thing for shape 3
'decompress it
              mov       count, #64
              'puts address of waves parts into local wave values
:dec3         rdlong    wave3a, wavemem_3        'puts the value in wave1a
              rdlong    wave3b, wavemem_3        'puts same value in wave1b
              'formats each wave value for 32-bit PWM engine
              and       wave3a, PCMValMask       'masks wave1a so value is in MSB
              shl       wave3b, #16              'shfts wave1b so data is in MSB
              add       wavemem_3, #4            'moves index pointer to next value in memory
              'stores the values in the 2k main memory data area for full 32-bit up-sampled shapes.
              wrlong    wave3a, chanadr3         'write 1st part to memory
              add       chanadr3, #4             'go to next 32-bit address
              wrlong    wave3b, chanadr3         'write the 2nd part
              add       chanadr3, #4             'go to the next 32-bit address
              djnz      count, #:dec3            'go to next set of chunks in shape index if not at the end             
              sub       chanadr3, chanrst
              mov       wavemem_3, #0 
              jmp       #:_shape4                'check next shape

''----------Shape 4---------------
:shape4       rdlong    asmshape4_v, asmshape4    'get current shape number
              mov       count, asmshape4_v        '\                          
              mov       asmshape4_v, waveadr      ' \                         
:shape4_l     add       asmshape4_v, #256         '  \                        
              djnz      count, #:shape4_l         '   \                       
              sub       asmshape4_v, #256         '    \                      
              add       wavemem_4, asmshape4_v    '     Same thing for shape 4
'decompress it
              mov       count, #64
              'puts address of waves parts into local wave values
:dec4         rdlong    wave4a, wavemem_4        'puts the value in wave1a
              rdlong    wave4b, wavemem_4        'puts same value in wave1b
              'formats each wave value for 32-bit PWM engine
              and       wave4a, PCMValMask       'masks wave1a so value is in MSB
              shl       wave4b, #16              'shfts wave1b so data is in MSB
              add       wavemem_4, #4            'moves index pointer to next value in memory
              'stores the values in the 2k main memory data area for full 32-bit up-sampled shapes.
              wrlong    wave4a, chanadr4         'write 1st part to memory
              add       chanadr4, #4             'go to next 32-bit address
              wrlong    wave4b, chanadr4         'write the 2nd part
              add       chanadr4, #4             'go to the next 32-bit address
              djnz      count, #:dec4            'go to next set of chunks in shape index if not at the end          
              sub       chanadr4, chanrst
              mov       wavemem_4, #0 
              jmp       #:end                    'restart whole checking process
                

           '****[Variables]****'
waveadr       long $800                         'This is the starting address of wave tables (may change, keep an eye on these ones)
chanadr1      long $20                          'address of chan1 wave uncompressed
chanadr2      long $200                         'address of chan2 wave uncompressed
chanadr3      long $400                         'address of chan3 wave uncompressed
chanadr4      long $600                         'address of chan4 wave uncompressed
chanrst       long $200                         'reset mask for re-entry of storage loop
 
PCMValMask    long $FFFF_0000                   'upper sample mask 
count         long 0                            'loop counter, everyone wants one of these
temp          long 0                            'these too

asmshape_v      long 0                          'local value of shape1 
asmshape2_v     long 0                          'local value of shape2
asmshape3_v     long 0                          'local value of shape3 
asmshape4_v     long 0                          'local value of shape4 
flags_v         long 0                          'command flags

wavemem_1     long 0                            'Used as address variable for wave index (of shape1) in main memory
wavemem_2     long 0                            'Used as address variable for wave index (of shape2) in main memory   
wavemem_3     long 0                            'Used as address variable for wave index (of shape3) in main memory   
wavemem_4     long 0                            'Used as address variable for wave index (of shape4) in main memory  

wave1a        long $69696969                    '1st compressed piece of chan1
wave1b        long $69696969                    '2nd compressed piece of chan1
wave2a        long $69696969                    '1st compressed piece of chan2
wave2b        long $69696969                    '2nd compressed piece of chan2
wave3a        long $69696969                    '1st compressed piece of chan3
wave3b        long $69696969                    '2nd compressed piece of chan3
wave4a        long $69696969                    '1st compressed piece of chan4
wave4b        long $69696969                    '2nd compressed piece of chan4


'spin adresses
asmshape      long 0                            'shape1 address
asmshape2     long 0                            'shape2 address
asmshape3     long 0                            'shape3 address
asmshape4     long 0                            'shape4 address
flags         long 0


''
''************************************************************************************************************************************

              org       0
{{
                                            **********************************
--------------------------------------------*          Mixer Engine:         *------------------------------------------------------
                                            **********************************
                                            
Function:     This engine will take the 4 samples to mix (as an address of each), mixt them, add effects, then put the output on
              a shared address for consumption by PCM engine.
How it works:
Notes:        -Continiously runs (without being called); expect the output address to hold a semi up to date mix of values in the
              channel addresses in real time.
              -The addressess that hold another address that hold the value sounds confusing, and I shouldn't just leave it at
              lol'ing at it in the comments below. The indirectness allows me to be flexible. This engine merely asks where the
              real data is located, instead of all of the extra overhead of passing several real values everywhere. Other cores
              are going to be constantly updating the data in real time, so this engine only cares where that data currently is,
              and will then play with it. Visuall analogy (painful):
                        Addresses               value in address
                        1337 W. HaK Dr.         Actual Sample chunk of data     (a value)
                        1369 E. Noob St.        1337 W. HaK Dr.                 (a value, however, of an address)

                        This code grabs the address of the address (it gets the 1369 address),
                        It puts the value of that address (1337 Dr.) in a local variable,
                        It then overwrites the value of the address from that local variable (1337 Dr.) into the variable.
                        So now we have real data in a local workable variable (inderectly, but flexibly)
                        ...lol
                        
}}

Mixer         mov       mx_adr1, par           
              mov       mx_adr2, par
              mov       mx_adr3, par
              mov       mx_adr4, par
              mov       mx_out_adr, par
              mov       qual_adr, par
              mov       m_garb_adr, par
              mov       m_not_adr, par
              mov       vol1_adr, par              
              mov       vol2_adr, par
              mov       vol3_adr, par
              mov       vol4_adr, par
              ''indexes them
              add       mx_adr1, #84
              add       mx_adr2, #88
              add       mx_adr3, #92
              add       mx_adr4, #96
              add       mx_out_adr, #100
              add       qual_adr, #32
              add       m_garb_adr, #40
              add       m_not_adr, #44
              add       vol1_adr, #16
              add       vol2_adr, #20
              add       vol3_adr, #24
              add       vol4_adr, #28
              
              ''put values (also addresses) at the addresses in local workspace
:MXStart      rdlong    mx_val1, mx_adr1
              rdlong    mx_val2, mx_adr2
              rdlong    mx_val3, mx_adr3
              rdlong    mx_val4, mx_adr4
              ''put the values of the addresses of the addresses in the local workspace (lolz at the confusing).
              rdlong    mx_val1, mx_val1
              rdlong    mx_val2, mx_val2
              rdlong    mx_val3, mx_val3
              rdlong    mx_val4, mx_val4                             




              'divide them all by 4
              shr       mx_val1, #2             'Divide by 4
              shr       mx_val2, #2             'Divide by 4 
              shr       mx_val3, #2             'Divide by 4 
              shr       mx_val4, #2             'Divide by 4 
              'read volumes
              rdlong    vol1, vol1_adr
              rdlong    vol2, vol2_adr
              rdlong    vol3, vol3_adr
              rdlong    vol4, vol4_adr
              'set volumes
              shr       mx_val1, vol1
              shr       mx_val2, vol2
              shr       mx_val3, vol3
              shr       mx_val4, vol4
              'add them back together
              add       mx_val1, mx_val2
              add       mx_val1, mx_val3
              add       mx_val1, mx_val4

              'read quality
              rdlong    qual, qual_adr
              'apply quality
              mov       qualmask, F_mask
              shl       qualmask, qual
              and       mx_val1, qualmask

              'read garble
              rdlong    m_garb, m_garb_adr
              'apply garble
              mov       garbmask, F_mask
              shr       garbmask, m_garb
              and       mx_val1, garbmask
              sub       m_garb, #2 wc
        if_nc shl       mx_val1, m_garb

              'read or mask
              rdlong    m_not, m_not_adr
              'apply mask
              shl       m_not, #24
              or        mx_val1, m_not

              'write result to output address
              wrlong    mx_val1, mx_out_adr

              jmp       #:MXStart                            
              
mx_adr1       long 0
mx_adr2       long 0
mx_adr3       long 0
mx_adr4       long 0
mx_out_adr    long 0

mx_val1       long 0
mx_val2       long 0
mx_val3       long 0
mx_val4       long 0

qual_adr     long 0
qual         long 0

m_garb_adr    long 0
m_garb        long 0
garbmask      long 0

m_not_adr     long 0
m_not         long 0
notmask       long 0

vol1_adr      long 0
vol2_adr      long 0
vol3_adr      long 0
vol4_adr      long 0
vol1          long 0
vol2          long 0
vol3          long 0
vol4          long 0

qualmask      long 0
F_Mask        long $FFFFFFFF

''
''************************************************************************************************************************************

              org       0
{{
                                            **********************************
--------------------------------------------*          PCM Engine:           *------------------------------------------------------
                                            **********************************
                                            
Function:     This engine keeps track of where the signal level of each channel should be in time. It first goes through a check
              through each channel to decide the level, while placing those levels in the mixer data. The engine next takes the
              mixer output and throws it on the PWM engine (a part of this engine)
How it works: For any wave you want to play, you must set done flags to 0 from SPIN.
Notes:       

        ------------------------------                                                         
     ┳─→| Fetch duration & done_flag |                                                         
     │  | values from main memory    |                                                         
     │  ---------┳--------------------                                                         
     │           │                                                                             
     │           ↓                                                                             
     │  ┳─────────────────────┳   yes   --------                                               
     │  │ Is channel 1 done?  ┣────────→| Skip ┣─────────────────────────────────────────┳     
     │  ┻────────┳────────────┻         --------                                         │     
     │           │                                                                       │     
     │           ↓no                                                                     │     
     │  ------------------------------                                                   │     
     │  | Decrement a tic of holding |                                                   │     
     │  | the PWM at its current val |                                                   │     
     │  ---------┳--------------------                                                   │     
     │           │                                                                       │     
     │           ↓                                                                       │                                             
     │  ┳─────────────────────┳       ------------------------------                     │     
     │  │ are the tics empty/ │ yes   | go to next PCM value for   |                     │     
     │  │ done/=0?            ┣──────→| PWM output                 |                     │     
     │  ┻────────┳────────────┻       ------------┳-----------------                     │     
     │           │                                │                                      │     
     │           ↓no                              ↓                                      │     
     │  ┳─────────────────────┳       ------------------------------                     │     
     │  │ is it at the end of │       | reset tic count to initial |                     │                     
     │  │ the wave (index ==  │←──────┫ parameter                  |                     │     
     │  │ 128)?               │       ------------------------------                     │     
     │  ┻──┳────────────┳─────┻                                                          │     
     │     │            ↓yes                                                             │     
     │     │         ------------------------------                                      │
     │     │         | Check for new tic value;   |                                      │
     │     │         | change in frequency        |                                      │
     │     │         ------------┳-----------------                                      │
     │     │                     ↓                                                       │
     │     │         ------------------------------                                      │
     │     │         | go back to first PCM value |                                      │
     │     │         | for the wave (reset index) |                                      │
     │     │         ------------┳-----------------                                      │
     │     │                     ↓                                                       │
     │     │         ------------------------------                                      │
     │     │         | decrement loop count (how  |                                      │
     │     │         | many times to play that    |                                      │
     │     │         | shape). Also update main   |                                      │
     │     │         | memory with this value.    |                                      │
     │     │         ------------┳-----------------                                      │
     │     │                     ↓                                                       │
     │     │          ┳─────────────────────┳          ------------------------------    │
     │     │          │ is loop count down  │   yes    | set channel 1 (flag) to    |    │     
     │     │          │ to 0?               ┣─────────→| done.                      |    │     
     │     │          ┻┳────────────────────┻          ----┳-------------------------    │     
     │     │           │no                                 │                             │     
     │     ↓           ↓                                   │                             │     
     │    ------------------------                         │                             │     
     │    | Do same routine for  |\                        │                             │     
     │    | channel 2, 3, and 4. | |\                      │                             │     
     │    ------------------------\| |←────────────────────┻                             │     
     │    \------------------------\ |←──────────────────────────────────────────────────┻     
     │     \-----------┳-------------|                                                         
     │                 │                                                                       
     │                 ↓                                                                       
     │     ------------------------------                                                      
     │     | Get mix and send it to PCM |                                                      
     ┻─────┫ engine (frqa)              |                                                                                          
           ------------------------------
                        
}}

          
              'get un-indexed addresses
PCM           mov       chan1_tic_adr, par      'freq1
              mov       chan2_tic_adr, par      'freq2
              mov       chan3_tic_adr, par      'freq3
              mov       chan4_tic_adr, par      'freq4
              mov       chan1_dur_adr, par      'dur1
              mov       chan2_dur_adr, par      'dur2
              mov       chan3_dur_adr, par      'dur3
              mov       chan4_dur_adr, par      'dur4
              mov       p_mx_adr1, par          'mix address 1     
              mov       p_mx_adr2, par          'mix address 2
              mov       p_mx_adr3, par          'mix address 3
              mov       p_mx_adr4, par          'mix address 4
              mov       p_mx_out_adr, par       'mix output address
              mov       chan1_done_adr, par     'channel 1 done flag address
              mov       chan2_done_adr, par     'channel 2 done flag address
              mov       chan3_done_adr, par     'channel 3 done flag address
              mov       chan4_done_adr, par     'channel 4 done flag address
              mov       datastart, par          'data area
              mov       p_pin, par              'audiopin
              ''indexes them
              add       chan2_tic_adr, #4       'freq
              add       chan3_tic_adr, #8       'freq
              add       chan4_tic_adr, #12      'freq
              add       chan1_dur_adr, #48      'dur
              add       chan2_dur_adr, #52      'dur
              add       chan3_dur_adr, #56      'dur
              add       chan4_dur_adr, #60      'dur
              add       p_mx_adr1, #84          'mix
              add       p_mx_adr2, #88          'mix
              add       p_mx_adr3, #92          'mix
              add       p_mx_adr4, #96          'mix
              add       p_mx_out_adr, #100      'mix out
              add       chan1_done_adr, #104    'flag
              add       chan2_done_adr, #108    'flag
              add       chan3_done_adr, #112    'flag
              add       chan4_done_adr, #116    'flag
              add       datastart, #36          'data area
              add       p_pin, #120             'audio pin

              rdlong    p_pin, p_pin            'get pin number
              shl       pinmask, p_pin          'shift it acordingly
              or        dira, pinmask           'add it to mask

              or        CtrCfg, p_pin           'add pin number to ctra mask
              mov       ctra, CtrCfg            'single ended duty

              rdlong    datastart, datastart
              add       p_chanadr1, datastart 
              add       p_chanadr2, p_chanadr1
              add       p_chanadr3, p_chanadr1
              add       p_chanadr4, p_chanadr1               

              mov       mstart, datastart
              sub       mstart, #4
              add       m214, mstart
              add       m414, mstart
              add       m614, mstart
              add       m814, mstart
              add       m218, datastart
              add       m418, datastart
              add       m618, datastart
              add       m818, datastart              
              


              'initialize tics
              rdlong    chan1_tic, chan1_tic_adr        '\
              rdlong    chan2_tic, chan2_tic_adr        ' \
              rdlong    chan3_tic, chan3_tic_adr        '  \
              rdlong    chan4_tic, chan4_tic_adr        '   update local frequency data with main memory

              'start blasting initial PCM's (since the will be initial values anyway)
              rdlong    p_temp, p_mx_out_adr            'get the current mix output into a temporary value
              mov       frqa, p_temp                    'put it on the PWM engine

              'initialize durs
:PStart       rdlong    chan1_dur, chan1_dur_adr        '\
              rdlong    chan2_dur, chan2_dur_adr        ' \
              rdlong    chan3_dur, chan3_dur_adr        '  \
              rdlong    chan4_dur, chan4_dur_adr        '   update local channel duration with main memory

              'see if SPIN decided to re-initialize a channel
              rdlong    chan1_done, chan1_done_adr      '\
              rdlong    chan2_done, chan2_done_adr      ' \
              rdlong    chan3_done, chan3_done_adr      '  \
              rdlong    chan4_done, chan4_done_adr      '   update local flag data with main memory

'Channel 1 update routine  
:Chan1        mov       p_temp, #1              '\
              sub       p_temp, chan1_done  wz  ' \
        if_z  jmp       #:Chan2               '  Is channel 1 flag set (done/1)

              sub       chan1_tic, #1  wz     'decrement a tic, make note of if it hit zero
       if_nz  jmp       #:EndWave1            'if tics aren't done, skip getting next PCM and resetting tic

              'NextPCM
              add       p_chanadr1, #4         'update p_chandr1 with address of next PCM value
              wrlong    p_chanadr1, p_mx_adr1  'put address of the next PCM value on p_mx_adr1 line for mixer
              rdlong    chan1_tic, chan1_tic_adr  'reset chan1 tic to initialized value

'end of wave?
:EndWave1     mov       p_temp, m214             'last address of PCM index (could be $214)
              sub       p_temp, p_chanadr1  wz     'if at end, zero flag will set
        if_nz jmp       #:Chan2                 'no need to update if not at end of index, proceed to next chan.      

'check for new tic value        
              rdlong    chan1_tic, chan1_tic_adr
'go back to first PCM value
              mov       p_chanadr1, datastart         'go back to first PCM value
'decrement loop count
              sub       chan1_dur, #1            'decrement amount of times to play wave
              wrlong    chan1_dur, chan1_dur_adr 'make sure main memory has an updated copy too                                   
'is loop count 0?
              mov       p_temp, #0                 '  |if not 0, go to next channel
              sub       p_temp, chan1_dur  wz      '  |if it is, go to next step
        if_nz jmp       #:Chan2                  '

'set chan1 to done
              mov       chan1_done, #1
              wrlong    chan1_done, chan1_done_adr 'update main memory as well                                                        


'Channel 2 update routine          
:Chan2        mov       p_temp, #1              '\
              sub       p_temp, chan2_done  wz  ' \
        if_z  jmp       #:Chan3               '  Is channel 2 flag set (done/1)

              sub       chan2_tic, #1  wz     'decrement a tic, make note of if it hit zero
        if_nz jmp       #:EndWave2            'if tics aren't done, skip getting next PCM and resetting tic

              'NextPCM
              add       p_chanadr2, #4         'update p_chandr1 with address of next PCM value
              wrlong    p_chanadr2, p_mx_adr2  'put address of the next PCM value on p_mx_adr1 line for mixer
              rdlong    chan2_tic, chan2_tic_adr  'reset chan1 tic to initialized value

'end of wave?
:EndWave2     mov       p_temp, m414             'last address of PCM index (could be $214)
              sub       p_temp, p_chanadr2  wz     'if at end, zero flag will set
        if_nz jmp       #:Chan3                 'no need to update if not at end of index, proceed to next chan.      

'check for new tic value        
              rdlong    chan2_tic, chan2_tic_adr        
'go back to first PCM value
              mov       p_chanadr2, m218         'go back to first PCM value
'decrement loop count
              sub       chan2_dur, #1            'decrement amount of times to play wave
              wrlong    chan2_dur, chan2_dur_adr 'make sure main memory has an updated copy too                                 
'is loop count 0?
              mov       p_temp, #0                 '  |if not 0, go to next channel
              sub       p_temp, chan2_dur  wz      '  |if it is, go to next step
        if_nz jmp       #:Chan3                  '

'set chan1 to done
              mov       chan2_done, #1
              wrlong    chan2_done, chan2_done_adr 'update main memory as well                                                          

'Channel 3 update routine          
:Chan3        mov       p_temp, #1              '\
              sub       p_temp, chan3_done  wz  ' \
        if_z  jmp       #:Chan4               '  Is channel 2 flag set (done/1)

              sub       chan3_tic, #1  wz     'decrement a tic, make note of if it hit zero
       if_nz  jmp       #:EndWave3            'if tics aren't done, skip getting next PCM and resetting tic

              add       p_chanadr3, #4         'update p_chandr1 with address of next PCM value
              wrlong    p_chanadr3, p_mx_adr3  'put address of the next PCM value on p_mx_adr1 line for mixer
              rdlong    chan3_tic, chan3_tic_adr  'reset chan1 tic to initialized value

'end of wave?
:EndWave3     mov       p_temp, m614             'last address of PCM index (could be $214)
              sub       p_temp, p_chanadr3  wz     'if at end, zero flag will set
        if_nz jmp       #:Chan4                 'no need to update if not at end of index, proceed to next chan.      

'check for new tic value        
              rdlong    chan3_tic, chan3_tic_adr        
'go back to first PCM value
              mov       p_chanadr3, m418         'go back to first PCM value
'decrement loop count
              sub       chan3_dur, #1            'decrement amount of times to play wave
              wrlong    chan3_dur, chan3_dur_adr 'make sure main memory has an updated copy too                                  
'is loop count 0?
              mov       p_temp, #0                 '  |if not 0, go to next channel
              sub       p_temp, chan3_dur  wz      '  |if it is, go to next step
        if_nz jmp       #:Chan4                  '

'set chan1 to done
              mov       chan3_done, #1
              wrlong    chan3_done, chan3_done_adr 'update main memory as well                                                      

'Channel 4 update routine          
:Chan4        mov       p_temp, #1              '\
              sub       p_temp, chan4_done  wz  ' \
        if_z  jmp       #:Send                '  Is channel 2 flag set (done/1)

              sub       chan4_tic, #1  wz     'decrement a tic, make note of if it hit zero
       if_nz  jmp       #:EndWave4            'if tics are done, Next PCM

              add       p_chanadr4, #4         'update p_chandr1 with address of next PCM value
              wrlong    p_chanadr4, p_mx_adr4  'put address of the next PCM value on p_mx_adr1 line for mixer
              rdlong    chan4_tic, chan4_tic_adr  'reset chan1 tic to initialized value

'end of wave?
:EndWave4     mov       p_temp, m814             'last address of PCM index (could be $214)
              sub       p_temp, p_chanadr4  wz     'if at end, zero flag will set
        if_nz jmp       #:Send                 'no need to update if not at end of index, proceed to next chan.      

'check for new tic value        
              rdlong    chan4_tic, chan4_tic_adr        
'go back to first PCM value
              mov       p_chanadr4, m618         'go back to first PCM value
'decrement loop count
              sub       chan4_dur, #1            'decrement amount of times to play wave
              wrlong    chan4_dur, chan4_dur_adr 'make sure main memory has an updated copy too                                  
'is loop count 0?
              mov       p_temp, #0                 '  |if not 0, go to next channel
              sub       p_temp, chan4_dur  wz      '  |if it is, go to next step
        if_nz jmp       #:Send                  '

'set chan1 to done
              mov       chan4_done, #1
              wrlong    chan4_done, chan4_done_adr 'update main memory as well                                                         

:Send         rdlong    p_temp, p_mx_out_adr    'get value of mix out
              mov       frqa, p_temp            'put it on the PCM
              jmp       #:PStart



'Flags
'1 means done, 0 means still working
chan1_done      long 0
chan2_done      long 0
chan3_done      long 0
chan4_done      long 0
chan1_done_adr  long 0
chan2_done_adr  long 0
chan3_done_adr  long 0
chan4_done_adr  long 0

'PWM 'tics'
chan1_tic     long 0
chan2_tic     long 0
chan3_tic     long 0
chan4_tic     long 0
chan1_tic_adr long 0
chan2_tic_adr long 0
chan3_tic_adr long 0
chan4_tic_adr long 0

'loop counts
chan1_dur     long 0
chan2_dur     long 0
chan3_dur     long 0
chan4_dur     long 0
chan1_dur_adr long 0
chan2_dur_adr long 0
chan3_dur_adr long 0
chan4_dur_adr long 0

p_temp          long 0

p_mx_adr1       long 0
p_mx_adr2       long 0
p_mx_adr3       long 0
p_mx_adr4       long 0
p_mx_out_adr    long 0

p_mx_val1       long 0
p_mx_val2       long 0
p_mx_val3       long 0
p_mx_val4       long 0

p_pin         long 0
CtrCfg        long %0_00110_000_00000000_000000_000_000000  'single ended duty, pin 31 
pinmask       long $00000001                                'make pin 31 an output

'These are just masks higher than the 9-bit immediate values would allow. I know the names are arbitrary looking,
'they weren't arbitrary when I first created them, I swear. I may fix them when I'm finished with everything, I
'have just changed their values too much to what to do find and replace everytime.
m214          long $200
m218          long $200         
m414          long $400
m418          long $400
m614          long $600
m618          long $600
m814          long $800
m818          long $800
mstart        long 0

datastart     long 0
p_chanadr1    long 0                          'address of chan1 wave uncompressed
p_chanadr2    long $200                         'address of chan2 wave uncompressed
p_chanadr3    long $400                         'address of chan3 wave uncompressed
p_chanadr4    long $600                         'address of chan4 wave uncompressed

fit     220            '496 is highest


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
