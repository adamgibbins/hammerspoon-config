function batteryHandler()
  printMessage('batteryHandler triggered')
  -- Notify on power source state changes
  local powerSource = hs.battery.powerSource()

  if powerSource ~= powerSourcePrevious and powerSourcePrevious ~= nil then
    sendNotification('Power Source', powerSource)
    powerSourcePrevious = powerSource
  end

  -- Notify when battery is low
  local batteryPercentage = tonumber(hs.battery.percentage())

  if batteryPercentage ~= batteryPercentagePrevious and not hs.battery.isCharging() and batteryPercentage < 15 then
    sendNotification('Battery Status', batteryPercentage .. '% battery remaining!')
    batteryPercentagePrevious = batteryPercentage
  end

  if hs.battery.psuSerial() == workPSU then
    atWork = true
    enterWork()
  elseif atWork then
    atWork = false
    leaveWork()
  end
end
batteryWatcher = hs.battery.watcher.new(batteryHandler):start()
