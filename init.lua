local modHyper = {'cmd', 'alt', 'ctrl', 'shift'}
local altCmd = {'alt', 'cmd'}

homeSSID = 'CatFi'

workPSU = 12735159

talkDevice = 'Sennheiser USB headset'
local musicDevice = 'ODAC'

local workScreenMiddle = 1007310081
local workScreenLeft = 1007310146
local screenInternal = 69732928

local expose = hs.expose.new()

local workLayout = {
  { 'cieye',            nil,                hs.screen.find(workScreenLeft),   hs.geometry.unitrect(0,    0,    0.33, 0.33 ), nil, nil },
  { 'Dash',             nil,                hs.screen.find(screenInternal),   hs.layout.maximized,                           nil, nil },
  { 'Google Chrome',    nil,                hs.screen.find(screenInternal),   hs.layout.maximized,                           nil, nil },
  { 'nagdash',          nil,                hs.screen.find(workScreenLeft),   hs.geometry.unitrect(0.33, 0,    0.68, 0.33 ), nil, nil },
  { 'Skype Web',        nil,                hs.screen.find(workScreenLeft),   hs.geometry.unitrect(0.43, 0.35, 0.58, 0.6  ), nil, nil },
  { 'Terminal',         'comms',            hs.screen.find(workScreenLeft),   hs.geometry.unitrect(0,    0.33, 1.0,  0.675), nil, nil },
  { 'Terminal',         nil,                hs.screen.find(workScreenMiddle), hs.layout.maximized,                           nil, nil },
  { 'Tweetbot',         nil,                hs.screen.find(workScreenLeft),   hs.geometry.unitrect(0.43, 0.35, 0.58, 0.6  ), nil, nil },
}

local laptopLayout = {
  { '1Password 6',              nil,          hs.screen.find(screenInternal), hs.layout.right70,      nil, nil },
  { 'Dash',                     nil,          hs.screen.find(screenInternal), hs.layout.maximized,    nil, nil },
  { 'Fastmail',                 nil,          hs.screen.find(screenInternal), hs.layout.maximized,    nil, nil },
  { 'Firefox',                  nil,          hs.screen.find(screenInternal), hs.layout.right75,      nil, nil },
  { 'FoldingText',              nil,          hs.screen.find(screenInternal), hs.layout.right70,      nil, nil },
  { 'Google Chrome',            nil,          hs.screen.find(screenInternal), hs.layout.right75,      nil, nil },
  { 'nvALT',                    nil,          hs.screen.find(screenInternal), hs.layout.right70,      nil, nil },
  { 'OmniFocus',                nil,          hs.screen.find(screenInternal), hs.layout.maximized,    nil, nil },
  { 'Skype Web',                nil,          hs.screen.find(screenInternal), hs.layout.left25,       nil, nil },
  { 'Terminal',                 'comms',      hs.screen.find(screenInternal), hs.layout.left75,       nil, nil },
  { 'Terminal',                 nil,          hs.screen.find(screenInternal), hs.layout.maximized,    nil, nil },
  { 'Tweetbot',                 nil,          hs.screen.find(screenInternal), hs.layout.left50,       nil, nil },
}

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

function listScreens()
  for k,v in pairs(hs.screen.allScreens()) do
    print(k,v)
  end
end

-- Toggle between an app and the previously focused window
function toggleApp(app)
  if hs.window.focusedWindow() and hs.window.focusedWindow():application():title() == app and previousFocus then
    previousFocus:focus()
  else
    previousFocus = hs.window.focusedWindow()
    hs.application.launchOrFocus(app)
  end
end

function killIfApplicationRunning(application, force)
  local app = hs.application.get(application)
  if app then
    if force then
      app:kill9()
    else
      app:kill()
    end
  end
end

function enterWork()
  sendNotification('Location', 'Entering work')
  printMessage('Entering work')
  listScreens()
  hs.application.launchOrFocus('nagdash')
  hs.application.launchOrFocus('cieye')
  hs.application.launchOrFocus('Google Chrome')
  os.execute('/usr/local/bin/task context tg')
  hs.layout.apply(workLayout)

  if hs.battery.isCharging() then
    hs.brightness.set(100)
  end
end

function leaveWork()
  sendNotification('Location', 'Leaving work')
  printMessage('Leaving work')
  listScreens()
  killIfApplicationRunning('nagdash')
  killIfApplicationRunning('cieye')
  killIfApplicationRunning('Mumble')
  killIfApplicationRunning('Microsoft Remote Desktop', true)
  os.execute('/usr/local/bin/task context personal')
  hs.layout.apply(laptopLayout)
end

function closeComms()
  hs.execute('/usr/local/bin/tmux send-keys -t comms C-a d')
  printMessage('Closed comms')
end

function pauseMusic()
  if hs.spotify.isRunning() then
    hs.spotify.pause()
  end
end

-- From https://github.com/cmsj/hammerspoon-config/blob/master/init.lua
function mouseHighlight()
    if mouseCircle then
        mouseCircle:delete()
        if mouseCircleTimer then
            mouseCircleTimer:stop()
        end
    end
    mousepoint = hs.mouse.getAbsolutePosition()
    mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x-40, mousepoint.y-40, 80, 80))
    mouseCircle:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1})
    mouseCircle:setFill(false)
    mouseCircle:setStrokeWidth(5)
    mouseCircle:bringToFront(true)
    mouseCircle:show(0.5)

    mouseCircleTimer = hs.timer.doAfter(3, function()
        mouseCircle:hide(0.5)
        hs.timer.doAfter(0.6, function() mouseCircle:delete() end)
    end)
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
        setAudioInput(talkDevice)
      end
    end
  else
    sendNotification('Audio Alert', device .. ' is missing!')
  end
end

-- Configure audio input device, unless it doesn't exist - then notify
function setAudioInput(device)
  local hardwareDevice = hs.audiodevice.findInputByName(device)
  local currentDevice = hs.audiodevice.defaultInputDevice()

  if hardwareDevice then
    if currentDevice ~= hardwareDevice then
      hardwareDevice:setDefaultInputDevice()
      sendNotification('Audio Input', 'Switched to ' .. device)
    end
  else
    sendNotification('Audio Alert', device .. ' is missing!')
  end
end

-- Toggle between the two audio devices
local function toggleAudio()
  local currentDevice = hs.audiodevice.defaultOutputDevice()

  if currentDevice:name() == talkDevice then
    setAudioOutput(musicDevice)
  else
    setAudioOutput(talkDevice)
    setAudioInput(talkDevice)
  end
end

local function toggleInputMute()
  local currentDevice = hs.audiodevice.defaultInputDevice()
 if currentDevice:inputVolume() < 40 then
   currentDevice:setInputVolume(40)
   hs.alert('Unmuted', 1)
 else
   currentDevice:setInputVolume(0)
   hs.alert('Muted', 1)
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
    sendNotification('Wifi Off', 'Wifi is now off')
  else
    hs.wifi.setPower(true)
    sendNotification('Wifi On', 'Wifi is now on')
  end
  local wifiIsPowered = nil
end

function switchToIde()
  local IDEs = { 'IntelliJ IDEA', 'RubyMine', 'PhpStorm', 'DataGrip', 'WebStorm' }
  local success = false

  for i, IDE in ipairs(IDEs) do
    if(hs.application(IDE)) then
      hs.application.launchOrFocus(IDE)
      success = true
      break
    end
  end

  if not success then
    sendNotification('IDE Hotkey', 'No IDE found!')
  end
end

-- Misc bindings
hs.hotkey.bind(modHyper, '`', function() toggleInputMute() end)
hs.hotkey.bind(modHyper, '=', function() expose:toggleShow() end)
hs.hotkey.bind(modHyper, '-', function() toggleWifi() end)
hs.hotkey.bind(modHyper, ']', function() mouseHighlight() end)
hs.hotkey.bind(modHyper, '0', function() leaveWork() hs.layout.apply(laptopLayout) end)
hs.hotkey.bind(modHyper, '1', function() openMusicApplication('Spotify') end)
hs.hotkey.bind(modHyper, '2', function() openMusicApplication('Vox') end)
hs.hotkey.bind(modHyper, '9', function() enterWork() end)
hs.hotkey.bind(modHyper, 'c', function() toggleApp('Google Chrome') end)
hs.hotkey.bind(modHyper, 'd', function() toggleApp('Dash') end)
hs.hotkey.bind(modHyper, 'e', function() toggleApp('Fastmail') end)
hs.hotkey.bind(modHyper, 'f', function() toggleApp('FoldingText') end)
hs.hotkey.bind(altCmd,   'f', function() hs.window.focusedWindow():maximize() end)
hs.hotkey.bind(modHyper, 'h', function() hs.toggleConsole() end)
hs.hotkey.bind(modHyper, 'i', function() switchToIde() end)
hs.hotkey.bind(modHyper, 'm', function()
  setAudioOutput(talkDevice)
  toggleApp('Mumble')
end)
hs.hotkey.bind(modHyper, 'n', function() toggleApp('nvAlt') end)
hs.hotkey.bind(modHyper, 'o', function() toggleApp('OmniFocus') end)
hs.hotkey.bind(modHyper, 'p', function() toggleApp('1Password 6') end)
hs.hotkey.bind(modHyper, 'q', function() toggleAudio() end)
hs.hotkey.bind(modHyper, 'r', function()
  os.execute('open -a /Applications/Microsoft\\ Remote\\ Desktop.app/Contents/MacOS/Microsoft\\ Remote\\ Desktop ~/doc/misc/rds.rdp')
end)
hs.hotkey.bind(modHyper, 's', function() toggleApp('Skype Web') end)
hs.hotkey.bind(modHyper, 't', function() toggleApp('Tweetbot') end)
hs.hotkey.bind({'cmd', 'shift'}, 'v', function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)
hs.hotkey.bind(modHyper, 'w', function() hs.appfinder.windowFromWindowTitlePattern('^project_.*'):focus() end)
hs.hotkey.bind(modHyper, 'x', function() hs.grid.show() end)
hs.hotkey.bind(modHyper, 'z', function() hs.appfinder.windowFromWindowTitle('comms'):focus() end)
hs.hotkey.bind(modHyper, 'space', function() hs.timer.doAfter(1, function() hs.caffeinate.startScreensaver() end) end)

require 'app_watcher'
require 'battery_watcher'
require 'caffeinate_watcher'
require 'caffeine'
require 'usb_watcher'
require 'wifi_watcher'

-- We just booted - call all the handlers to get things in a sane state
batteryHandler()
wifiHandler()

sendNotification('Hammerspoon', 'Config reloaded')
