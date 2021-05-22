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

local voice = 1
local max_voices = 4
local pages = {[1]="sound", [2]="pan", [3]="filter"}
local page_params = {}

page_params["sound"] = {[1]="volume", [2]="stretch", [3]="harmonic_oct", [4]="harmonic_mix"}
page_params["pan"] = {[1]="position", [2]="lfo_spread", [3]="lfo_rate"}
page_params["filter"] = {[1]="freq", [2]="width"}

local active_page = 1
local active_param = 1
local alt = false
local rec = false

function init()
  for i=1, max_voices do add_params(i) end
  redraw()
end

function key(n, z)
  if n == 1 then
    alt = z == 1
  end

  if z == 1 then
    if n == 2 and active_page > 1 then
      active_page = active_page - 1
    elseif n == 3 and active_page < 3 then
      active_page = active_page + 1
    end
  end

  redraw()
end

function enc(n, d)
  local change = util.clamp(d, -1, 1)
  local active_page_params = page_params[pages[active_page]]
  local param_name = voice .. "_" .. pages[active_page] .. "_" .. active_page_params[active_param]

  if n == 1 and not (alt or rec) then
    voice = math.min(max_voices, (math.max(voice + change, 1)))
  elseif n == 2 then
    active_param = math.min(#active_page_params, (math.max(active_param + change, 1)))
  elseif n == 3 then
    params:delta(param_name, d)
  end

  redraw()
end


function redraw()
  local page_name = (alt or rec) and "buffer" or pages[active_page]
  local render_params = page_params[page_name]

  screen.clear()

  screen.font_face(1)
  screen.font_size(48)
  screen.level(15)
  screen.move(4, 47)
  screen.text(voice)

  screen.font_face(1)
  screen.font_size(8)

  screen.move(45, 10)
  screen.text(page_name:upper())

  screen.font_face(1)
  screen.font_size(8)

  if alt or rec then
    screen.level(15)
    screen.move(45, 25)
    screen.text("state: playing")

    screen.level(2)
    screen.move(45, 35)
    screen.text("K2: clear")
    screen.move(45, 45)
    screen.text("K3: record")
  else
    for i, param_name in pairs(render_params) do
      if active_param == i then
        screen.level(15)
        screen.move(37, (i + 1.5) * 10)
        screen.text(">")
      else
        screen.level(2)
      end
      screen.move(45, (i + 1.5) * 10)
      screen.text(param_name:gsub("_", " ") .. ": ")
      screen.text(params:string(voice .. "_" .. page_name .. "_" .. param_name))
    end
  end

  screen.update()
end

function add_params(voice)
  params:add{type = "file", id = voice .. "_sound_sample", name = voice .. " sample",
    action = function(file)
      engine.read(voice, file)
      redraw()
    end}

  params:add{type = "control", id = voice .. "_sound_volume", name = voice .. " volume",
    controlspec = controlspec.DB,
    action = function(v)
      engine.volume(voice, v)
      redraw()
    end}

  params:add{type = "taper", id = voice .. "_sound_stretch", name = voice .. " stretch",
    min=1, max=4000, default = 100, k = 25,
    action = function(v)
      engine.stretch(voice, v)
      redraw()
    end}

  params:add{type = "control", id = voice .. "_sound_harmonic_mix", name = voice .. " harmonic mix",
    controlspec = controlspec.UNIPOLAR,
    action = function(v)
      engine.pitchmix(voice, v)
      redraw()
    end}

  params:add{type = "number", id = voice .. "_sound_harmonic_oct", name = voice .. " harmonic oct",
    min = -3, max = 3, default = 1,
    action = function(v)
      engine.pitchharm(voice, MusicUtil.interval_to_ratio(12 * v))
      redraw()
    end}

  params:add{type = "control", id = voice .. "_pan_position", name = voice .. " pan position",
    controlspec = controlspec.PAN,
    action = function(v)
      engine.pan(voice, v)
      redraw()
    end}

  params:add{type = "taper", id = voice .. "_pan_lfo_rate", name = voice .. " pan rate",
    min=0.1, max=30, default = 10, k = -1, units = "s",
    action = function(v)
      engine.panrate(voice, 1/v)
      redraw()
    end}

  params:add{type = "control", id = voice .. "_pan_lfo_spread", name = voice .. " pan spread",
    controlspec = controlspec.UNIPOLAR,
    action = function(v)
      engine.pandepth(voice, v)
      redraw()
    end}

  params:add{type = "number", id = voice .. "_filter_width", name = voice .. " filter width",
    min = 1, max = 10, default = 10,
    action = function(v)
      engine.bpwidth(voice, v)
      redraw()
    end}

  params:add{type = "control", id = voice .. "_filter_freq", name = voice .. " filter freq",
    controlspec = controlspec.FREQ,
    action = function(v)
      engine.bpfreq(voice, v)
      redraw()
    end}
end
