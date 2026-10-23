sub Init()
    m.bgFocus = m.top.findNode("bgFocus")
    m.logo = m.top.findNode("logo")
    m.initialsLabel = m.top.findNode("initialsLabel")
    m.nameLabel = m.top.findNode("nameLabel")
    m.groupLabel = m.top.findNode("groupLabel")
    m.favoriteStar = m.top.findNode("favoriteStar")
    m.content = invalid

    m.logo.observeField("loadStatus", "onLogoStatus")
end sub

sub onFocusChanged()
    if m.bgFocus <> invalid then
        m.bgFocus.opacity = m.top.focusPercent
    end if
end sub

sub onContentChanged()
    content = m.top.itemContent
    if m.content <> invalid then
        m.content.unobserveField("favorite")
    end if
    m.content = content

    if content = invalid then
        m.nameLabel.text = ""
        m.groupLabel.text = ""
        m.logo.uri = ""
        m.logo.visible = false
        m.initialsLabel.visible = false
        m.favoriteStar.visible = false
        return
    end if

    content.observeField("favorite", "onFavoriteChanged")

    m.nameLabel.text = content.title
    m.groupLabel.text = content.description
    m.favoriteStar.visible = (content.favorite = true)

    logoUrl = content.HDPosterUrl
    if logoUrl = invalid then
        logoUrl = ""
    end if

    if logoUrl = "" then
        m.logo.uri = ""
        m.logo.visible = false
        m.initialsLabel.text = MakeInitials(content.title)
        m.initialsLabel.visible = true
    else
        m.logo.uri = logoUrl
        m.logo.visible = true
        m.initialsLabel.visible = false
    end if
end sub

sub onFavoriteChanged()
    if m.content <> invalid then
        m.favoriteStar.visible = (m.content.favorite = true)
    end if
end sub

sub onLogoStatus()
    status = m.logo.loadStatus
    if status = "failed" then
        m.logo.visible = false
        m.initialsLabel.visible = true
    else if status = "ready" then
        m.logo.visible = true
        m.initialsLabel.visible = false
    end if
end sub

function MakeInitials(name as String) as String
    if name = invalid then
        return "TV"
    end if
    initials = ""
    for each word in name.Split(" ")
        word = word.Trim()
        if Len(word) > 0 and Len(initials) < 2 then
            initials = initials + UCase(Left(word, 1))
        end if
    end for
    if initials = "" then
        initials = UCase(Left(name.Trim(), 2))
    end if
    return initials
end function
