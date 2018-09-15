function caffeinateHandler(event)
  print('caffeinateWatcher triggered')
  -- Mute sounds on suspend, or if shutting down - to stop the startup chime
  if event == hs.caffeinate.watcher.systemWillSleep or event == hs.caffeinate.watcher.systemWillPowerOff then
    print('Sleeping')
    hs.audiodevice.defaultOutputDevice():setMuted(true)
    closeComms()
    pauseMusic()
  end

  if event == hs.caffeinate.watcher.screensaverDidStart then
    print('Screensaver Started')
    closeComms()
    pauseMusic()
  end
end
caffeinateWatcher = hs.caffeinate.watcher.new(caffeinateHandler):start()
