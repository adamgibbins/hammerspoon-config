hs.pathwatcher.new(hs.configdir, function()
  hs.reload()
end):start()

hs.notify.new({
  title='Hammerspoon',
  informativeText='Config reloaded'
}):send()
