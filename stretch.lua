engine.name = "PaulStretch"

local active_voice = 1;

function init()
   for i=1,4 do
     -- file
     params:add_file(i .. "sample", i .. " sample")
     params:set_action(i .. "sample", function(file) engine.read(i, file) end)

     params:add_control(i .. "stretch", i .. " stretch", controlspec.new(10, 1000, 'exp', 0, 100))
     params:set_action(i .. "stretch", function(s) engine.stretch(i, s) end)

     -- params:add_taper(i .. "volume", i .. " volume",  0, 1, 0.5, 0.1)
     -- params:set_action(i .. "volume", function(s) engine.volume(i, s) end)

     params:add_taper(i .. "pan", i .. " pan",  -1, 1, 0, 0.1)
     params:set_action(i .. "pan", function(s) engine.pan(i, s) end)
   end

end

function key(n, v)
  if n == 1 then
   -- load defaults for testing
    engine.read(1, _path.code .. "nc02-rs/lib/nc02-perc.wav")
    engine.read(2, _path.code .. "nc02-rs/lib/nc02-tonal.wav")
    engine.read(3, _path.code .. "nc02-rs/lib/dawnchorus.wav")
    engine.read(4, _path.code .. "nc02-rs/lib/faraway.wav")
  end
end

