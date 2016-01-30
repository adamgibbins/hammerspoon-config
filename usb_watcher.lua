function usbHandler(data)
  if data['productName'] == 'ScanSnap S1100' then
    local event = data['eventType']

    if event == 'added' then
      hs.application.launchOrFocus('ScanSnap Manager')
    elseif event == 'removed' then
      hs.appfinder.appFromName('ScanSnap Manager'):kill()
    end
  end
end
usbWatcher = hs.usb.watcher.new(usbHandler)
usbWatcher:start()
