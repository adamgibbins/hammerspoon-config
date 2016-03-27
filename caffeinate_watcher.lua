function caffeinateHandler(event)
  printMessage('caffeinateWatcher triggered')
  -- Mute sounds on suspend, or if shutting down - to stop the startup chime
  if event == hs.caffeinate.watcher.systemWillSleep or event == hs.caffeinate.watcher.systemWillPowerOff then
    printMessage('Sleeping')
    hs.audiodevice.defaultOutputDevice():setMuted(true)
    closeComms()
    pauseMusic()
  end

  if event == hs.caffeinate.watcher.screensaverDidStart then
    printMessage('Screensaver Started')
    closeComms()
    pauseMusic()
  end
end
caffeinateWatcher = hs.caffeinate.watcher.new(caffeinateHandler):start()
