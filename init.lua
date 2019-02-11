-- Reload configuration on changes
pathWatcher = hs.pathwatcher.new(hs.configdir, function(files)
  for _,file in pairs(files) do
    if file:sub(-4) == '.lua' then
      hs.reload()
    end
  end
end)
pathWatcher:start()

require 'main'

notify('Hammerspoon', 'Config reloaded')
