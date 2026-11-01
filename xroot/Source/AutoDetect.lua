-- Listens to the external sources (jacks and built-in teletype ports) and
-- reports the first one whose signal changes (local patch, US-15).
local app = app
local Class = require "Base.Class"
local Timer = require "Timer"

local sourceNames = {
  "IN1", "IN2", "IN3", "IN4", "G1", "G2", "G3", "G4", "A1", "A2", "A3", "B1",
  "B2", "B3", "C1", "C2", "C3", "D1", "D2", "D3"
}
for port = 1, app.TeletypeTask.CVOutletCount do
  sourceNames[#sourceNames + 1] = "TCV" .. port
end
for port = 1, app.TeletypeTask.TROutletCount do
  sourceNames[#sourceNames + 1] = "TTR" .. port
end

-- Wait this long before taking the baseline, so the probes hold fresh data.
local settleTime = 0.3
local pollPeriod = 0.05
-- Change from the baseline that counts as activity (1.0 = full scale).
local meanThreshold = 0.02
local spreadThreshold = 0.05

local AutoDetect = Class {}

-- onFound(source) is called once, after detection has stopped.
function AutoDetect:init(onFound)
  self.onFound = onFound
end

function AutoDetect:isActive()
  return self.timer ~= nil
end

function AutoDetect:start()
  self:stop()
  local probes = {}
  for _, name in ipairs(sourceNames) do
    local source = app.getExternalSource(name)
    if source then
      local probe = app.OutletProbe()
      probe:watch(source:getOutlet())
      probes[#probes + 1] = {
        source = source,
        probe = probe
      }
    end
  end
  self.probes = probes
  self.elapsed = 0
  self.baseline = false
  -- Timer.update may call this several times within one slow UI frame, even
  -- after stop() cancelled it; returning false ends that loop.
  local handle
  handle = Timer.every(pollPeriod, function()
    if self.timer ~= handle then return false end
    self:poll()
    if self.timer ~= handle then return false end
  end)
  self.timer = handle
end

function AutoDetect:stop()
  if self.timer then
    Timer.cancel(self.timer)
    self.timer = nil
  end
  if self.probes then
    for _, entry in ipairs(self.probes) do entry.probe:release() end
    self.probes = nil
  end
end

function AutoDetect:poll()
  self.elapsed = self.elapsed + pollPeriod
  if self.elapsed < settleTime then return end

  if not self.baseline then
    for _, entry in ipairs(self.probes) do
      entry.probe:update()
      entry.mean = entry.probe:mean()
      entry.spread = entry.probe:peakToPeak()
    end
    self.baseline = true
    return
  end

  for _, entry in ipairs(self.probes) do
    local probe = entry.probe
    probe:update()
    if math.abs(probe:mean() - entry.mean) > meanThreshold or
        probe:peakToPeak() > 2 * entry.spread + spreadThreshold then
      local source = entry.source
      self:stop()
      self.onFound(source)
      return
    end
  end
end

return AutoDetect
