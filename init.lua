local modHyper = {'⌘', '⌥', '⌃', '⇧'}

local homeSSID = 'woland'
local workSSID = 'timgroup_corp'

local talkDevice = 'Microsoft LifeChat LX-3000'
local musicDevice = 'ODAC'

local workScreenMiddle = 1007310081
local workScreenLeft = 1007310146
local screenInternal = 69732928

local laptopLayout = {
  {"OmniFocus", nil, hs.screen.find(screenInternal), hs.layout.maximized, nil, nil},
  {"Terminal", nil, hs.screen.find(screenInternal), hs.layout.maximized, nil, nil},
  {"Fastmail", nil, hs.screen.find(screenInternal), hs.layout.maximized, nil, nil},
}

hs.grid.setGrid('6x3')
hs.grid.setMargins('0x0')

-- Turn off animations, I don't like slow things
hs.window.animationDuration = 0

-- Util function to send notifications, with the standard boilerplate
function sendNotification(title, description)
  hs.notify.new({
    title=title,
    informativeText=description
  }):send()
end

-- Util function to print with timestamp
function printMessage(message)
  print(os.date('%x %X') .. ': ' .. message)
end

-- Reload configuration on changes
pathWatcher = hs.pathwatcher.new(hs.configdir, function(files)
  for _,file in pairs(files) do
    if file:sub(-4) == '.lua' then
      hs.reload()
    end
  end
end)
pathWatcher:start()

commsClosed = false
function closeComms()
  hs.execute('/usr/local/bin/tmux send-keys -t comms C-a d')
  commsClosed = true
  printMessage('Closed comms')
end

function openComms()
  if commsClosed then
    hs.execute('/usr/local/bin/tmux send-keys -t comms "tmux -2u attach -d" Enter')
    commsClosed = false
    printMessage('Opened comms')
  end
end

function pauseMusic()
  if hs.spotify.isRunning() and hs.spotify.isPlaying() then
    hs.spotify.pause()
  end
end

caffeinateWatcher = hs.caffeinate.watcher.new(function(event)
  -- Mute sounds on suspend, or if shutting down - to stop the startup chime
  if event == hs.caffeinate.watcher.systemWillSleep or event == hs.caffeinate.watcher.systemWillPowerOff then
    printMessage('Sleeping')
    hs.audiodevice.defaultOutputDevice():setVolume(0)
    closeComms()
    pauseMusic()
  end

  if event == hs.caffeinate.watcher.screensaverDidStart then
    printMessage('Screensaver Started')
    closeComms()
    pauseMusic()
  end

  if event == hs.caffeinate.watcher.systemDidWake or event == hs.caffeinate.watcher.screensaverDidStop then
    printMessage('Waking')
    openComms()
  end
end)
caffeinateWatcher:start()

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
  local app = hs.application.get(application)
  if app then
    app:kill()
  end
end

if caffeine then
  caffeine:setClickCallback(caffeineClicked)
  setCaffeineDisplay(hs.caffeinate.get('displayIdle'))
end

function wifiHandler()
  local currentSSID = hs.wifi.currentNetwork()

  -- Turn Caffeine off when leaving home network
  if currentSSID == homeSSID then
    hs.caffeinate.set('displayIdle', true)
  else
    hs.caffeinate.set('displayIdle', false)
  end

  -- Put the caffeine icon in the correct state, as we just modified it without clicking
  setCaffeineDisplay(hs.caffeinate.get('displayIdle'))
end
WifiWatcher = hs.wifi.watcher.new(wifiHandler)
WifiWatcher:start()

function batteryHandler()
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
end
batteryWatcher = hs.battery.watcher.new(batteryHandler)
batteryWatcher:start()

function usbHandler(data)
  if data['productName'] == 'ScanSnap S1100' then
    local event = data['eventType']

    if event == 'added' then
      hs.application.launchOrFocus('ScanSnap Manager')
    elseif event == 'removed' then
      hs.appfinder.appFromName('ScanSnap Manager'):kill()
    end
  end
end
usbWatcher = hs.usb.watcher.new(usbHandler)
usbWatcher:start()

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
screenWatcher = hs.screen.watcher.new(screenHandler)
screenWatcher:start()

function enterWork()
  printMessage('Entering work')
  hs.application.launchOrFocus('Nagios')
  hs.application.launchOrFocus('cieye')
  hs.application.launchOrFocus('Google Chrome')

  if hs.battery.isCharging() then
    hs.brightness.set(100)
  end
end

function leaveWork()
  printMessage('Leaving work')
  killIfApplicationRunning('Nagios')
  killIfApplicationRunning('cieye')
--  killIfApplicationRunning('Google Chrome')
  killIfApplicationRunning('Mumble')
  killIfApplicationRunning('Microsoft Remote Desktop')
  hs.layout.apply(laptopLayout)
end

-- Configure audio output device, unless it doesn't exist - then notify
function setAudioOutput(device)
  local hardwareDevice = hs.audiodevice.findOutputByName(device)
  local currentDevice = hs.audiodevice.defaultOutputDevice()

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
local function toggleAudio()
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
  local wifiIsPowered = hs.wifi.interfaceDetails('en0')['power']
  if wifiIsPowered then
    hs.wifi.setPower(false)
    sendNotification('Wifi On', 'Wifi is now off')
  else
    hs.wifi.setPower(true)
    sendNotification('Wifi Off', 'Wifi is now on')
  end
  local wifiIsPowered = nil
end

-- Misc bindings
hs.hotkey.bind(modHyper, '-', function() toggleWifi() end)
hs.hotkey.bind(modHyper, '1', function() openMusicApplication('Spotify') end)
hs.hotkey.bind(modHyper, '2', function() openMusicApplication('Vox') end)
hs.hotkey.bind(modHyper, 'a', function() hs.application.launchOrFocus('Google Chrome Canary') end)
hs.hotkey.bind(modHyper, 'c', function() hs.application.launchOrFocus('Google Chrome') end)
hs.hotkey.bind(modHyper, 'd', function() hs.application.launchOrFocus('Dash') end)
hs.hotkey.bind(modHyper, 'f', function() hs.application.launchOrFocus('Fastmail') end)
hs.hotkey.bind(modHyper, 'h', function() hs.toggleConsole() end)
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
hs.layout.apply(laptopLayout)
sendNotification('Hammerspoon', 'Config reloaded')
