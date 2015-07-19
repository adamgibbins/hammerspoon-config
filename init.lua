local modHyper = {'⌘', '⌥', '⌃', '⇧'}
local homeSSID = 'woland'

-- Reload configuration on changes
hs.pathwatcher.new(hs.configdir, function(files)
  for _,file in pairs(files) do
    if file:sub(-4) == '.lua' then
      hs.reload()
    end
  end
end):start()

hs.notify.new({
  title='Hammerspoon',
  informativeText='Config reloaded'
}):send()

-- Mute sounds on suspend
hs.caffeinate.watcher.new(function()
  if hs.caffeinate.watcher.systemWillSleep then
    hs.audiodevice.defaultOutputDevice():setVolume(0)
  end
end):start()

-- Replicate Caffeine.app - click to toggle auto sleep
local caffeine = hs.menubar.new()

function setCaffeineDisplay(state)
  -- Icons originally from https://github.com/cmsj/hammerspoon-config
  local result
  if state then
    result = caffeine:setIcon('caffeine-on.pdf')
  else
    result = caffeine:setIcon('caffeine-off.pdf')
  end
end

function caffeineClicked()
  setCaffeineDisplay(hs.caffeinate.toggle('displayIdle'))
end

if caffeine then
  caffeine:setClickCallback(caffeineClicked)
  setCaffeineDisplay(hs.caffeinate.get('displayIdle'))
end

-- Turn Caffeine off when leaving home network
hs.wifi.watcher.new(function()
  if hs.wifi.currentNetwork() == homeSSID then
    hs.caffeinate.set('displayIdle', true)
  else
    hs.caffeinate.set('displayIdle', false)
  end

  setCaffeineDisplay(hs.caffeinate.get('displayIdle'))
end):start()

powerSourcePrevious = nil
batteryPercentagePrevious = nil

hs.battery.watcher.new(function()
  -- Notify on power source state changes
  powerSource = hs.battery.powerSource()

  if powerSource ~= powerSourcePrevious then
    hs.notify.new({
      title = 'Power Source',
      informativeText = powerSource
    }):send()

    powerSourcePrevious = powerSource
  end

  -- Notify when battery is low
  batteryPercentage = hs.battery.percentage()

  if batteryPercentage ~= batteryPercentagePrevious and not hs.battery.isCharging() and batteryPercentage < 15 then
    hs.notify.new({
      title = 'Battery Status',
      informativeText = string.format('%d%% battery remaining!', batteryPercentage),
    }):send()

    batteryPercentagePrevious = batteryPercentage
  end
end):start()

-- Misc bindings
hs.hotkey.bind(modHyper, '1', function() hs.application.launchOrFocus('Spotify') end)
hs.hotkey.bind(modHyper, '2', function() hs.application.launchOrFocus('Vox') end)
hs.hotkey.bind(modHyper, 'a', function() hs.application.launchOrFocus('Safari') end)
hs.hotkey.bind(modHyper, 'c', function() hs.application.launchOrFocus('Google Chrome') end)
hs.hotkey.bind(modHyper, 'd', function() hs.application.launchOrFocus('Dash') end)
hs.hotkey.bind(modHyper, 'h', function() os.execute('open ~') end)
hs.hotkey.bind(modHyper, 'i', function() hs.application.launchOrFocus('iTerm') end)
hs.hotkey.bind(modHyper, 'm', function() hs.application.launchOrFocus('Mumble') end)
hs.hotkey.bind(modHyper, 'n', function() hs.application.launchOrFocus('nvAlt') end)
hs.hotkey.bind(modHyper, 'o', function() hs.application.launchOrFocus('OmniFocus') end)
hs.hotkey.bind(modHyper, 's', function() hs.application.launchOrFocus('Slack') end)
hs.hotkey.bind(modHyper, 'space', function() hs.caffeinate.startScreensaver() end)
