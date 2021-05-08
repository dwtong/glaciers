engine.name = "PaulStretch"

function init()
end

function key(n, v)
  if n == 2 then
    engine.play(-1)
  elseif n == 3 then
    engine.play(1)
  end
end

