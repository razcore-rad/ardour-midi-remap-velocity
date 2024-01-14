ardour {
  ["type"]    = "dsp",
  name        = "MIDI Remap Velocity",
  category    = "Utility",
  license     = "MIT",
  author      = "Răzvan Cosmin Rădulescu / razcore-rad",
  description = [[MIDI filter remapping velocity linearly.]]
}

function dsp_ioconfig()
  return { { midi_in = 1, midi_out = 1, audio_in = 0, audio_out = 0 }, }
end

function dsp_params()
  return {
    { ["type"] = "input", name = "Input MIN Velocity", min = 1, max = 127, default = 1, integer = true },
    { ["type"] = "input", name = "Input MAX Velocity", min = 1, max = 127, default = 127, integer = true },
    { ["type"] = "input", name = "Output MIN Velocity", min = 1, max = 127, default = 1, integer = true },
    { ["type"] = "input", name = "Output MAX Velocity", min = 1, max = 127, default = 127, integer = true },
  }
end

function dsp_run(_, _, n_samples)
  local ctrl = CtrlPorts:array()
  local input_min_velocity = ctrl[1]
  local input_max_velocity = ctrl[2]
  local output_min_velocity = ctrl[3]
  local output_max_velocity = ctrl[4]

  function tx_midi(idx, time, data)
    midiout[idx] = {}
    midiout[idx]["time"] = time;
    midiout[idx]["data"] = data;
  end

  function map_velocity(velocity)
    local t = (velocity - input_min_velocity) / (input_max_velocity - input_min_velocity)
    local clamped_velocity = math.min(127, math.max(output_min_velocity * (1 - t) + output_max_velocity * t, 1))
    return math.floor(clamped_velocity)
  end

  -- for each incoming midi event
  for idx, b in pairs(midiin) do
    local time = b["time"] -- t = [ 1 .. n_samples ]
    local data = b["data"] -- get midi-event bytes
    local event_type
    if #data == 0 then event_type = -1 else event_type = data[1] >> 4 end
    if (#data == 3 and event_type == 9) then data[3] = map_velocity(data[3]) end
    tx_midi(idx, time, data)
  end
end
