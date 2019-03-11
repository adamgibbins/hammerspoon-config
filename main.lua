modHyper = {'cmd', 'alt', 'ctrl', 'shift'}
altCmd = {'alt', 'cmd'}

workPSU = 12735159
talkDevice = 'Sennheiser USB headset'
musicDevices = {
  'WH-1000XM3',
  'aeg-qc35',
  'ODAC',
  'Headphones',
  'Built-in Output',
}

-- Util function to send notifications, with the standard boilerplate
function notify(title, description, time)
  time = time or 2
  hs.notify.new({
    title=title,
    informativeText=description,
    withdrawAfter=time,
  }):send()
end

hs.loadSpoon('SpoonInstall')
spoon.SpoonInstall:andUse('MouseCircle', {
  hotkeys = {
    show = { modHyper, ']' }
  }
})
spoon.SpoonInstall:andUse('Caffeine', {
  start = true
})

hs.grid.setGrid('6x3')
hs.grid.setMargins('0x0')

-- Turn off animations, I don't like slow things
hs.window.animationDuration = 0

-- Make HS accessible from the command line
hs.ipc.cliInstall()
hs.ipc.cliSaveHistory(true)

hs.autoLaunch(true)
hs.automaticallyCheckForUpdates(true)
hs.preferencesDarkMode(true)
hs.accessibilityState(true)
hs.dockIcon(false)
hs.menuIcon(false)
hs.consoleOnTop(true)

require 'audio'

function pauseMusic()
  if hs.spotify.isRunning() then
    hs.spotify.pause()
  end
end

function openMusicApplication(name)
  toggleApp(name)
  setMusicDevice()
end

-- Toggle between an app and the previously focused window
function toggleApp(app)
  if hs.window.focusedWindow()
    and hs.window.focusedWindow():application():title() == app
    and previousFocus then
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

function toggleWifi()
  local wifiIsPowered = hs.wifi.interfaceDetails('en0')['power']
  if wifiIsPowered then
    hs.wifi.setPower(false)
    notify('Wifi Off', 'Wifi is now off')
  else
    hs.wifi.setPower(true)
    notify('Wifi On', 'Wifi is now on')
  end
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

apps = {
  todo = 'Remember The Milk',
  terminal = 'Terminal',
  twitter = 'Tweetbot',
  browser = 'Google Chrome',
  browser_secondary = 'Safari',
  mail = 'MailMate',
}

laptopScreen = hs.screen.find('Color LCD')
workCenterScreen = hs.screen.find(724847118)
workRightScreen = hs.screen.find(724850701)

workLayout = {
  {'Spotify',               nil,                       laptopScreen,      hs.layout.maximized,             nil, nil},
  {apps.terminal,           nil,                       workCenterScreen,  hs.layout.maximized,             nil, nil},
  {apps.terminal,           'comms',                   workRightScreen,   {x=0,    y=0.3,  w=1,    h=0.7}, nil, nil},
  {apps.browser,            nil,                       workRightScreen,   {x=0.2,  y=0.3,  w=0.8,  h=0.7}, nil, nil},
  {apps.browser_secondary,  nil,                       workRightScreen,   {x=0,    y=0,    w=0.67, h=0.3}, nil, nil},
  {'cieye',                 'Infrastructure - CI-Eye', workRightScreen,   {x=0.67, y=0,    w=0.33, h=0.2}, nil, nil},
  {'cieye',                 'adam - CI-Eye',           workRightScreen,   {x=0.67, y=0.2,  w=0.33, h=0.1}, nil, nil},
  {'Discord',               nil,                       workRightScreen,   nil,                             nil, nil},
}

laptopLayout = {
  -- app, window, screen, unit, frame, full-frame
  {apps.terminal,          nil, laptopScreen, hs.layout.maximized, nil, nil},
  {apps.mail,              nil, laptopScreen, hs.layout.maximized, nil, nil},
  {'IntelliJ IDEA',        nil, laptopScreen, hs.layout.maximized, nil, nil},
  {'PyCharm',              nil, laptopScreen, hs.layout.maximized, nil, nil},
  {apps.browser,           nil, laptopScreen, hs.layout.maximized, nil, nil},
  {apps.browser_secondary, nil, laptopScreen, hs.layout.maximized, nil, nil},
  {'Spotify',              nil, laptopScreen, hs.layout.maximized, nil, nil},
  {'Discord',              nil, laptopScreen, hs.layout.right75,   nil, nil},
  {apps.twitter,           nil, laptopScreen, hs.layout.right75,   nil, nil},
  {apps.todo,              nil, laptopScreen, hs.layout.right75,   nil, nil},
  {'Slack',                nil, laptopScreen, hs.layout.right75,   nil, nil},
}

function enterWork()
  hs.alert('Entering work')
  hs.layout.apply(workLayout)

  if hs.battery.isCharging() then
    hs.brightness.set(100)
  end
end

function leaveWork()
  hs.alert('Leaving work')
  hs.layout.apply(laptopLayout)
end

for _, name in ipairs({
  'Discord Helper',
  'Safari Storage',
}) do
  hs.window.filter.ignoreAlways[name] = true
end

hs.hotkey.bind(modHyper, '-', function() toggleWifi() end)
hs.hotkey.bind(modHyper, '1', function() openMusicApplication('Spotify') end)
hs.hotkey.bind(modHyper, 'c', function() toggleApp(apps.browser) end)
hs.hotkey.bind(modHyper, 'd', function() toggleApp('Dash') end)
hs.hotkey.bind(modHyper, 'e', function() toggleApp('MailMate') end)
hs.hotkey.bind(modHyper, 'f', function() toggleApp('Firefox') end)
hs.hotkey.bind(altCmd,   'f', function() hs.window.focusedWindow():maximize() end)
hs.hotkey.bind(modHyper, 'h', function() hs.toggleConsole() end)
hs.hotkey.bind(modHyper, 'i', function() switchToIde() end)
hs.hotkey.bind(modHyper, 'm', function()
  setAudioOutput(talkDevice)
  toggleApp('Mumble')
end)
hs.hotkey.bind(modHyper, 'n', function() toggleApp('nvAlt') end)
hs.hotkey.bind(modHyper, 'o', function() toggleApp(apps.todo) end)
hs.hotkey.bind(modHyper, 'p', function() toggleApp('1Password 7') end)
hs.hotkey.bind(modHyper, 'q', function() toggleAudio() end)
hs.hotkey.bind(modHyper, 's', function() toggleApp(apps.browser_secondary) end)
hs.hotkey.bind(modHyper, 't', function() toggleApp(apps.twitter) end)
hs.hotkey.bind({'cmd', 'shift'}, 'v', function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)
hs.hotkey.bind(modHyper, 'w', function() hs.appfinder.windowFromWindowTitlePattern('^2. .*'):focus() end)
hs.hotkey.bind(modHyper, 'x', function() hs.grid.show() end)
hs.hotkey.bind(modHyper, 'z', function() hs.appfinder.windowFromWindowTitlePattern('^1. .*'):focus() end)
hs.hotkey.bind(modHyper, 'space', function() hs.timer.doAfter(1, function() hs.caffeinate.startScreensaver() end) end)
-- Display a menubar item to indicate if the Internet is reachable
reachabilityMenuItem = require("reachabilityMenuItem"):start()

require 'app_watcher'
require 'battery_watcher'
require 'caffeinate_watcher'
require 'usb_watcher'

-- We just booted - call all the handlers to get things in a sane state
batteryHandler()
