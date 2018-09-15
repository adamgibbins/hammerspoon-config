local powerSource = hs.battery.powerSource()

function batteryHandler()
  local newPowerSource = hs.battery.powerSource()

  if newPowerSource ~= powerSource then
    notify('Power Source', newPowerSource)
    powerSource = newPowerSource
  end

  if hs.battery.percentage() < 100 then
    isCharged = false
  end

  if hs.battery.isCharged() ~= isCharged
    and hs.battery.percentage() == 100
    and newPowerSource == 'AC Power' then
    notify('Battery', 'Fully charged!', 5)
    isCharged = true
  end

  -- Notify when battery is low
  local batteryPercentage = tonumber(hs.battery.percentage())

  if batteryPercentage ~= batteryPercentagePrevious and not hs.battery.isCharging() and batteryPercentage < 8 then
    notify('Battery Status', batteryPercentage .. '% battery remaining!')
    batteryPercentagePrevious = batteryPercentage
  end
end
batteryWatcher = hs.battery.watcher.new(batteryHandler):start()
