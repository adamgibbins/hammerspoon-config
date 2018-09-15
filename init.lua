local modHyper = {'cmd', 'alt', 'ctrl', 'shift'}
local altCmd = {'alt', 'cmd'}

homeSSID = 'CatFi'

workPSU = 12735159

talkDevice = 'Sennheiser USB headset'

if hs.audiodevice.findOutputByName('aeg-qc35') then
  musicDevice = 'aeg-qc35'
elseif hs.audiodevice.findOutputByName('ODAC') then
  musicDevice = 'ODAC'
end


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
function notify(title, description, time)
  time = time or 2
  hs.notify.new({
    title=title,
    informativeText=description,
    withdrawAfter=time,
  }):send()
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
  notify('Location', 'Entering work')
  print('Entering work')

  if hs.battery.isCharging() then
    hs.brightness.set(100)
  end
end

function leaveWork()
  notify('Location', 'Leaving work')
  print('Leaving work')
end

function closeComms()
  hs.execute('/usr/local/bin/tmux send-keys -t comms C-a d')
  print('Closed comms')
end

function pauseMusic()
  if hs.spotify.isRunning() then
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
      notify('Audio Output', 'Switched to ' .. device)

      -- talkDevice is replugged often, when plugged in it starts on mute - so turn it up to a reasonable volume
      if device == talkDevice then
        hardwareDevice:setVolume(40)
        setAudioInput(talkDevice)
      end
    end
  else
    notify('Audio Alert', device .. ' is missing!')
  end
end

-- Configure audio input device, unless it doesn't exist - then notify
function setAudioInput(device)
  local hardwareDevice = hs.audiodevice.findInputByName(device)
  local currentDevice = hs.audiodevice.defaultInputDevice()

  if hardwareDevice then
    if currentDevice ~= hardwareDevice then
      hardwareDevice:setDefaultInputDevice()
      notify('Audio Input', 'Switched to ' .. device)
    end
  else
    notify('Audio Alert', device .. ' is missing!')
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
    notify('Wifi Off', 'Wifi is now off')
  else
    hs.wifi.setPower(true)
    notify('Wifi On', 'Wifi is now on')
  end
  local wifiIsPowered = nil
end

function switchToIde()
  local IDEs = { 'IntelliJ IDEA', 'RubyMine', 'PhpStorm', 'DataGrip', 'WebStorm', 'PyCharm' }
  local success = false

  for i, IDE in ipairs(IDEs) do
    if(hs.application(IDE)) then
      hs.application.launchOrFocus(IDE)
      success = true
      break
    end
  end

  if not success then
    notify('IDE Hotkey', 'No IDE found!')
  end
end

-- Misc bindings
hs.hotkey.bind(modHyper, '`', function() toggleInputMute() end)
hs.hotkey.bind(modHyper, '=', function() expose:toggleShow() end)
hs.hotkey.bind(modHyper, '-', function() toggleWifi() end)
hs.hotkey.bind(modHyper, '0', function() leaveWork() hs.layout.apply(laptopLayout) end)
hs.hotkey.bind(modHyper, '1', function() openMusicApplication('Spotify') end)
hs.hotkey.bind(modHyper, '2', function() openMusicApplication('Vox') end)
hs.hotkey.bind(modHyper, '9', function() enterWork() end)
hs.hotkey.bind(modHyper, 'c', function() toggleApp('Google Chrome') end)
hs.hotkey.bind(modHyper, 'd', function() toggleApp('Dash') end)
hs.hotkey.bind(modHyper, 'e', function() toggleApp('MailMate') end)
hs.hotkey.bind(modHyper, 'f', function() toggleApp('FoldingText') end)
hs.hotkey.bind(altCmd,   'f', function() hs.window.focusedWindow():maximize() end)
hs.hotkey.bind(modHyper, 'h', function() hs.toggleConsole() end)
hs.hotkey.bind(modHyper, 'i', function() switchToIde() end)
hs.hotkey.bind(modHyper, 'm', function()
  setAudioOutput(talkDevice)
  toggleApp('Mumble')
end)
hs.hotkey.bind(modHyper, 'n', function() toggleApp('nvAlt') end)
hs.hotkey.bind(modHyper, 'o', function() toggleApp('2Do') end)
hs.hotkey.bind(modHyper, 'p', function() toggleApp('1Password 6') end)
hs.hotkey.bind(modHyper, 'q', function() toggleAudio() end)
hs.hotkey.bind(modHyper, 'r', function()
  os.execute('open -a /Applications/Microsoft\\ Remote\\ Desktop.app/Contents/MacOS/Microsoft\\ Remote\\ Desktop ~/doc/misc/rds.rdp')
end)
hs.hotkey.bind(modHyper, 's', function() toggleApp('Safari') end)
hs.hotkey.bind(modHyper, 't', function() toggleApp('Tweetbot') end)
hs.hotkey.bind({'cmd', 'shift'}, 'v', function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)
hs.hotkey.bind(modHyper, 'w', function() hs.appfinder.windowFromWindowTitlePattern('^project_.*'):focus() end)
hs.hotkey.bind(modHyper, 'x', function() hs.grid.show() end)
hs.hotkey.bind(modHyper, 'z', function() hs.appfinder.windowFromWindowTitle('comms'):focus() end)
hs.hotkey.bind(modHyper, 'space', function() hs.timer.doAfter(1, function() hs.caffeinate.startScreensaver() end) end)

hs.loadSpoon('Caffeine')
spoon.Caffeine:start()
hs.loadSpoon('MouseCircle')
spoon.MouseCircle:bindHotkeys({show={modHyper, ']'}})
require 'app_watcher'
require 'battery_watcher'
require 'caffeinate_watcher'
require 'usb_watcher'

-- We just booted - call all the handlers to get things in a sane state
batteryHandler()

notify('Hammerspoon', 'Config reloaded')
