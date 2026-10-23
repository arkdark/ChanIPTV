sub Init()
    m.bgFocus = m.top.findNode("bgFocus")
    m.titleLabel = m.top.findNode("titleLabel")
    m.countLabel = m.top.findNode("countLabel")
    m.chevronLabel = m.top.findNode("chevronLabel")
    m.favoriteStar = m.top.findNode("favoriteStar")
end sub

sub onFocusChanged()
    if m.bgFocus <> invalid then
        m.bgFocus.opacity = m.top.focusPercent
    end if
end sub

sub onContentChanged()
    content = m.top.itemContent
    if content = invalid then
        m.titleLabel.text = ""
        m.countLabel.text = ""
        return
    end if

    m.titleLabel.text = content.title
    m.countLabel.text = content.description

    if content.categoryType = "favorites" then
        m.favoriteStar.visible = true
        m.chevronLabel.visible = false
    else
        m.favoriteStar.visible = false
        m.chevronLabel.visible = true
    end if
end sub
