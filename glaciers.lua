-- glaciers
-- @dwtong
-- https://llllllll.co/t/glaciers/45117
--
-- extreme sound stretcher
-- based on paulstretch
-- four voices with harmoniser
--
-- Load samples in params menu
-- E1 - Change voice
-- E2 - Select parameter
-- E3 - Change parameter value

engine.name = "Glacial"

MusicUtil = require "musicutil"

local voice = 1;
local max_voices = 4;
local render_params = {[1]="volume", [2]="stretch", [3]="pan spread", [4]="pan rate", [5]="harmonic oct", [6]="harmonic mix"}
local active_param = 1

function init()
  for i = 1, max_voices do
    params:add{type = "file", id = i .. "sample", name = i .. " sample",
      action = function(file) engine.read(i, file) end}

    params:add{type = "control", id = i .. "volume", name = i .. " volume",
      controlspec = controlspec.new(-48, 5, "lin", 1, -48, "db"),
      action = function(v) engine.volume(i, v) end}

    params:add{type = "taper", id = i .. "stretch", name = i .. " stretch",
      min=1, max=4000, default = 100, k = 25,
      action = function(s) engine.stretch(i, s) end}

    params:add{type = "taper", id = i .. "pan rate", name = i .. " pan rate",
      min=0.1, max=30, default = 10, k = -1, units = "s",
      action = function(s) engine.panrate(i, 1/s) end}

    params:add{type = "taper", id = i .. "pan position", name = i .. " pan position",
      min=-1.0, max=1.0, default = 0.0,
      action = function(p) engine.pan(i, p) end}

    params:add{type = "control", id = i .. "pan spread", name = i .. " pan spread",
      controlspec = controlspec.new(0.0, 1.0, "lin", 0.01, 0.0),
      action = function(s) engine.pandepth(i, s) end}

    params:add{type = "control", id = i .. "harmonic mix", name = i .. " harmonic mix",
      controlspec = controlspec.new(0.0, 1.0, "lin", 0.01, 0.0),
      action = function(s) engine.pitchmix(i, s) end}

    params:add{type = "number", id = i .. "harmonic oct", name = i .. " harmonic oct",
      min = -3, max = 3, default = 1,
      action = function(o) engine.pitchharm(i, MusicUtil.interval_to_ratio(12 * o)) end}
  end

  redraw()
end

function enc(n, d)
  local change = util.clamp(d, -1, 1)

  if n == 1 then
    voice = math.min(4, (math.max(voice + change, 1)))
  elseif n == 2 then
    active_param = math.min(6, (math.max(active_param + change, 1)))
  elseif n == 3 then
    local param = voice .. render_params[active_param]
    params:delta(param, d)
  end

  redraw()
end


function redraw()
  screen.clear()

  screen.font_face(1)
  screen.font_size(48)
  screen.level(15)
  screen.move(4, 47)
  screen.text(voice)

  screen.font_face(1)
  screen.font_size(8)

  for i,name in pairs(render_params) do
    if active_param == i then
      screen.level(15)
      screen.move(32, i * 10)
      screen.text(">")
    else
      screen.level(2)
    end
    screen.move(40, i * 10)
    screen.text(string.upper(name) .. ": ")
    screen.text(params:string(voice .. name))
  end

  screen.update()
end
