engine.name = "PaulStretch"

local shift = false;

function init()
end

function key(n, v)
  if n == 2 then
    engine.play1(_path.code .. "nc02-rs/lib/nc02-perc.wav")
  elseif n == 3 then
    engine.play2(_path.code .. "nc02-rs/lib/nc02-tonal.wav")
  end
end

