PCM
===

This is a project I worked on from August of 2009 to October 24 2009. I plan to pick it back up at some point, since I had already invested so much into it.

This is an audio driver for the Propeller microcontroller, most of it is written in assembly, the high level code for the API is written in Spin.

The other details are in the documentation part of the source code for now.

DON'T USE
===
I have since 'Forked' this project over to LPDJ. To progress on the driver, I had to take some major steps back before I could step forward (like removing all of the precanned wavetables and the decompression engine). So it didn't make sense to keep doing pushes to this PCM project that would kill functionality.

I say don't use because I naively programmed the timing of the 4-channel PCM engine. The timing of processing the channels is non-deterministic, which is a big problem with how the driver works. you can play notes just fine on all of the channels, but if you do use more than one channel, all the notes start to drop in pitch. So you can play chords, just not the ones you expect to. This has been fixed on LPDJ.

Even though that was a (relatively) simple fix, I still decided to go a different way with the driver in LPDJ. Instead of pre-canned wave table data, I am creating 'instruments.' For example, you can call a PulseWave instrument to load a wave table into a channel at a certain duty and even repeating the wave pattern many (lower fidelity) times in divisions. This instrument routine is launched on a dedicated cog and terminates when finished (small fraction of time). This decision was initially made due to size. Even though the pre-canned wave tables were compressed in half, they were still starting to take up a lot of space. So with 'instruments,' an instrument can versatally create many wave shapes per instrument, and the engine for each instrument is a fraction of the size of just one pre-canned wave table. Worth the complexity
