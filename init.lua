local external_monitor = "C49RG9x"
local builtin_monitor  = "Built-in Retina Display"

-- First match wins, so keep external above internal monitor
local profiles = {
  {
    machine = "CW9LKX6L63",
    monitor = external_monitor,
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
      { "Code",            nil, { x = 1044, y = 0,   w = 2750, h = 1440 }, launch=true },
    },
  },
  {
    machine = "CW9LKX6L63",
    monitor = builtin_monitor,
    layouts = {
      { "Ghostty",        nil, { x = 0, y = 0, w = 2560, h = 1440 }, launch=true },
      { "Microsoft Edge", nil, { x = 0, y = 0, w = 2560, h = 1440 }, launch=true },
      { "Code",           nil, { x = 0, y = 0, w = 2560, h = 1440 }, launch=true },
    },
  },
  {
    machine = "aeg-laptop23",
    monitor = external_monitor,
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
      { "Code",            nil, { x = 1044, y = 0, w = 2750, h = 1440 } },
    },
  },
  {
    machine = "aeg-laptop23",
    monitor = builtin_monitor,
    layouts = {
      { "Ghostty",        nil, { x = 0, y = 0, w = 2560, h = 1440 }, launch=true },
      { "Microsoft Edge", nil, { x = 0, y = 0, w = 2560, h = 1440 }, launch=true },
      { "Code",           nil, { x = 0, y = 0, w = 2560, h = 1440 } },
    },
  },
}

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
  hs.notify.new({
    title=title,
    informativeText=description,
    withdrawAfter=time,
  }):send()
end

configWatcher = hs.pathwatcher.new(hs.configdir, function(files)
    for _,file in pairs(files) do
      if file:sub(-4) == '.lua' then
        hs.reload()
      end
    end
  end)
configWatcher:start()

local function getActiveProfile()
  local machine = hs.host.localizedName()
  local screenNames = {}
  for _, screen in ipairs(hs.screen.allScreens()) do
    screenNames[screen:name()] = true
  end
  for _, profile in ipairs(profiles) do
    if profile.machine == machine and screenNames[profile.monitor] then
      return profile
    end
  end
end

local function findScreen(name)
  for _, s in ipairs(hs.screen.allScreens()) do
    if s:name() == name then return s end
  end
end

local function buildEntry(layout, screen)
  local sf = screen:frame()
  local pos = layout[3]
  local rect = hs.geometry.rect(sf.x + pos.x, sf.y + pos.y, pos.w, pos.h)
  return { layout[1], layout[2], screen, nil, rect }
end

local function applyLayouts()
  local profile = getActiveProfile()
  if not profile then
    hs.alert.show("No matching profile found for this machine/monitor.")
    return
  end
  local screen = findScreen(profile.monitor)
  if not screen then
    hs.alert.show("Monitor not found: " .. tostring(profile.monitor))
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

appWatcher = hs.application.watcher.new(function(name, event, _app)
  if event ~= hs.application.watcher.launched then return end
  local profile = getActiveProfile()
  if not profile then return end
  local screen = findScreen(profile.monitor)
  if not screen then return end
  for _, layout in ipairs(profile.layouts) do
    if layout[1] == name then
      local entry = buildEntry(layout, screen)
      hs.layout.apply({ entry })
    end
  end
end)
appWatcher:start()

screenWatcher = hs.screen.watcher.new(applyLayouts)
screenWatcher:start()

applyLayouts()

notify("Hammerspoon", "Config loaded")
