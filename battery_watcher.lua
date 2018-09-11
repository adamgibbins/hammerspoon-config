function batteryHandler()
  -- Notify on power source state changes
  local powerSource = hs.battery.powerSource()

  if powerSource ~= powerSourcePrevious and powerSourcePrevious ~= nil then
    notify('Power Source', powerSource)
    powerSourcePrevious = powerSource
  end

  -- Notify when battery is low
  local batteryPercentage = tonumber(hs.battery.percentage())

  if batteryPercentage ~= batteryPercentagePrevious and not hs.battery.isCharging() and batteryPercentage < 8 then
    notify('Battery Status', batteryPercentage .. '% battery remaining!')
    batteryPercentagePrevious = batteryPercentage
  end
end
batteryWatcher = hs.battery.watcher.new(batteryHandler):start()
