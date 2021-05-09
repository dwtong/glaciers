Engine_PaulStretch : CroneEngine {
	var grainEnv;
	var buffer1;
	var buffer2;
	var synth1;
	var synth2;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		SynthDef(\paulstretch, {
			arg out, buf, envbuf, pan=0, stretch=50, window=0.25, amp=0.7;
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
			Out.ar(out, Pan2.ar(Mix.new(sig), pan));
		}).add;

		context.server.sync();

		// The grain envelope
		grainEnv = Buffer.alloc(context.server, context.server.sampleRate, 1);
		grainEnv.loadCollection(Signal.newClear(context.server.sampleRate).waveFill({|x| (1 - x.pow(2)).pow(1.25)}, -1.0, 1.0));

		this.addCommand("play1", "s", { arg msg;
			var path = msg[1];
			buffer1 = Buffer.readChannel(context.server, path, channels: [0]);
			synth1 = Synth(\paulstretch, [\buf, buffer1, \envbuf, grainEnv, stretch: 100, \window, 0.250, \pan, -0.8]);
		});

		this.addCommand("play2", "s", { arg msg;
			var path = msg[1];
			buffer2 = Buffer.readChannel(context.server, path, channels: [0]);
			synth2 = Synth(\paulstretch, [\buf, buffer2, \envbuf, grainEnv, stretch: 100, \window, 0.250, \pan, 0.8]);
		});

		this.addCommand("stretch1", "i", { arg msg;
			synth1.set(\stretch, msg[1]);
		});

		this.addCommand("stretch2", "i", { arg msg;
			synth2.set(\stretch, msg[1]);
		});
	}

	free {
		// TODO more nuanced freeing
		context.server.freeAll;
	}
}

