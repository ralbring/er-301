local app = app
local Class = require "Base.Class"
local SpottedControl = require "SpottedStrip.Control"
local ply = app.SECTION_PLY

local CollapsedHeader = Class {}
CollapsedHeader:include(SpottedControl)

function CollapsedHeader:init(title, sources)
  SpottedControl.init(self)
  self:setClassName("Source.ExternalChooser.CollapsedHeader")
  local graphic = app.Graphic(0, 0, ply, 64)
  local label = app.Label(title, 10)
  label:fitToText(0)
  label:setPosition(5, 55)
  graphic:addChild(label)

  local n = #sources
  local width = 6
  local gap = 2
  -- Large groups (the teletype ports) get rows of at most 8 narrower meters
  -- so they stay within the section (local patch, US-15).
  local columns = math.min(n, 8)
  local rows = (n + columns - 1) // columns
  local pitch = (ply - 2) // math.max(columns, 1)
  if pitch < width + gap then
    gap = 1
    width = math.max(pitch - gap, 1)
  end
  local rowGap = 3
  local height = (44 - (rows - 1) * rowGap) // rows
  local offset = ply // 2 - (columns * (width + gap)) // 2

  for i, source in ipairs(sources) do
    local column = (i - 1) % columns
    local row = (i - 1) // columns
    local bottom = 8 + (rows - 1 - row) * (height + rowGap)
    local meter = app.VerticalMeter(column * (width + gap) + offset, bottom,
                                    width, height)
    meter:watchOutlet(source:getOutlet())
    graphic:addChild(meter)
  end

  self:setControlGraphic(graphic)
  self:addSpotDescriptor{
    center = 0.5 * ply
  }
end

function CollapsedHeader:spotReleased()
  self:callUp("expand")
  self:callUp("leftJustify")
  return true
end

function CollapsedHeader:enterReleased()
  self:callUp("expand")
  self:callUp("leftJustify")
  return true
end

return CollapsedHeader
