engine.name = "Glacial"

local active_voice = 1;
local max_voices = 4;

function init()
   for i=1,max_voices do
     -- file
     params:add_file(i .. "sample", i .. " sample")
     params:set_action(i .. "sample", function(file) engine.read(i, file) end)

     params:add_control(i .. "stretch", i .. " stretch", controlspec.new(1, 4000, 'exp', 0, 100))
     params:set_action(i .. "stretch", function(s) engine.stretch(i, s) end)

     params:add_control(i .. "volume", i .. " volume", controlspec.new(0.0, 1.0, 'lin', 0.05, 0.50))
     params:set_action(i .. "volume", function(s) engine.volume(i, s) end)

     params:add_control(i .. "pan", i .. " pan", controlspec.new(-1.0, 1.0, 'lin', 0.05, 0.0))
     params:set_action(i .. "pan", function(s) engine.pan(i, s) end)

     params:add_control(i .. "pitchmix", i .. " pitchmix", controlspec.new(0.0, 1.0, 'lin', 0.05, 0.5))
     params:set_action(i .. "pitchmix", function(s) engine.pitchmix(i, s) end)

     params:add_control(i .. "pitchharm", i .. " pitchharm", controlspec.new(0.1, 4.0, 'lin', 0.1, 2.0))
     params:set_action(i .. "pitchharm", function(s) engine.pitchharm(i, s) end)
   end

end

function key(n, v)
  if n == 2 then
   -- load defaults for testing
    engine.read(1, _path.code .. "nc02-rs/lib/nc02-perc.wav")
    engine.read(2, _path.code .. "nc02-rs/lib/nc02-tonal.wav")
    engine.read(3, _path.code .. "nc02-rs/lib/dawnchorus.wav")
    engine.read(4, _path.code .. "nc02-rs/lib/faraway.wav")
  end
end

