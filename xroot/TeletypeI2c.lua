-- Built-in teletype i2c receiver (local patch, US-15), formerly the teletype
-- mod. Enabled and addressed through Admin > Settings > Teletype.
local app = app
local Settings = require "Settings"

-- In developer mode on testing builds the UART console uses the i2c pins.
local function uartInUse()
  return app.TESTING and Settings.get("enableDevMode")
end

local function refresh()
  local task = app.getTeletypeTask()
  if task:isEnabled() then
    task:disable()
    if uartInUse() then app.Uart_enable() end
    app.logInfo("Teletype: i2c disabled.")
  end
  if Settings.get("teletypeEnable") == "yes" and not uartInUse() then
    local address = Settings.get("teletypeAddress")
    task:enable(tonumber(address))
    app.logInfo("Teletype: i2c enabled (address=%s).", address)
  end
end

return {
  refresh = refresh
}
