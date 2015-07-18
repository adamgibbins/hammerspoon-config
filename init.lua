local modHyper = {'⌘', '⌥', '⌃', '⇧'}

function reloadConfig(files)
  for _,file in pairs(files) do
    if file:sub(-4) == '.lua' then
      hs.reload()
    end
  end
end

hs.pathwatcher.new(hs.configdir, reloadConfig):start()

hs.caffeinate.watcher.new(function()
  if hs.caffeinate.watcher.systemWillSleep then
    hs.audiodevice.defaultOutputDevice():setVolume(0)
  end
end):start()

hs.hotkey.bind(modHyper, 'c', function() hs.application.launchOrFocus('Google Chrome') end)
hs.hotkey.bind(modHyper, 'i', function() hs.application.launchOrFocus('iTerm') end)
hs.hotkey.bind(modHyper, 'm', function() hs.application.launchOrFocus('Mumble') end)
hs.hotkey.bind(modHyper, 'n', function() hs.application.launchOrFocus('nvAlt') end)
hs.hotkey.bind(modHyper, 'o', function() hs.application.launchOrFocus('OmniFocus') end)
hs.hotkey.bind(modHyper, 's', function() hs.application.launchOrFocus('Spotify') end)
hs.hotkey.bind(modHyper, 'v', function() hs.application.launchOrFocus('Vox') end)
hs.hotkey.bind(modHyper, 'd', function() hs.application.launchOrFocus('Dash') end)

hs.battery.watcher.new(function()
  batteryPercentage = hs.battery.percentage()

  if batteryPercentage ~= batteryPreviousPercentage and batteryPercentage < 20 and not hs.battery.isCharging() then
    hs.notify.new({
      title='Battery Status',
      informativeText='Battery needs charge!'
    })
  end

  batteryPreviousPercentage = batteryPercentage
end):start()

hs.notify.new({
  title='Hammerspoon',
  informativeText='Config reloaded'
}):send()
