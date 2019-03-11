spoon.SpoonInstall:andUse('MicMute')
spoon.MicMute:bindHotkeys({ toggle = {modHyper, '`'}}, 0.75)

function setMusicDevice()
  local musicDevice

  for _, device in pairs(musicDevices) do
    if hs.audiodevice.findOutputByName(device) then
      musicDevice = device
      break
    end
  end

  setAudioOutput(musicDevice)
end

-- Configure audio output device, unless it doesn't exist - then notify
function setAudioOutput(device)
  local hardwareDevice = hs.audiodevice.findOutputByName(device)
  local currentDevice = hs.audiodevice.defaultOutputDevice()

  if hardwareDevice then
    if currentDevice ~= hardwareDevice then
      hardwareDevice:setDefaultOutputDevice()
      notify('Audio Output', 'Switched to ' .. device)

      -- talkDevice is replugged often, when plugged in it starts on mute - so turn it up to a reasonable volume
      if device == talkDevice then
        hardwareDevice:setVolume(40)
        setAudioInput(talkDevice)
      end
    end
  else
    notify('Audio Output', 'Tried to set invalid audio output! Device: ' .. device)
    print('Tried to set invalid audio output: ' .. device)
  end
end

-- Configure audio input device, unless it doesn't exist - then notify
function setAudioInput(device)
  local hardwareDevice = hs.audiodevice.findInputByName(device)
  local currentDevice = hs.audiodevice.defaultInputDevice()

  if hardwareDevice then
    if currentDevice ~= hardwareDevice then
      hardwareDevice:setDefaultInputDevice()
      notify('Audio Input', 'Switched to ' .. device)
    end
  else
    notify('Audio Alert', device .. ' is missing!')
  end
end

-- Toggle between the two audio devices
function toggleAudio()
  local currentDevice = hs.audiodevice.defaultOutputDevice()

  if currentDevice:name() == talkDevice then
    setMusicDevice()
  else
    setAudioOutput(talkDevice)
    setAudioInput(talkDevice)
  end
end

