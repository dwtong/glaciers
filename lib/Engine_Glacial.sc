Engine_Glacial : CroneEngine {
	var buffers;
	var grainEnv;
	var voices;
	var pg;

	var maxVoices = 4;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		this.stretchdef.add;
		context.server.sync;

		grainEnv = Buffer.alloc(context.server, context.server.sampleRate, 1);
		grainEnv.loadCollection(Signal.newClear(context.server.sampleRate).waveFill({|x| (1 - x.pow(2)).pow(1.25)}, -1.0, 1.0));

		pg = ParGroup.head(context.xg);

		buffers = Array.fill(maxVoices, {arg i; Buffer.alloc(context.server, context.server.sampleRate, 1); });
		voices = Array.fill(maxVoices, {arg i;
			0.2.wait; // Workaround: wait to avoid jack "Supercollider was not finished" errors
			Synth(\stretch, [buf: buffers[i], envbuf: grainEnv, out: context.out_b.index], target: pg);
		});

		context.server.sync;

		this.addCommands;
	}

	stretchdef {
		^SynthDef(\stretch, {
			arg out, buf, envbuf, pan=0, stretch=100, stretchscale=1, window=0.25, amp=0, pitchMix=0, pitchHarm=2.0, panRate=1/10, panDepth=0;
			var trigPeriod, sig, chain, trig, pos, fftSize, fftCompensation;

			// Calculating fft buffer size according to suggested window size
			// Reduce by half to optimise for Norns
			fftSize = (2 ** floor(log2(window * SampleRate.ir))) / 2;

			// scale stretch based on buffer size
			stretch = stretch * stretchscale;

			// Windows (using grains)
			trigPeriod = fftSize/SampleRate.ir;
			trig = Impulse.ar(1/trigPeriod);

			// grain position
			// second grain position is offset
			pos = Demand.ar(trig, 0, demandUGens: Dseries(0, trigPeriod/stretch));
			pos = [pos, pos + (trigPeriod/(2*stretch))];
			sig = GrainBuf.ar(1, trig, trigPeriod, buf, 1, pos, envbufnum: envbuf) * amp;

			// FFT Processing
			sig = sig.collect({ |item, i|
				// convert signal to fft (frequency domain)
				chain = FFT(LocalBuf(fftSize), item, hop: 1.0, wintype: -1);

				// randomise phase as per paulstretch algo
				chain = PV_Diffuser(chain, 1 - trig);

				// convert back to ifft (time domain)
				item = IFFT(chain, wintype: -1);
			});

			// Reapply the grain envelope because the FFT phase randomization removes it
			sig = sig * PlayBuf.ar(1, envbuf, 1/(trigPeriod), loop:1);

			// Delay second grain by half a grain length for superposition
			sig[1] = DelayC.ar(sig[1], trigPeriod/2, trigPeriod/2);

			// Compensate for delay introduced by FFT
			fftCompensation = (fftSize - BlockSize.ir)/SampleRate.ir;
			sig = DelayC.ar(sig, fftCompensation, fftCompensation);

			// Panning
			sig = Mix.new(sig);
			sig = Pan2.ar(sig, SinOsc.kr(panRate).range(pan - panDepth, pan + panDepth));

			// Pitch shifting
			sig = XFade2.ar(sig, PitchShift.ar(sig, trigPeriod, pitchHarm, 0, 0.1), pitchMix * 2 - 1);

			Out.ar(out, sig);
		});
	}

	loadBuffer { arg voice, path;
		var newbuf = Buffer.readChannel(context.server, path, channels: [0], action: {
			buffers[voice].free;
			buffers[voice] = newbuf;
			voices[voice].set(\buf, newbuf, \stretchscale, newbuf.duration);
		});
	}

	addCommands {
		this.addCommand("read", "is", { arg msg;
			this.loadBuffer(msg[1] - 1, msg[2]);
		});

		this.addCommand("stretch", "ii", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\stretch, msg[2]);
		});

		this.addCommand("pan", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\pan, msg[2]);
		});

		this.addCommand("pitchmix", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\pitchMix, msg[2]);
		});

		this.addCommand("pitchharm", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\pitchHarm, msg[2]);
		});

		this.addCommand("pandepth", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\panDepth, msg[2]);
		});

		this.addCommand("panrate", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\panRate, msg[2]);
		});

		this.addCommand("volume", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\amp, msg[2].dbamp);
		});
	}

	free {
		buffers.do({ arg b; b.free });
		voices.do({ arg v; v.free });
		grainEnv.free;
	}
}

