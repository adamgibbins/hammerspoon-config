local modHyper = {'⌘', '⌥', '⌃', '⇧'}

hs.pathwatcher.new(hs.configdir, function()
  hs.reload()
end):start()

hs.hotkey.bind(modHyper, 'c', function() hs.application.launchOrFocus('Google Chrome') end)
hs.hotkey.bind(modHyper, 'i', function() hs.application.launchOrFocus('iTerm') end)
hs.hotkey.bind(modHyper, 'm', function() hs.application.launchOrFocus('Mumble') end)
hs.hotkey.bind(modHyper, 'n', function() hs.application.launchOrFocus('nvAlt') end)
hs.hotkey.bind(modHyper, 'o', function() hs.application.launchOrFocus('OmniFocus') end)
hs.hotkey.bind(modHyper, 's', function() hs.application.launchOrFocus('Spotify') end)
hs.hotkey.bind(modHyper, 'v', function() hs.application.launchOrFocus('Vox') end)

hs.notify.new({
  title='Hammerspoon',
  informativeText='Config reloaded'
}):send()
