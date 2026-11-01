local app = app

app.logInfo("Setup app module.")
app.AudioThread.init()
app.UIThread.init()

-- enable/disable gc calls in the code
function app.collectgarbage()
  -- app.logInfo("Collecting garbage...")
  collectgarbage()
  -- app.logInfo("Garbage collection finished.")
end

function app.luaMemoryUsage()
  return collectgarbage("count")
end

-- Buttons

function app.getButtonCenter(n)
  return (n - 1) * 43 + 20
end

function app.MainButton(text, pos, opaque)
  local button = app.SoftButton(text, pos)
  button:setOpaque(opaque or false)
  return button
end

function app.SubButton(text, pos, opaque)
  local button = app.SoftButton(text, pos)
  button:setOpaque(opaque or false)
  return button
end

function app.addButtons(graphic, ...)
  local texts = {
    ...
  }
  for i, text in ipairs(texts) do
    local button = app.SoftButton(text, i)
    graphic:addChild(button)
  end
end

function app.FittedTextBox(text, justify, shrink)
  local graphic = app.RichTextBox(text, 10)
  local ply = app.SECTION_PLY
  shrink = shrink or 2
  justify = justify or app.justifyCenter
  if graphic:flowText(ply - shrink, 2) then
    graphic:fitHeight(ply - shrink)
  elseif graphic:flowText(2 * ply - shrink, 2) then
    graphic:fitHeight(2 * ply - shrink)
  else
    graphic:fitHeight(3 * ply - shrink)
  end
  graphic:setJustification(justify)
  graphic:setBorder(1)
  graphic:setBorderColor(app.GRAY7)
  graphic:setCornerRadius(3, 3, 3, 3)
  return graphic
end

local externalSources = {}

-- Built-in teletype i2c receiver (US-15); one instance, never released.
local teletypeTask = app.TeletypeTask()
function app.getTeletypeTask()
  return teletypeTask
end

-- Ordered groups {title, sources} of the teletype i2c sources (US-15).
local i2cSourceGroups = {}

-- Empty while teletype i2c is disabled in Admin > Settings (and without the
-- MIDI groups while MIDI via i2c is disabled), so those sources are neither
-- offered in the chooser nor watched by auto-detect. Saved assignments still
-- resolve through app.getExternalSource().
function app.getI2cSourceGroups()
  local Settings = require "Settings"
  if Settings.get("teletypeEnable") ~= "yes" then return {} end
  if Settings.get("teletypeMidi") == "yes" then return i2cSourceGroups end
  local groups = {}
  for _, g in ipairs(i2cSourceGroups) do
    if not g.isMidi then groups[#groups + 1] = g end
  end
  return groups
end

local externalDestinations = {}

do
  local inputTask = app.AudioThread.getInputTask()
  local outputTask = app.AudioThread.getOutputTask()
  local Source = require "Source.External"

  externalSources["A1"] = Source("A1", inputTask.mA1)
  externalSources["A2"] = Source("A2", inputTask.mA2)
  externalSources["A3"] = Source("A3", inputTask.mA3)

  externalSources["B1"] = Source("B1", inputTask.mB1)
  externalSources["B2"] = Source("B2", inputTask.mB2)
  externalSources["B3"] = Source("B3", inputTask.mB3)

  externalSources["C1"] = Source("C1", inputTask.mC1)
  externalSources["C2"] = Source("C2", inputTask.mC2)
  externalSources["C3"] = Source("C3", inputTask.mC3)

  externalSources["D1"] = Source("D1", inputTask.mD1)
  externalSources["D2"] = Source("D2", inputTask.mD2)
  externalSources["D3"] = Source("D3", inputTask.mD3)

  externalSources["G1"] = Source("G1", inputTask.mG1, true)
  externalSources["G2"] = Source("G2", inputTask.mG2, true)
  externalSources["G3"] = Source("G3", inputTask.mG3, true)
  externalSources["G4"] = Source("G4", inputTask.mG4, true)

  externalSources["IN1"] = Source("IN1", inputTask.mIN1)
  externalSources["IN2"] = Source("IN2", inputTask.mIN2)
  externalSources["IN3"] = Source("IN3", inputTask.mIN3)
  externalSources["IN4"] = Source("IN4", inputTask.mIN4)

  externalSources["OUT1"] = Source("OUT1", outputTask.mMonitor1)
  externalSources["OUT2"] = Source("OUT2", outputTask.mMonitor2)
  externalSources["OUT3"] = Source("OUT3", outputTask.mMonitor3)
  externalSources["OUT4"] = Source("OUT4", outputTask.mMonitor4)

  -- Built-in teletype i2c ports (US-15), laid out for the Sweet Sixteen
  -- (16n firmware): faders, GESS gates and its MIDI-to-i2c conversion.
  -- Values sent over i2c are never negative, so all sources are unipolar.
  local teletypeTask = app.getTeletypeTask()
  local function group(title, isMidi)
    local g = {
      title = title,
      isMidi = isMidi,
      sources = {}
    }
    i2cSourceGroups[#i2cSourceGroups + 1] = g
    return g
  end
  local function addSource(g, kind, port, name)
    local outlet
    if kind == "CV" then
      outlet = teletypeTask:getCVOutlet(port)
    else
      outlet = teletypeTask:getTROutlet(port)
    end
    local source = Source(name, outlet, true)
    externalSources[name] = source
    g.sources[#g.sources + 1] = source
  end
  -- Adds sources <prefix><firstNumber><suffix>... for count consecutive
  -- ports.
  local function add(g, kind, firstPort, count, prefix, firstNumber, suffix)
    for i = 0, count - 1 do
      local name = prefix .. (firstNumber + i) .. (suffix or "")
      addSource(g, kind, firstPort + i, name)
    end
  end
  add(group("TT CV"), "CV", 1, 16, "TCV", 1)
  add(group("TT TR"), "TR", 1, 8, "TTR", 1)
  -- MIDI channels 1-8 (pitch: note number 21 = 0V, 1V/oct)
  add(group("MIDI P", true), "CV", 21, 8, "MP", 1)
  add(group("MIDI V", true), "CV", 31, 8, "MV", 1)
  add(group("MIDI G", true), "TR", 21, 8, "MG", 1)
  local cc = group("MIDI CC", true)
  add(cc, "CV", 41, 8, "CC", 1, "/33") -- CC1/33 = CC 33 on channel 1
  add(cc, "CV", 51, 8, "CC", 1, "/34")
  -- MIDI channel 10 (drums), notes 36-51, named by note (36 = C3); the prefix keeps them apart from jacks A1-D3.
  local noteNames = {
    "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
  }
  local drumTriggers = group("DRUM T", true)
  local drumVelocities = group("DRUM V", true)
  for note = 36, 51 do
    local noteName = noteNames[note % 12 + 1] .. (note // 12)
    local port = note + 25
    addSource(drumTriggers, "TR", port, "DT-" .. noteName)
    addSource(drumVelocities, "CV", port, "DV-" .. noteName)
  end

  externalDestinations["OUT1"] = outputTask.mOut1
  externalDestinations["OUT2"] = outputTask.mOut2
  externalDestinations["OUT3"] = outputTask.mOut3
  externalDestinations["OUT4"] = outputTask.mOut4
end

function app.getExternalSource(name)
  return externalSources[name]
end

function app.getExternalDestination(name)
  return externalDestinations[name]
end

function app.getModeToggleState()
  if app.Gpio_read(app.TOGGLE_MODE_A) then
    return "hold"
  elseif app.Gpio_read(app.TOGGLE_MODE_B) then
    return "scope"
  else
    return "edit"
  end
end

function app.getStorageToggleState()
  if app.Gpio_read(app.TOGGLE_STORAGE_A) then
    return "user"
  elseif app.Gpio_read(app.TOGGLE_STORAGE_B) then
    return "eject"
  else
    return "admin"
  end
end

function app.isCancelButtonPushed()
  if app.Gpio_read(app.BUTTON_DIAL2) then
    return false
  else
    return true
  end
end

function app.isShiftButtonPushed()
  if app.Gpio_read(app.BUTTON_SHIFT) then
    return false
  else
    return true
  end
end

