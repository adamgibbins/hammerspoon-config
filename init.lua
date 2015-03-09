hs.pathwatcher.new(hs.configdir, function()
  hs.reload()
end):start()

hs.alert.show('Hammerspoon config reloaded')
