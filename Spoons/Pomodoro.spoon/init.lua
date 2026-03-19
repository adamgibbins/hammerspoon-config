local obj = {}
obj.__index = obj

obj.workSeconds = 60 * 25
obj.breakSeconds = 60 * 5
obj.workStartShortcut = "Quiet Focus On"
obj.workEndShortcut = "Quiet Focus Off"
obj.logFile = os.getenv("HOME") .. "/.pomodoro.log"

obj.defaultHotkey = { { "cmd", "ctrl", "alt" }, "P" }

local STATE = {
  IDLE = "idle",
  WORKING = "working",
  BREAKING = "breaking",
  PAUSED = "paused",
}

function obj:init()
  self.state = STATE.IDLE
  self.timeLeft = 0
  self.isWorkSession = true
  self.menuItem = hs.menubar.new()
  self.completedToday = 0
  self.lastDateCheck = os.date("%Y-%m-%d")
  self:_renderMenu()
end

function obj:bindHotkeys(mapping)
  if self.hotkeyObj then
    self.hotkeyObj:delete()
  end

  local keys = mapping and mapping.toggle or self.defaultHotkey
  self.hotkeyObj = hs.hotkey.bind(keys[1], keys[2], function()
    self:_handleHotkeyPress()
  end)
end

function obj:_handleHotkeyPress()
  if self.state == STATE.IDLE then
    self:start()
  elseif self.state == STATE.PAUSED then
    self:resume()
  else
    self:pause()
  end
end

function obj:start()
  local isWork = self.isWorkSession
  self.state = isWork and STATE.WORKING or STATE.BREAKING
  self.timeLeft = isWork and self.workSeconds or self.breakSeconds
  if isWork then
    hs.shortcuts.run(self.workStartShortcut)
  end
  self:_log("started")
  self:_startCountdown()
  self:_renderMenu()
end

function obj:pause()
  if self.state == STATE.WORKING or self.state == STATE.BREAKING then
    self.state = STATE.PAUSED
    if self.timer then
      self.timer:stop()
    end
    self:_log("paused")
    self:_renderMenu()
  end
end

function obj:resume()
  if self.state == STATE.PAUSED then
    local isWork = self.isWorkSession
    self.state = isWork and STATE.WORKING or STATE.BREAKING
    if isWork then
      hs.shortcuts.run(self.workStartShortcut)
    end
    self:_log("resumed")
    self:_startCountdown()
    self:_renderMenu()
  end
end

function obj:reset()
  if self.state == STATE.IDLE then
    return
  end
  if self.timer then
    self.timer:stop()
  end
  self.state = STATE.IDLE
  self.timeLeft = 0
  self:_log("reset")
  self:_renderMenu()
end

function obj:_log(action)
  local sessionType = self.isWorkSession and "work" or "break"
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local logEntry = timestamp .. " - " .. sessionType .. " " .. action .. "\n"
  local f = io.open(self.logFile, "a")
  if f then
    f:write(logEntry)
    f:close()
  end
end

function obj:_startCountdown()
  if self.timer then
    self.timer:stop()
  end

  self.timer = hs.timer.doEvery(1, function()
    self.timeLeft = self.timeLeft - 1
    self:_renderMenu()

    if self.timeLeft <= 0 then
      self:_completeSession()
    end
  end)
end

function obj:_completeSession()
  if self.timer then
    self.timer:stop()
    self.timer = nil
  end

  if self.isWorkSession then
    hs.alert.show("Work done!", { textSize = 60 }, 5)
    self.completedToday = self.completedToday + 1
  else
    hs.alert.show("Break done!", { textSize = 60 }, 5)
  end

  hs.sound.getByName("Glass"):play()

  self:_log("completed")
  if self.isWorkSession then
    hs.shortcuts.run(self.workEndShortcut)
  end
  self.isWorkSession = not self.isWorkSession
  self.state = STATE.IDLE
  self.timeLeft = 0
  self:_renderMenu()
end

function obj:_getEmoji()
  if self.isWorkSession then
    return "🍅"
  else
    return "☕"
  end
end

function obj:_formatTime()
  local mins = math.floor(self.timeLeft / 60)
  local secs = self.timeLeft % 60
  return string.format("%02d:%02d", mins, secs)
end

function obj:_renderMenu()
  local today = os.date("%Y-%m-%d")
  if today ~= self.lastDateCheck then
    self.completedToday = 0
    self.lastDateCheck = today
  end

  local emoji = self:_getEmoji()

  if self.state == STATE.IDLE then
    local label = self.isWorkSession and "Start Work" or "Start Break"
    local countLabel = self.completedToday > 0 and (" (" .. self.completedToday .. ")") or ""
    self.menuItem:setTitle(emoji .. countLabel)
    self.menuItem:setMenu({
      {
        title = label,
        fn = function()
          self:start()
        end,
      },
    })
  else
    local timeStr = self:_formatTime()
    self.menuItem:setTitle(emoji .. " " .. timeStr)

    if self.state == STATE.PAUSED then
      self.menuItem:setMenu({
        {
          title = "Resume",
          fn = function()
            self:resume()
          end,
        },
        {
          title = "Reset",
          fn = function()
            self:reset()
          end,
        },
      })
    else
      self.menuItem:setMenu({
        {
          title = "Pause",
          fn = function()
            self:pause()
          end,
        },
        {
          title = "Reset",
          fn = function()
            self:reset()
          end,
        },
      })
    end
  end
end

return obj
