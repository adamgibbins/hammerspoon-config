local external_screen = "C49RG9x"
local builtin_screen = "Built-in Retina Display"
local audio_output_device = "Scarlett Solo USB"
-- Implemented with https://hyperkey.app/
local modHyper = { "cmd", "alt", "ctrl", "shift" }

local hostname = hs.host.localizedName()

-- First match wins, so keep external above builtin screen
-- stylua: ignore start
local profiles = {
  {
    machine = "CW9LKX6L63",
    screen = external_screen,
    layouts = {
      -- Top left
      { "Microsoft Teams", nil, { x = 0,    y = 0,   w = 1044, h = 1082 }, launch=true },
      -- Top right
      { "Obsidian",        nil, { x = 3794, y = 0,   w = 1326, h = 809  }, launch=true },
      { "OmniFocus",       nil, { x = 3794, y = 0,   w = 1326, h = 809  } },
      -- Bottom right
      { "Spotify",         nil, { x = 3794, y = 809, w = 1326, h = 601  } },
      -- Middle
      { "Ghostty",         nil, { x = 1044, y = 0,   w = 2750, h = 1440 }, launch=true },
      { "Microsoft Edge",  nil, { x = 1044, y = 0,   w = 2750, h = 1440 }, launch=true },
      { "Firefox",         nil, { x = 1044, y = 0,   w = 2750, h = 1440 }, },
      { "Code",            nil, { x = 1044, y = 0,   w = 2750, h = 1440 }, launch=true },
      { "Microsoft Outlook", nil, { x = 1044, y = 0,   w = 2750, h = 1440 }, launch=true },
    },
  },
  {
    machine = "CW9LKX6L63",
    screen = builtin_screen,
    layouts = {
      { "Ghostty",        nil, { x = 0, y = 0, w = 2560, h = 1440 }, launch=true },
      { "Microsoft Edge", nil, { x = 0, y = 0, w = 2560, h = 1440 }, launch=true },
      { "Code",           nil, { x = 0, y = 0, w = 2560, h = 1440 }, launch=true },
    },
  },
  {
    machine = "aeg-laptop23",
    screen = external_screen,
    layouts = {
      -- Top left
      { "Discord",         nil, { x = 0, y = 0, w = 1044, h = 720 } },
      -- Bottom left
      { "WhatsApp",        nil, { x = 0, y = 720, w = 1044, h = 719 } },
      { "Beeper",          nil, { x = 0, y = 720, w = 1044, h = 690 } },
      -- Top right
      { "Obsidian",        nil, { x = 3794, y = 0, w = 1326, h = 809 }, launch=true },
      { "OmniFocus",       nil, { x = 3794, y = 0, w = 1326, h = 809 }, launch=true },
      -- Bottom right
      { "Spotify",         nil, { x = 3794, y = 809, w = 1326, h = 601 }, launch=true },
      -- Middle
      { "Ghostty",         nil, { x = 1044, y = 0, w = 2750, h = 1440 }, launch=true },
      { "Fastmail",        nil, { x = 1044, y = 0, w = 2750, h = 1440 }, launch=true },
      { "Microsoft Edge",  nil, { x = 1044, y = 0, w = 2750, h = 1440 }, launch=true },
      { "Google Chrome",   nil, { x = 1044, y = 0, w = 2750, h = 1440 }, },
      { "Firefox",         nil, { x = 1044, y = 0, w = 2750, h = 1440 }, },
      { "Firefox Developer Edition", nil, { x = 1044, y = 0, w = 2750, h = 1440 }, },
      { "Code",            nil, { x = 1044, y = 0, w = 2750, h = 1440 } },
    },
  },
  {
    machine = "aeg-laptop23",
    screen = builtin_screen,
    layouts = {
      { "Ghostty",         nil, { x = 0, y = 0, w = 1800, h = 1169 }, launch=true },
      { "Fastmail",        nil, { x = 0, y = 0, w = 1800, h = 1169 }, launch=true },
      { "Microsoft Edge",  nil, { x = 0, y = 0, w = 1800, h = 1169 }, launch=true },
      { "Google Chrome",   nil, { x = 0, y = 0, w = 1800, h = 1169 }, },
      { "Firefox",         nil, { x = 0, y = 0, w = 1800, h = 1169 }, },
      { "Firefox Developer Edition", nil, { x = 0, y = 0, w = 1800, h = 1169 }, },
      { "Code",            nil, { x = 0, y = 0, w = 1800, h = 1169 } },
    },
  },
}
-- stylua: ignore end

hs.ipc.cliInstall()

hs.autoLaunch(true)
hs.automaticallyCheckForUpdates(true)
hs.preferencesDarkMode(true)
hs.accessibilityState(true)
hs.dockIcon(false)
hs.menuIcon(false)
hs.consoleOnTop(true)

hs.window.animationDuration = 0.1

local function notify(title, description, time)
  time = time or 2
  hs.notify
    .new({
      title = title,
      informativeText = description,
      withdrawAfter = time,
    })
    :send()
end

local reloadTimer = nil
configWatcher = hs.pathwatcher.new(hs.configdir, function(files)
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      if reloadTimer then
        reloadTimer:stop()
      end
      reloadTimer = hs.timer.doAfter(0.5, function()
        print("Reloading config due to changes in " .. file)
        hs.reload()
      end)
      return
    end
  end
end)
configWatcher:start()

local function getActiveProfileAndScreen()
  for _, s in ipairs(hs.screen.allScreens()) do
    for _, profile in ipairs(profiles) do
      if profile.machine == hostname and profile.screen == s:name() then
        return profile, s
      end
    end
  end
end

local function buildEntry(layout, screen)
  local sf = screen:frame()
  local pos = layout[3]
  local rect = hs.geometry.rect(sf.x + pos.x, sf.y + pos.y, pos.w, pos.h)
  return { layout[1], layout[2], screen, nil, rect }
end

local function applyLayouts()
  local profile, screen = getActiveProfileAndScreen()
  if not profile then
    hs.alert.show("No matching profile found for this machine/screen.")
    return
  end
  local entries = {}
  for _, layout in ipairs(profile.layouts) do
    if layout.launch and not hs.application.find(layout[1], true) then
      hs.application.open(layout[1])
      print("Launched " .. layout[1])
    elseif hs.application.find(layout[1], true) then
      table.insert(entries, buildEntry(layout, screen))
    end
  end
  hs.layout.apply(entries)
  print("Applied layout for " .. profile.machine .. " on screen " .. profile.screen)
end

local function getWatchedAppNames()
  local seen = {}
  local names = {}
  for _, profile in ipairs(profiles) do
    for _, layout in ipairs(profile.layouts) do
      if not seen[layout[1]] then
        seen[layout[1]] = true
        table.insert(names, layout[1])
      end
    end
  end
  return names
end

windowFilter = hs.window.filter.new(getWatchedAppNames())
windowFilter:subscribe(hs.window.filter.windowCreated, function(win)
  local app = win:application()
  if not app then
    return
  end
  local appName = app:name()
  local profile, screen = getActiveProfileAndScreen()
  if not profile then
    return
  end
  for _, layout in ipairs(profile.layouts) do
    if layout[1] == appName then
      local sf = screen:frame()
      local pos = layout[3]
      win:setFrame(hs.geometry.rect(sf.x + pos.x, sf.y + pos.y, pos.w, pos.h))
      print("Repositioned " .. appName)
      break
    end
  end
end)

screenWatcher = hs.screen.watcher.new(applyLayouts)
screenWatcher:start()

applyLayouts()

hs.audiodevice.watcher.setCallback(function(event)
  if event == "dev#" then
    local output = hs.audiodevice.findDeviceByName(audio_output_device)
    if output and output ~= hs.audiodevice.defaultOutputDevice() then
      output:setDefaultOutputDevice()
      print("Switched audio output to " .. audio_output_device)
    end
  end
end)
hs.audiodevice.watcher.start()

local previousFocus = nil
local function toggleApp(appName, launchName)
  local focused = hs.window.focusedWindow()
  if focused and string.find(focused:application():name(), appName, 1, true) and previousFocus then
    previousFocus:focus()
    previousFocus = focused
  else
    previousFocus = focused
    hs.application.launchOrFocus(launchName or appName)
  end
end

hs.loadSpoon("Pomodoro")
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall:andUse("MouseCircle")

-- modHyper bindings (sorted by key)
hs.hotkey.bind(modHyper, "]", function()
  spoon.MouseCircle:show()
end)
hs.hotkey.bind(modHyper, "a", function()
  toggleApp("Ghostty")
end)
hs.hotkey.bind(modHyper, "b", function()
  toggleApp("Microsoft Edge")
end)
hs.hotkey.bind(modHyper, "e", function()
  toggleApp("Code", "Visual Studio Code")
end)
hs.hotkey.bind(modHyper, "m", function()
  toggleApp("Fastmail")
end)
hs.hotkey.bind(modHyper, "n", function()
  toggleApp("Obsidian")
end)
hs.hotkey.bind(modHyper, "o", function()
  toggleApp("OmniFocus")
end)
spoon.Pomodoro:bindHotkeys({ toggle = { modHyper, "p" } })
hs.hotkey.bind(modHyper, "s", function()
  toggleApp("Spotify")
end)
hs.hotkey.bind(modHyper, "w", function()
  toggleApp("WhatsApp")
end)

notify("Hammerspoon", "Config loaded")
