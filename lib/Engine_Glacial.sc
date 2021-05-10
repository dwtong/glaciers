Engine_Glacial : CroneEngine {
	var buffers;
	var grainEnv;
	var maxVoices;
	var voices;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		maxVoices = 4;

		SynthDef(\stretch, {
			arg out, buf, envbuf, pan=0, stretch=50, window=0.25, amp=0.7, pitchmix=0.5, pitchharm=2.0;
			var trigPeriod, sig, chain, trig, pos, fftSize, fftCompensation;

			// Calculating fft buffer size according to suggested window size
			// Reduce by half to optimise for Norns
			fftSize = (2 ** floor(log2(window * SampleRate.ir))) / 2;

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

			// Mix grains and pan output
			sig = Pan2.ar(Mix.new(sig), pan);

			sig = XFade2.ar(sig, PitchShift.ar(sig, 0.5, pitchharm, 0.01, 0.02), pitchmix * 2 - 1);

			// TODO move reverb to separate synth
			// sig = XFade2.ar(sig, JPverb.ar(HPF.ar(sig, 100), t60: 30, size: 5), verbmix * 2 - 1);

			Out.ar(out, sig);
		}).add;

		context.server.sync();

		// The grain envelope
		grainEnv = Buffer.alloc(context.server, context.server.sampleRate, 1);
		grainEnv.loadCollection(Signal.newClear(context.server.sampleRate).waveFill({|x| (1 - x.pow(2)).pow(1.25)}, -1.0, 1.0));

		// Initialise empty buffers and synths
		buffers = Array.fill(maxVoices, {arg i; Buffer.alloc(context.server, context.server.sampleRate, 1); });
		voices = Array.fill(maxVoices, {arg i;
			// Workaround: wait to avoid jack "Supercollider was not finished" errors
			0.1.wait;
			Synth(\stretch, [buf: buffers[i], envbuf: grainEnv]);
		});

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
			voices[voice].set(\pitchmix, msg[2]);
		});

		this.addCommand("pitchharm", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\pitchharm, msg[2]);
		});

		this.addCommand("volume", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\amp, msg[2]);
		});
	}

	loadBuffer { arg voice, path;
		var newbuf = Buffer.readChannel(context.server, path, channels: [0], action: {
			buffers[voice].free;
			buffers[voice] = newbuf;
			voices[voice].set(\buf, newbuf);
		});
	}

	free {
		buffers.do({ arg b; b.free });
		voices.do({ arg v; v.free });
	}
}

