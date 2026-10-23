sub Init()
    m.top.width = 150
    m.top.height = 44
    m.top.focusable = true

    m.normalPoster = m.top.findNode("normalPoster")
    m.activePoster = m.top.findNode("activePoster")
    m.focusPoster = m.top.findNode("focusPoster")
    m.buttonLabel = m.top.findNode("buttonLabel")

    RefreshVisuals()
end sub

sub onTextChanged()
    if m.buttonLabel <> invalid then
        m.buttonLabel.text = m.top.text
    end if
end sub

sub onActiveChanged()
    RefreshVisuals()
end sub

sub onFocusedChanged()
    RefreshVisuals()
end sub

sub RefreshVisuals()
    if m.focusPoster = invalid then
        return
    end if

    if m.top.focused then
        m.focusPoster.opacity = 1.0
        m.buttonLabel.color = "0x06101EFF"
    else
        m.focusPoster.opacity = 0.0
        if m.top.active then
            m.buttonLabel.color = "0x57E6C8FF"
        else
            m.buttonLabel.color = "0xE8EEF8FF"
        end if
    end if

    if m.top.active and not m.top.focused then
        m.activePoster.opacity = 0.22
    else
        m.activePoster.opacity = 0.0
    end if

    m.buttonLabel.text = m.top.text
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then
        return false
    end if
    k = LCase(key)
    if k = "ok" then
        m.top.trigger = m.top.trigger + 1
        return true
    end if
    return false
end function
