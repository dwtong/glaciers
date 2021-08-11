-- glaciers
-- @dwtong
-- https://llllllll.co/t/glaciers
--
-- extreme sound stretcher
-- based on paulstretch
-- four voices with harmoniser
--
-- Hold K1 to open buffer menu
-- K2 to load file
-- K3 to record
--
-- K2 and K3 change pages
-- E1 - Change voice
-- E2 - Select parameter
-- E3 - Change parameter value
--
-- Photo of Titlis by Audrius
-- Meskauskas on Wikipedia
-- Commons.

engine.name = "Glacial"

musicutil = require "musicutil"
fileselect = require "fileselect"

local redraw_fs = false

local voice = 1
local max_voices = 4
local voice_states = {}
local pages = {[1]="sound", [2]="pan", [3]="filter"}

local page_params = {}

page_params["sound"] = {[1]="volume", [2]="stretch", [3]="harmonic_oct", [4]="harmonic_mix"}
page_params["pan"] = {[1]="position", [2]="lfo_spread", [3]="lfo_rate"}
page_params["filter"] = {[1]="freq", [2]="width"}

local states = {}

states["recording"] = {
  k2_label="clear buffer", k2_action=function() clear_buffer() end,
  k3_label="save recording", k3_action=function() save_recording() end
}

states["playing"] = {
  k2_label="clear buffer", k2_action=function() clear_buffer() end,
  k3_label="record input", k3_action=function() record_input() end
}

states["stopped"] = {
  k2_label="load file", k2_action=function() load_file() end,
  k3_label="record input", k3_action=function() record_input() end
}

local active_page = 1
local active_param = 1

local alt = false
local rec_start = 0
local rec_finish = 0

function init()

  params:add_separator("GLOBAL")
  params:add{type = "number", id = "gain_offset", name = "gain offset",
    min = -12, max = 12, default = 0,
    action = function(d)
      for i=1, max_voices do
        local vol = params:get(i .. "_sound_volume") + d
        engine.volume(i, vol)
      end
    end
  }

  for i=1, max_voices do
    add_params(i)
    voice_states[i] = "stopped"
  end

  redraw()
end

function key(n, z)
  local voice_state = voice_states[voice] 

  if z == 1 then
    if alt and n == 2 then
      states[voice_state].k2_action()
    elseif alt and n == 3 then
      states[voice_state].k3_action()
    else
      change_page(n)
    end
  end

  if z == 0 then
    alt = voice_state == "recording"
  end

  if redraw_fs then
    fileselect.redraw()
  else
    redraw()
  end
end

function enc(n, d)
  local change = util.clamp(d, -1, 1)
  local active_page_params = page_params[pages[active_page]]
  local param_name = voice .. "_" .. pages[active_page] .. "_" .. active_page_params[active_param]

  if n == 1 and voice_states[voice] ~= "recording" then
    voice = math.min(max_voices, (math.max(voice + change, 1)))
  elseif n == 2 then
    active_param = math.min(#active_page_params, (math.max(active_param + change, 1)))
  elseif n == 3 then
    params:delta(param_name, d)
  end

  redraw()
end

function redraw()
  local voice_state = voice_states[voice]
  local page_name = alt and "buffer" or pages[active_page]
  local render_params = page_params[page_name]
  local state = states[voice_state]

  screen.clear()

  screen.display_png(_path.this.path.."img/glacier-"..voice..".png", 0, 0)

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

  if page_name == "buffer" then
    screen.level(15)
    screen.move(45, 25)
    screen.text("state: " .. voice_state)

    screen.level(2)
    screen.move(45, 35)
    screen.text("K2: " .. state.k2_label)
    screen.move(45, 45)
    screen.text("K3: " .. state.k3_label)
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

function change_page(n)
  if n == 1 then
    alt = true
  elseif n == 2 and active_page > 1 then
    active_page = active_page - 1
  elseif n == 3 and active_page < 3 then
    active_page = active_page + 1
  end

  active_param = 1
end

function record_input()
  print("record input " .. voice)

  rec_start = util.time()

  audio.level_eng_cut(0)
  audio.level_tape_cut(0)
  softcut.buffer_clear()

  for i = 1, 2 do
    softcut.enable(i, 1)
    softcut.pan(i, i == 1 and 1 or -1)
    softcut.buffer(i, i)
    softcut.level(i, 0)

    softcut.rec(i, 1)
    softcut.play(i, 1)
    softcut.rate(i, 1)
    softcut.position(i, 0)

    softcut.loop_start(i, 0)
    softcut.loop_end(i, 60)

    softcut.rec_level(i, 1.0)
    softcut.pre_level(i, 1.0)
  end

  softcut.level_input_cut(1, 1, 1)
  softcut.level_input_cut(1, 2, 0)
  softcut.level_input_cut(2, 1, 0)
  softcut.level_input_cut(2, 2, 1)

  voice_states[voice] = "recording"
end

function save_recording()
  print("save recording " .. voice)

  rec_finish = util.time()

  local path = _path.audio .. "glaciers/"
  local file = path .. os.date("%y%m%d_%H%M%S") .. ".wav"

  for i = 1, 2 do
    softcut.rec(i, 0)
    softcut.play(i, 0)
    softcut.level_input_cut(i, 1, 0.0)
    softcut.rec_level(i, 0)
    softcut.pre_level(i, 0)
  end

  if not util.file_exists(path) then
    os.execute("mkdir -p " .. path)
  end

  softcut.buffer_write_stereo(file, 0, rec_finish - rec_start)

  voice_states[voice] = "playing"

  clock.run(function()
    clock.sleep(1)
    params:set(voice .. "_sound_sample", file)
  end)
end

function clear_buffer()
  print("clear buffer " .. voice)

  if voice_states[voice] == "recording" then
    softcut.rec(1, 0)
    softcut.play(1, 0)
  end

  voice_states[voice] = "stopped"
  engine.clear(voice)
  params:set(voice .. "_sound_sample", "cancel")
end

function load_file()
  print("load file " .. voice)
  redraw_fs = true

  fileselect.enter(_path.audio, function(path)
    params:set(voice .. "_sound_sample", path)
    alt = false
    redraw_fs = false
    redraw()
  end)
end

function add_params(voice)
  params:add_separator("VOICE " .. voice)

  params:add{type = "file", id = voice .. "_sound_sample", name = voice .. " sample",
    action = function(file)
      if file ~= "cancel" then
        engine.read(voice, file)
        voice_states[voice] = "playing"
      end

      redraw()
    end
  }

  params:add{type = "control", id = voice .. "_sound_volume", name = voice .. " volume",
    controlspec = controlspec.DB,
    action = function(v)
      engine.volume(voice, v + params:get("gain_offset"))
      redraw()
    end
  }

  params:add{type = "taper", id = voice .. "_sound_stretch", name = voice .. " stretch",
    min=1, max=4000, default = 100, k = 25,
    action = function(v)
      engine.stretch(voice, v)
      redraw()
    end
  }

  params:add{type = "control", id = voice .. "_sound_harmonic_mix", name = voice .. " harmonic mix",
    controlspec = controlspec.UNIPOLAR,
    action = function(v)
      engine.pitchmix(voice, v)
      redraw()
    end
  }

  params:add{type = "number", id = voice .. "_sound_harmonic_oct", name = voice .. " harmonic oct",
    min = -3, max = 3, default = 1,
    action = function(v)
      engine.pitchharm(voice, musicutil.interval_to_ratio(12 * v))
      redraw()
    end
  }

  params:add{type = "control", id = voice .. "_pan_position", name = voice .. " pan position",
    controlspec = controlspec.PAN,
    action = function(v)
      engine.pan(voice, v)
      redraw()
    end
  }

  params:add{type = "taper", id = voice .. "_pan_lfo_rate", name = voice .. " pan rate",
    min=0.1, max=30, default = 10, k = -1, units = "s",
    action = function(v)
      engine.panrate(voice, 1/v)
      redraw()
    end
  }

  params:add{type = "control", id = voice .. "_pan_lfo_spread", name = voice .. " pan spread",
    controlspec = controlspec.UNIPOLAR,
    action = function(v)
      engine.pandepth(voice, v)
      redraw()
    end
  }

  params:add{type = "number", id = voice .. "_filter_width", name = voice .. " filter width",
    min = 1, max = 10, default = 10,
    action = function(v)
      engine.bpwidth(voice, v)
      redraw()
    end
  }

  params:add{type = "control", id = voice .. "_filter_freq", name = voice .. " filter freq",
    controlspec = controlspec.FREQ,
    action = function(v)
      engine.bpfreq(voice, v)
      redraw()
    end
  }
end
