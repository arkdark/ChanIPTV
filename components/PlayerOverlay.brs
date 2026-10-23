sub Init()
    m.top.width = 1280
    m.top.height = 720
    m.top.focusable = true

    m.video = m.top.findNode("video")
    m.channelLogo = m.top.findNode("channelLogo")
    m.logoInitials = m.top.findNode("logoInitials")
    m.channelName = m.top.findNode("channelName")
    m.channelGroup = m.top.findNode("channelGroup")
    m.favoriteStar = m.top.findNode("favoriteStar")
    m.statusPanel = m.top.findNode("statusPanel")
    m.statusLabel = m.top.findNode("statusLabel")
    m.positionLabel = m.top.findNode("positionLabel")

    m.video.observeField("state", "onVideoState")
    m.channelLogo.observeField("loadStatus", "onLogoStatus")
end sub

sub onChannelChanged()
    channel = m.top.channel
    if channel = invalid then
        m.channelName.text = ""
        m.channelGroup.text = ""
        m.channelLogo.visible = false
        m.logoInitials.visible = false
        return
    end if

    m.channelName.text = SafeValue(channel.name)
    m.channelGroup.text = SafeValue(channel.group)

    logoUrl = SafeValue(channel.logo)
    if logoUrl = "" then
        m.channelLogo.uri = ""
        m.channelLogo.visible = false
        m.logoInitials.text = MakeInitials(channel.name)
        m.logoInitials.visible = true
    else
        m.channelLogo.uri = logoUrl
        m.channelLogo.visible = true
        m.logoInitials.visible = false
    end if

    if m.top.playing then
        StartPlayback()
    end if
end sub

sub onFavoriteChanged()
    m.favoriteStar.visible = (m.top.favorite = true)
end sub

sub onPlayingChanged()
    if m.top.playing then
        StartPlayback()
    else
        StopPlayback()
    end if
end sub

sub onPositionChanged()
    m.positionLabel.text = SafeValue(m.top.position)
end sub

sub StartPlayback()
    channel = m.top.channel
    if channel = invalid then
        return
    end if

    url = SafeValue(channel.url)
    if url = "" then
        ShowStatus("Este canal não possui uma transmissão disponível.")
        m.video.visible = false
        return
    end if

    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.title = SafeValue(channel.name)
    format = DetectFormat(url)
    if format <> "" then
        content.streamFormat = format
    end if

    m.video.content = content
    m.video.visible = true
    m.video.control = "play"
    m.statusPanel.visible = false
end sub

sub StopPlayback()
    m.video.control = "stop"
    m.video.visible = false
    m.video.content = invalid
    m.statusPanel.visible = false
end sub

sub onVideoState()
    state = m.video.state
    if state = "buffering" then
        ShowStatus("Carregando transmissão...")
    else if state = "playing" then
        m.statusPanel.visible = false
    else if state = "finished" then
        ShowStatus("Transmissão encerrada. Use as setas esquerda e direita para trocar de canal.")
    else if state = "error" then
        print "ChanIPTV player error "; m.video.errorCode; " "; m.video.errorMsg
        ShowStatus("Não foi possível reproduzir este canal agora." + Chr(10) + "Use as setas esquerda e direita para tentar outro.")
    end if
end sub

sub ShowStatus(message as String)
    m.statusLabel.text = message
    m.statusPanel.visible = true
end sub

sub onLogoStatus()
    status = m.channelLogo.loadStatus
    if status = "failed" then
        m.channelLogo.visible = false
        m.logoInitials.visible = true
    else if status = "ready" then
        m.channelLogo.visible = true
        m.logoInitials.visible = false
    end if
end sub

function DetectFormat(url as String) as String
    low = LCase(url)
    if Instr(1, low, ".m3u8") > 0 then
        return "hls"
    else if Instr(1, low, ".mpd") > 0 then
        return "dash"
    else if Instr(1, low, ".mp4") > 0 then
        return "mp4"
    else if Instr(1, low, ".mkv") > 0 then
        return "mkv"
    end if
    return ""
end function

function SafeValue(value as Dynamic) as String
    if value = invalid then
        return ""
    end if
    return value
end function

function MakeInitials(name as Dynamic) as String
    text = SafeValue(name)
    if text = "" then
        return "TV"
    end if
    initials = ""
    for each word in text.Split(" ")
        word = word.Trim()
        if Len(word) > 0 and Len(initials) < 2 then
            initials = initials + UCase(Left(word, 1))
        end if
    end for
    return initials
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then
        return false
    end if

    lower = LCase(key)
    if lower = "back" then
        m.top.command = "close"
        return true
    else if lower = "left" then
        m.top.command = "prev"
        return true
    else if lower = "right" then
        m.top.command = "next"
        return true
    else if lower = "*" or lower = "options" then
        m.top.command = "toggleFavorite"
        return true
    end if
    return false
end function
