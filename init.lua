local external_screen = "C49RG9x"
local builtin_screen = "Built-in Retina Display"

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
      { "Ghostty",         nil, { x = 0, y = 0, w = 2560, h = 1440 }, launch=true },
      { "Microsoft Edge",  nil, { x = 0, y = 0, w = 2560, h = 1440 }, launch=true },
      { "Google Chrome",   nil, { x = 1044, y = 0, w = 2750, h = 1440 }, },
      { "Firefox",         nil, { x = 1044, y = 0, w = 2750, h = 1440 }, },
      { "Firefox Developer Edition", nil, { x = 1044, y = 0, w = 2750, h = 1440 }, },
      { "Code",            nil, { x = 0, y = 0, w = 2560, h = 1440 } },
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

configWatcher = hs.pathwatcher.new(hs.configdir, function(files)
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      hs.reload()
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
    else
      table.insert(entries, buildEntry(layout, screen))
    end
  end
  hs.layout.apply(entries)
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
      break
    end
  end
end)

screenWatcher = hs.screen.watcher.new(applyLayouts)
screenWatcher:start()

applyLayouts()

hs.loadSpoon("Pomodoro")
spoon.Pomodoro:bindHotkeys()

notify("Hammerspoon", "Config loaded")
