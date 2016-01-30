function wifiHandler()
  local currentSSID = hs.wifi.currentNetwork()

  -- Turn Caffeine off when leaving home network
  if currentSSID == homeSSID then
    hs.caffeinate.set('displayIdle', true)
  else
    hs.caffeinate.set('displayIdle', false)
  end

  -- Put the caffeine icon in the correct state, as we just modified it without clicking
  setCaffeineDisplay(hs.caffeinate.get('displayIdle'))
end
wifiWatcher = hs.wifi.watcher.new(wifiHandler):start()
