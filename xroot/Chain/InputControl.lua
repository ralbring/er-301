local app = app
local Env = require "Env"
local Class = require "Base.Class"
local SpottedControl = require "SpottedStrip.Control"
local Utils = require "Utils"
local ply = app.SECTION_PLY

-- InputControl Class
local InputControl = Class {}
InputControl:include(SpottedControl)

function InputControl:init(index)
  SpottedControl.init(self)
  self:setClassName("InputControl")
  self:setInstanceName(index)
  self.inputIndex = index

  -- graphic
  local graphic = app.Graphic(0, 0, ply, 64)
  local scope = app.MiniScope(0, 0, ply, 64)
  scope:setForegroundColor(app.GRAY7)
  self.scope = scope
  graphic:addChild(self.scope)

  self.panel = app.TextPanel("", 1)
  graphic:addChild(self.panel)

  self:setControlGraphic(graphic)

  -- define spots
  self:addSpotDescriptor{
    center = 0.5 * ply,
    radius = ply
  }
  self.verticalDivider = 0

  -- sub display
  graphic = app.Graphic(0, 0, 128, 64)
  local label = app.Label("Set Chain Input", 12)
  label:setCenter(64, app.GRID5_LINE2)
  graphic:addChild(label)
  self.titleLabel = label
  label = app.SubButton("auto", 2)
  graphic:addChild(label)
  label = app.SubButton("clear", 3)
  graphic:addChild(label)
  self.menuGraphic = graphic
end

-- Return from a branch to its unit once an input has been chosen (US-15).
function InputControl:leaveBranch()
  local chain = self:getWindow()
  if chain and chain:getClassName() == "Chain.Branch" then chain:hide() end
end

function InputControl:spotReleased(i, shifted)
  if not shifted then
    local chain = self:getWindow()
    if chain then
      self:stopAuto()
      local SourceChooser = require "Source.Chooser"
      local chooser =
          SourceChooser(chain, chain:getInputSource(self.inputIndex))
      local task = function(src)
        chain:setInputSource(self.inputIndex, src)
        self:leaveBranch()
      end
      chooser:subscribe("choose", task)
      chooser:show()
    end
  end
end

function InputControl:contentChanged(chain)
  local scope = self.scope
  local source = chain:getInputSource(self.inputIndex)
  if source then
    scope:watchOutlet(source:getOutlet())
    if source.isUnipolar then
      scope:setOffset(-1)
    else
      scope:setOffset(0)
    end
    local channelName = source:getChannelName()
    local displayName = source:getDisplayName()
    if channelName then
      local text = string.format("%s (%s)", displayName, channelName)
      self:setText(text)
    else
      self:setText(displayName)
    end
  else
    self.scope:watchOutlet(nil)
    self.panel:setText("")
  end
end

function InputControl:setText(text)
  local graphic = self.panel
  local words = Utils.split(text, " ")
  graphic:clear()
  for _, word in ipairs(words) do graphic:addLine(Utils.shorten(word, 8, "..")) end
end

function InputControl:onCursorEnter()
  self:addSubGraphic(self.menuGraphic)
  self:grabFocus("subReleased")
end

function InputControl:onCursorLeave()
  self:stopAuto()
  self:removeSubGraphic(self.menuGraphic)
  self:releaseFocus("subReleased")
end

function InputControl:subReleased(i, shifted)
  if shifted then return end
  if i == 2 then
    if self.autoTimer then
      self:stopAuto()
    else
      self:startAuto()
    end
  elseif i == 3 then
    self:stopAuto()
    self:callUp("clearInputSource", self.inputIndex)
  end
  return true
end

-- "auto" (US-15): listen to the jacks and the built-in teletype ports, then
-- map whichever becomes active first.
local autoJacks = {
  "IN1", "IN2", "IN3", "IN4", "G1", "G2", "G3", "G4", "A1", "A2", "A3", "B1",
  "B2", "B3", "C1", "C2", "C3", "D1", "D2", "D3"
}
for port = 1, app.TeletypeTask.CVOutletCount do
  autoJacks[#autoJacks + 1] = "TCV" .. port
end
for port = 1, app.TeletypeTask.TROutletCount do
  autoJacks[#autoJacks + 1] = "TTR" .. port
end
-- Wait this long before taking the baseline, so the probes hold fresh data.
local autoSettleTime = 0.3
local autoPollPeriod = 0.05
-- Change from the baseline that counts as activity (1.0 = full scale).
local autoMeanThreshold = 0.02
local autoSpreadThreshold = 0.05

function InputControl:startAuto()
  local chain = self:getWindow()
  if chain == nil then return end
  local probes = {}
  for _, name in ipairs(autoJacks) do
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
  self.autoProbes = probes
  self.autoElapsed = 0
  self.autoBaseline = false
  self.titleLabel:setText("Listening...")
  local Timer = require "Timer"
  -- Timer.update may call this several times within one slow UI frame, even
  -- after stopAuto() cancelled it; returning false ends that loop.
  local handle
  handle = Timer.every(autoPollPeriod, function()
    if self.autoTimer ~= handle then return false end
    self:pollAuto()
    if self.autoTimer ~= handle then return false end
  end)
  self.autoTimer = handle
end

function InputControl:stopAuto()
  if self.autoTimer then
    local Timer = require "Timer"
    Timer.cancel(self.autoTimer)
    self.autoTimer = nil
  end
  if self.autoProbes then
    for _, entry in ipairs(self.autoProbes) do entry.probe:release() end
    self.autoProbes = nil
  end
  self.titleLabel:setText("Set Chain Input")
end

function InputControl:pollAuto()
  self.autoElapsed = self.autoElapsed + autoPollPeriod
  if self.autoElapsed < autoSettleTime then return end

  if not self.autoBaseline then
    for _, entry in ipairs(self.autoProbes) do
      entry.probe:update()
      entry.mean = entry.probe:mean()
      entry.spread = entry.probe:peakToPeak()
    end
    self.autoBaseline = true
    return
  end

  for _, entry in ipairs(self.autoProbes) do
    local probe = entry.probe
    probe:update()
    if math.abs(probe:mean() - entry.mean) > autoMeanThreshold or
        probe:peakToPeak() > 2 * entry.spread + autoSpreadThreshold then
      self:mapJack(entry.source)
      return
    end
  end
end

function InputControl:mapJack(source)
  self:stopAuto()
  local chain = self:getWindow()
  if chain == nil then return end
  chain:setInputSource(self.inputIndex, source)
  self:leaveBranch()
end

return InputControl
