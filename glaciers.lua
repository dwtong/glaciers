engine.name = "Glacial"

local voice = 1;
local max_voices = 4;
local started = false
local render_params = {"volume", "stretch", "pan depth", "pan rate", "harmonics", "harmonics mix"}
local active_param = 1

function init()
  for i=1,max_voices do
    -- file
    params:add_file(i .. "sample", i .. " sample")
    params:set_action(i .. "sample", function(file) engine.read(i, file) end)

    params:add_control(i .. "stretch", i .. " stretch", controlspec.new(1, 4000, 'exp', 0, 100, "x"))
    params:set_action(i .. "stretch", function(s) engine.stretch(i, s) end)

    params:add_control(i .. "volume", i .. " volume", controlspec.new(-48, 5, 'lin', 1, -18, "db"))
    params:set_action(i .. "volume", function(s) engine.volume(i, s) end)

    params:add_control(i .. "pan", i .. " pan", controlspec.new(-1.0, 1.0, 'lin', 0.05, 0.0))
    params:set_action(i .. "pan", function(s) engine.pan(i, s) end)

    params:add_control(i .. "pan rate", i .. " pan rate", controlspec.new(1, 5000, 'exp', 1, 0, "ms"))
    params:set_action(i .. "pan rate", function(s) engine.panrate(i, s/1000) end)

    params:add_control(i .. "pan depth", i .. " pan depth", controlspec.new(0.0, 1.0, 'lin', 0.05, 0.0))
    params:set_action(i .. "pan depth", function(s) engine.pandepth(i, s) end)

    params:add_control(i .. "harmonics mix", i .. " harmonics mix", controlspec.new(0.0, 1.0, 'lin', 0.05, 0.0))
    params:set_action(i .. "harmonics mix", function(s) engine.pitchmix(i, s) end)

    params:add_control(i .. "harmonics", i .. " harmonics", controlspec.new(0.1, 4.0, 'lin', 0.1, 2.0))
    params:set_action(i .. "harmonics", function(s) engine.pitchharm(i, s) end)
  end

  -- TODO do I actually need this or do I need to fix my engine "free" method for restarts
  started = true

  redraw()
end

function enc(n, d)
  -- TODO is there a better way to handle encoder sensitivity?
  local change = util.clamp(d, -1, 1)

  if n == 1 then
    voice = math.min(4, (math.max(voice + change, 1)))
    redraw()
  elseif n == 2 then
    active_param = math.min(6, (math.max(active_param + change, 1)))
    redraw()
  end
end


function redraw()
  screen.clear()

  screen.font_face(1)
  screen.font_size(48)
  screen.level(15)
  screen.move(7, 47)
  screen.text(voice)

  screen.font_face(1)
  screen.font_size(8)

  if started then
    for i,name in ipairs(render_params) do
      if active_param == i then
        screen.level(15)
        screen.move(37, i * 10)
        screen.text(">")
      else
        screen.level(2)
      end
      screen.move(45, i * 10)
      screen.text(string.upper(name) .. ": ")
      screen.text(params:string(voice .. name))
    end
  end

  screen.update()
end
