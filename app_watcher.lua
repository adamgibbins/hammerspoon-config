function appHandler(appName, eventType, appObject)
  if (appName == 'zoom.us' or appName == 'Hangout Infra') and eventType == hs.application.watcher.launched then
    setAudioOutput(talkDevice)
  end
end
appWatcher = hs.application.watcher.new(appHandler):start()
