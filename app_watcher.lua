function appHandler(appName, eventType, _)
  if (appName == 'zoom.us' or appName == 'Meet' or appName == 'Infra Meet') and eventType == hs.application.watcher.launched then
    setAudioOutput(talkDevice)
  end
end
appWatcher = hs.application.watcher.new(appHandler):start()
