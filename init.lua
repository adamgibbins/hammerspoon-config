local modHyper = {'cmd', 'alt', 'ctrl', 'shift'}
local altCmd = {'alt', 'cmd'}

homeSSID = 'woland'

workPSU = 12735159

local talkDevice = 'Microsoft LifeChat LX-3000'
local musicDevice = 'ODAC'

local workScreenMiddle = 1007310081
local workScreenLeft = 1007310146
local screenInternal = 69732928

local laptopLayout = {
  { 'OmniFocus',        nil,          hs.screen.find(screenInternal), hs.layout.maximized,    nil, nil },
  { 'Terminal',         nil,          hs.screen.find(screenInternal), hs.layout.maximized,    nil, nil },
  { 'Terminal',         'comms',      hs.screen.find(screenInternal), hs.layout.left75,       nil, nil },
  { 'Fastmail',         nil,          hs.screen.find(screenInternal), hs.layout.maximized,    nil, nil },
  { 'Tweetbot',         nil,          hs.screen.find(screenInternal), hs.layout.left50,       nil, nil },
  { 'Google Chrome',    nil,          hs.screen.find(screenInternal), hs.layout.right75,      nil, nil },
  { 'Dash',             nil,          hs.screen.find(screenInternal), hs.layout.maximized,    nil, nil },
}

hs.layout.apply(laptopLayout)

hs.grid.setGrid('6x3')
hs.grid.setMargins('0x0')

-- Turn off animations, I don't like slow things
hs.window.animationDuration = 0

-- Make HS accessible from the command line
hs.ipc.cliInstall()

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

-- Toggle between an app and the previously focused window
function toggleApp(app)
  if hs.window.focusedWindow() and hs.window.focusedWindow():application():title() == app and previousFocus then
    previousFocus:focus()
  else
    previousFocus = hs.window.focusedWindow()
    hs.application.launchOrFocus(app)
  end
end

function killIfApplicationRunning(application)
  local app = hs.application.get(application)
  if app then
    app:kill()
  end
end

function enterWork()
  printMessage('Entering work')
  hs.application.launchOrFocus('Nagios')
  hs.application.launchOrFocus('cieye')
  hs.application.launchOrFocus('Google Chrome')
  -- hs.layout.apply(workLayout)

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
  toggleApp(name)
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
hs.hotkey.bind(modHyper, 'a', function() toggleApp('Google Chrome Canary') end)
hs.hotkey.bind(modHyper, 'c', function() toggleApp('Google Chrome') end)
hs.hotkey.bind(modHyper, 'd', function() toggleApp('Dash') end)
hs.hotkey.bind(modHyper, 'f', function() toggleApp('Fastmail') end)
hs.hotkey.bind(altCmd,   'f', function() hs.window.focusedWindow():maximize() end)
hs.hotkey.bind(modHyper, 'h', function() hs.toggleConsole() end)
hs.hotkey.bind(modHyper, 'i', function() toggleApp('IntelliJ IDEA 14') end)
hs.hotkey.bind(modHyper, 'r', function()
  os.execute('open -a /Applications/Microsoft\\ Remote\\ Desktop.app/Contents/MacOS/Microsoft\\ Remote\\ Desktop ~/doc/misc/rds.rdp')
end)
hs.hotkey.bind(modHyper, 'm', function()
  setAudioOutput(talkDevice)
  toggleApp('Mumble')
end)
hs.hotkey.bind(modHyper, 'n', function() toggleApp('nvAlt') end)
hs.hotkey.bind(modHyper, 'o', function() toggleApp('OmniFocus') end)
hs.hotkey.bind(modHyper, 'p', function() hs.spotify.displayCurrentTrack() end)
hs.hotkey.bind(modHyper, 'q', function() toggleAudio() end)
hs.hotkey.bind(modHyper, 's', function() toggleApp('Slack') end)
hs.hotkey.bind(modHyper, 'w', function() hs.appfinder.windowFromWindowTitlePattern('^project_.*'):focus() end)
hs.hotkey.bind(modHyper, 'x', function() hs.grid.show() end)
hs.hotkey.bind(modHyper, 'z', function() hs.appfinder.windowFromWindowTitle('comms'):focus() end)
hs.hotkey.bind(modHyper, 'space', function() hs.timer.doAfter(1, function() hs.caffeinate.startScreensaver() end) end)

require 'caffeine'
require 'battery_watcher'
require 'caffeinate_watcher'
require 'usb_watcher'
require 'wifi_watcher'

-- We just booted - call all the handlers to get things in a sane state
batteryHandler()
wifiHandler()

sendNotification('Hammerspoon', 'Config reloaded')
