Engine_PaulStretch : CroneEngine {

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		var server = Crone.server;
		var stretchdef = SynthDef(\paulstretch, {
			arg out, buf, envbuf, pan=0, stretch=50, window=0.25, amp=1;
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
		});

		stretchdef.send(server);
		server.sync();

		// EXAMPLE
		~buffer1 = Buffer.readChannel(server, "/home/we/dust/audio/tehn/whirl1.aif", channels: [0]);
		~buffer2 = Buffer.readChannel(server, "/home/we/dust/audio/tehn/whirl1.aif", channels: [1]);

		// The grain envelope
		~envBuf = Buffer.alloc(server, server.sampleRate, 1);

		// do FFT math language side (signal is language based, buffer is server based)
		// possibly move this to be evaluated server side with LocalBuf?
		// potentially can simplify envelope too somehow? default hann?
		~envSignal = Signal.newClear(server.sampleRate).waveFill({|x| (1 - x.pow(2)).pow(1.25)}, -1.0, 1.0);
		~envBuf.loadCollection(~envSignal);
		server.sync();


		this.addCommand("play", "f", { arg msg;
			Synth(\paulstretch, [\buf, ~buffer1, \envbuf, ~envBuf, stretch: 100, \window, 0.250, \pan, msg[1]]);
		});
	}

	free {
		// Aggressive freeing
		Crone.server.freeAll;
	}
}

