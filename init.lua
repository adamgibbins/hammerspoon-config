local modHyper = {'⌘', '⌥', '⌃', '⇧'}

local homeSSID = 'woland'
local workSSID = 'timgroup_corp'

local talkDevice = 'Microsoft LifeChat LX-3000'
local musicDevice = 'ODAC'

local workScreenMiddle = 1007310081
local workScreenLeft = 1007310146
local workScreenInternal = 69732928

hs.grid.setGrid('6x3')
hs.grid.setMargins('0x0')
-- No clue to what this actually is, but I don't like slow things - so turn it off
hs.window.animationDuration = 0

-- Util function to send notifications, with the standard boilerplate
function sendNotification(title, description)
  hs.notify.new({
    title=title,
    informativeText=description
  }):send()
end

-- Reload configuration on changes
hs.pathwatcher.new(hs.configdir, function(files)
  for _,file in pairs(files) do
    if file:sub(-4) == '.lua' then
      hs.reload()
    end
  end
end):start()

hs.caffeinate.watcher.new(function(event)
  -- Mute sounds on suspend, or if shutting down - to stop the startup chime
  if event == hs.caffeinate.watcher.systemWillSleep or event == hs.caffeinate.watcher.systemWillPowerOff or event == hs.caffeinate.watcher.systemDidWake then
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

function killIfApplicationRunning(application)
  app = hs.application.get(application)
  if app then
    app:kill()
  end
end

if caffeine then
  caffeine:setClickCallback(caffeineClicked)
  setCaffeineDisplay(hs.caffeinate.get('displayIdle'))
end

function wifiHandler()
  currentSSID = hs.wifi.currentNetwork()

  -- Turn Caffeine off when leaving home network
  if currentSSID == homeSSID then
    hs.caffeinate.set('displayIdle', true)
  else
    hs.caffeinate.set('displayIdle', false)
  end

  -- Put the caffeine icon in the correct state, as we just modified it without clicking
  setCaffeineDisplay(hs.caffeinate.get('displayIdle'))
end
hs.wifi.watcher.new(wifiHandler):start()

function batteryHandler()
  -- Notify on power source state changes
  powerSource = hs.battery.powerSource()

  if powerSource ~= powerSourcePrevious then
    sendNotification('Power Source', powerSource)
    powerSourcePrevious = powerSource
  end

  -- Notify when battery is low
  batteryPercentage = tonumber(hs.battery.percentage())

  if batteryPercentage ~= batteryPercentagePrevious and not hs.battery.isCharging() and batteryPercentage < 15 then
    sendNotification('Battery Status', batteryPercentage .. '% battery remaining!')
    batteryPercentagePrevious = batteryPercentage
  end
end
hs.battery.watcher.new(batteryHandler):start()

function usbHandler(data)
  if data['productName'] == 'ScanSnap S1100' then
    event = data['eventType']

    if event == 'added' then
      hs.application.launchOrFocus('ScanSnap Manager')
    elseif event == 'removed' then
      hs.appfinder.appFromName('ScanSnap Manager'):kill()
    end
  end
end
hs.usb.watcher.new(usbHandler):start()

atWork = nil
function screenHandler()
  if hs.screen.find(workScreenMiddle) and hs.screen.find(workScreenLeft) then
    atWork = true
    enterWork()
  elseif atWork and hs.screen.find(workScreenMiddle) == nil and hs.screen.find(workScreenLeft) == nil then
    atWork = false
    leaveWork()
  end
end
hs.screen.watcher.new(screenHandler):start()

function enterWork()
  hs.application.launchOrFocus('Nagios')
  hs.application.launchOrFocus('cieye')
  hs.application.launchOrFocus('Google Chrome')

  if hs.battery.isCharging() then
    hs.brightness.set(100)
  end
end

function leaveWork()
  killIfApplicationRunning('Nagios')
  killIfApplicationRunning('cieye')
  killIfApplicationRunning('Google Chrome')
  killIfApplicationRunning('Mumble')
  killIfApplicationRunning('Microsoft Remote Desktop')
end

-- Configure audio output device, unless it doesn't exist - then notify
function setAudioOutput(device)
  hardwareDevice = hs.audiodevice.findOutputByName(device)
  currentDevice = hs.audiodevice.defaultOutputDevice()

  if hardwareDevice then
    if currentDevice ~= hardwareDevice then
      hardwareDevice:setDefaultOutputDevice()
      sendNotification('Audio Output', 'Switched to ' .. device)

      -- talkDevice is replugged often, when plugged in it starts on mute - so turn it up to a reasonable volume
      if device == talkDevice then
        hardwareDevice:setVolume(40)
      end
    end
  else
    sendNotification('Audio Alert', device .. ' is missing!')
  end
end

-- Toggle between the two audio devices
function toggleAudio()
  currentDevice = hs.audiodevice.defaultOutputDevice()

  if currentDevice:name() == talkDevice then
    setAudioOutput(musicDevice)
  else
    setAudioOutput(talkDevice)
  end
end

function openMusicApplication(name)
  setAudioOutput(musicDevice)
  hs.application.launchOrFocus(name)
end

function toggleWifi()
  wifiIsActive = hs.execute('/sbin/ifconfig | /usr/local/bin/pcregrep -M -o "^[^\t:]+:([^\n]|\n\t)*status: active" | /usr/bin/grep "^en0:"')
  if wifiIsActive == '' then
    hs.execute('networksetup -setairportpower en0 on')
    sendNotification('Wifi On', 'Wifi is now on')
  else
    hs.execute('networksetup -setairportpower en0 off')
    sendNotification('Wifi Off', 'Wifi is now off')
  end
  wifiIsActive = nil
end

-- Misc bindings
hs.hotkey.bind(modHyper, '-', function() toggleWifi() end)
hs.hotkey.bind(modHyper, '1', function() openMusicApplication('Spotify') end)
hs.hotkey.bind(modHyper, '2', function() openMusicApplication('Vox') end)
hs.hotkey.bind(modHyper, 'a', function() hs.application.launchOrFocus('Google Chrome Canary') end)
hs.hotkey.bind(modHyper, 'c', function() hs.application.launchOrFocus('Google Chrome') end)
hs.hotkey.bind(modHyper, 'd', function() hs.application.launchOrFocus('Dash') end)
hs.hotkey.bind(modHyper, 'f', function() hs.application.launchOrFocus('Fastmail') end)
hs.hotkey.bind(modHyper, 'h', function() os.execute('open ~') end)
hs.hotkey.bind(modHyper, 'i', function() hs.application.launchOrFocus('IntelliJ IDEA 14') end)
hs.hotkey.bind(modHyper, 'r', function()
  os.execute('open -a /Applications/Microsoft\\ Remote\\ Desktop.app/Contents/MacOS/Microsoft\\ Remote\\ Desktop ~/doc/misc/rds.rdp')
end)
hs.hotkey.bind(modHyper, 'm', function()
  setAudioOutput(talkDevice)
  hs.application.launchOrFocus('Mumble')
end)
hs.hotkey.bind(modHyper, 'n', function() hs.application.launchOrFocus('nvAlt') end)
hs.hotkey.bind(modHyper, 'o', function() hs.application.launchOrFocus('OmniFocus') end)
hs.hotkey.bind(modHyper, 'p', function() hs.spotify.displayCurrentTrack() end)
hs.hotkey.bind(modHyper, 'q', function() toggleAudio() end)
hs.hotkey.bind(modHyper, 's', function() hs.application.launchOrFocus('Slack') end)
hs.hotkey.bind(modHyper, 'w', function() hs.appfinder.windowFromWindowTitlePattern('^project_.*'):focus() end)
hs.hotkey.bind(modHyper, 'x', function() hs.grid.show() end)
hs.hotkey.bind(modHyper, 'z', function() hs.appfinder.windowFromWindowTitle('comms'):focus() end)
hs.hotkey.bind(modHyper, 'space', function() hs.timer.doAfter(1, function() hs.caffeinate.startScreensaver() end) end)

-- We just booted - call all the handlers to get things in a sane state
batteryHandler()
wifiHandler()
screenHandler()
sendNotification('Hammerspoon', 'Config reloaded')
