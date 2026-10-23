sub Init()
    m.bgFocus = m.top.findNode("bgFocus")
    m.titleLabel = m.top.findNode("titleLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.valueLabel = m.top.findNode("valueLabel")
    m.checkIcon = m.top.findNode("checkIcon")
    m.chevronLabel = m.top.findNode("chevronLabel")
    m.content = invalid
end sub

sub onFocusChanged()
    if m.bgFocus <> invalid then
        m.bgFocus.opacity = m.top.focusPercent
    end if
end sub

sub onContentChanged()
    if m.content <> invalid then
        m.content.unobserveField("title")
        m.content.unobserveField("description")
        m.content.unobserveField("settingValue")
        m.content.unobserveField("selected")
        m.content.unobserveField("trailing")
    end if

    m.content = m.top.itemContent
    if m.content = invalid then
        m.titleLabel.text = ""
        m.descriptionLabel.text = ""
        m.valueLabel.text = ""
        m.checkIcon.visible = false
        m.chevronLabel.visible = false
        return
    end if

    m.content.observeField("title", "onFieldChanged")
    m.content.observeField("description", "onFieldChanged")
    m.content.observeField("settingValue", "onFieldChanged")
    m.content.observeField("selected", "onFieldChanged")
    m.content.observeField("trailing", "onFieldChanged")

    Refresh()
end sub

sub onFieldChanged()
    Refresh()
end sub

sub Refresh()
    content = m.content
    if content = invalid then
        return
    end if

    m.titleLabel.text = SafeText(content.title)
    m.descriptionLabel.text = SafeText(content.description)
    m.valueLabel.text = SafeText(content.settingValue)

    selected = (content.selected = true)
    if selected then
        m.valueLabel.color = "0x57E6C8FF"
    else
        m.valueLabel.color = "0x7F8DA8FF"
    end if

    trailing = SafeText(content.trailing)
    if trailing = "check" then
        m.checkIcon.visible = selected
        m.chevronLabel.visible = false
    else if trailing = "chevron" then
        m.checkIcon.visible = false
        m.chevronLabel.visible = true
    else
        m.checkIcon.visible = false
        m.chevronLabel.visible = false
    end if
end sub

function SafeText(value as Dynamic) as String
    if value = invalid then
        return ""
    end if
    return value
end function
