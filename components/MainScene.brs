sub Init()
    m.background = m.top.findNode("background")
    m.viewTitle = m.top.findNode("viewTitle")
    m.viewSubtitle = m.top.findNode("viewSubtitle")
    m.footer = m.top.findNode("footer")

    m.navCategories = m.top.findNode("navCategories")
    m.navFavorites = m.top.findNode("navFavorites")
    m.navSearch = m.top.findNode("navSearch")
    m.navSettings = m.top.findNode("navSettings")

    m.categoryGrid = m.top.findNode("categoryGrid")
    m.channelGrid = m.top.findNode("channelGrid")
    m.settingGrid = m.top.findNode("settingGrid")

    m.loadingPanel = m.top.findNode("loadingPanel")
    m.loadingSpinner = m.top.findNode("loadingSpinner")
    m.loadingTitle = m.top.findNode("loadingTitle")
    m.loadingDetail = m.top.findNode("loadingDetail")

    m.errorPanel = m.top.findNode("errorPanel")
    m.errorTitle = m.top.findNode("errorTitle")
    m.errorMessage = m.top.findNode("errorMessage")
    m.errorHint = m.top.findNode("errorHint")
    m.retryButton = m.top.findNode("retryButton")

    m.emptyPanel = m.top.findNode("emptyPanel")
    m.emptyTitle = m.top.findNode("emptyTitle")
    m.emptyMessage = m.top.findNode("emptyMessage")

    m.player = m.top.findNode("player")

    m.view = "categories"
    m.categoryFilter = "all"
    m.currentGroup = ""
    m.searchQuery = ""
    m.allChannels = []
    m.visibleChannels = []
    m.categories = []
    m.favorites = LoadFavorites()
    m.playlistUrl = GetConfiguredUrl()
    m.pendingUrl = m.playlistUrl
    m.adultFilter = IsAdultFilterOn()
    m.filteredCount = 0
    m.rawSkipped = 0
    m.catalogDirty = true
    m.loading = false
    m.task = invalid
    m.appendTimer = invalid
    m.channelIndex = 0
    m.contentRoot = invalid
    m.playingList = []
    m.playingIndex = 0
    m.dialogNode = invalid
    m.initialFocusTimer = invalid

    m.categoryGrid.observeField("itemSelected", "onCategorySelected")
    m.channelGrid.observeField("itemSelected", "onChannelSelected")
    m.settingGrid.observeField("itemSelected", "onSettingSelected")
    m.player.observeField("command", "onPlayerCommand")

    m.navCategories.observeField("trigger", "onNavCategories")
    m.navFavorites.observeField("trigger", "onNavFavorites")
    m.navSearch.observeField("trigger", "onNavSearch")
    m.navSettings.observeField("trigger", "onNavSettings")
    m.retryButton.observeField("trigger", "onRetry")

    SetupFocusTimer()
    m.top.setFocus(true)

    if m.playlistUrl <> "" and IsHttpUrl(m.playlistUrl) then
        LoadPlaylist(m.playlistUrl)
    else
        ShowSettings()
    end if

    SetupInitialFocus()
end sub

' ---------------------------------------------------------------------------
' Foco inicial e navegação geral
' ---------------------------------------------------------------------------

sub SetupInitialFocus()
    timer = CreateObject("roSGNode", "Timer")
    timer.duration = 0.25
    timer.repeat = false
    timer.observeField("fire", "onInitialFocus")
    m.top.appendChild(timer)
    m.initialFocusTimer = timer
    timer.control = "start"
end sub

sub onInitialFocus()
    if m.initialFocusTimer <> invalid then
        m.initialFocusTimer.control = "stop"
        m.initialFocusTimer = invalid
    end if
    FocusCurrentView()
end sub

sub FocusCurrentView()
    if m.player <> invalid and m.player.visible then
        return
    end if

    if m.loading then
        m.navCategories.setFocus(true)
        return
    end if

    if m.view = "settings" and m.settingGrid.visible then
        m.settingGrid.setFocus(true)
        return
    end if

    if m.view = "channels" and m.channelGrid.visible then
        m.channelGrid.setFocus(true)
        return
    end if

    if m.view = "categories" and m.categoryGrid.visible then
        m.categoryGrid.setFocus(true)
        return
    end if

    if m.view = "error" and m.errorPanel.visible then
        m.retryButton.setFocus(true)
        return
    end if

    if m.view = "settings" then
        m.navSettings.setFocus(true)
    else if m.view = "channels" then
        if m.categoryFilter = "favorites" then
            m.navFavorites.setFocus(true)
        else if m.categoryFilter = "search" then
            m.navSearch.setFocus(true)
        else
            m.navCategories.setFocus(true)
        end if
    else
        m.navCategories.setFocus(true)
    end if
end sub

sub MoveHeaderFocus(delta as Integer)
    if m.navCategories.hasFocus() then
        if delta > 0 then
            m.navFavorites.setFocus(true)
        else
            m.navSettings.setFocus(true)
        end if
    else if m.navFavorites.hasFocus() then
        if delta > 0 then
            m.navSearch.setFocus(true)
        else
            m.navCategories.setFocus(true)
        end if
    else if m.navSearch.hasFocus() then
        if delta > 0 then
            m.navSettings.setFocus(true)
        else
            m.navFavorites.setFocus(true)
        end if
    else if m.navSettings.hasFocus() then
        if delta > 0 then
            m.navCategories.setFocus(true)
        else
            m.navSearch.setFocus(true)
        end if
    else
        m.navCategories.setFocus(true)
    end if
end sub

function HeaderHasFocus() as Boolean
    return m.navCategories.hasFocus() or m.navFavorites.hasFocus() or m.navSearch.hasFocus() or m.navSettings.hasFocus()
end function

' ---------------------------------------------------------------------------
' Foco dos botões do cabeçalho
' ---------------------------------------------------------------------------

sub SetupFocusTimer()
    timer = CreateObject("roSGNode", "Timer")
    timer.duration = 0.08
    timer.repeat = true
    timer.observeField("fire", "onFocusTick")
    m.top.appendChild(timer)
    m.focusTimer = timer
    timer.control = "start"
end sub

sub onFocusTick()
    focused = m.navCategories.hasFocus()
    if m.navCategories.focused <> focused then
        m.navCategories.focused = focused
    end if

    focused = m.navFavorites.hasFocus()
    if m.navFavorites.focused <> focused then
        m.navFavorites.focused = focused
    end if

    focused = m.navSearch.hasFocus()
    if m.navSearch.focused <> focused then
        m.navSearch.focused = focused
    end if

    focused = m.navSettings.hasFocus()
    if m.navSettings.focused <> focused then
        m.navSettings.focused = focused
    end if

    focused = m.retryButton.hasFocus()
    if m.retryButton.focused <> focused then
        m.retryButton.focused = focused
    end if
end sub

' ---------------------------------------------------------------------------
' Carregamento da lista
' ---------------------------------------------------------------------------

sub LoadPlaylist(url as String)
    url = url.Trim()
    if not IsHttpUrl(url) then
        ShowError("URL inválida", "A lista precisa começar com http:// ou https://.")
        return
    end if

    if m.task <> invalid then
        m.task.unobserveField("result")
        m.task.control = "stop"
        m.task = invalid
    end if

    m.pendingUrl = url
    ShowLoading(url)

    task = CreateObject("roSGNode", "PlaylistTask")
    if task = invalid then
        ShowError("Falha ao carregar", "Não foi possível iniciar o carregador da lista.")
        return
    end if

    task.observeField("result", "onPlaylistResult")
    m.task = task
    task.url = url
    task.control = "run"
end sub

sub onPlaylistResult()
    task = m.task
    if task = invalid then
        return
    end if

    result = task.result
    task.unobserveField("result")
    m.task = invalid

    if result = invalid then
        ShowError("Falha inesperada", "O carregador não devolveu nenhum resultado.")
        return
    end if

    if result.ok <> true then
        message = result.error
        if message = invalid or message = "" then
            message = "Não foi possível baixar a lista."
        end if
        ShowError("Não foi possível carregar a lista", message)
        return
    end if

    m.allChannels = result.channels
    m.rawSkipped = result.skipped
    if m.rawSkipped = invalid then
        m.rawSkipped = 0
    end if
    m.playlistUrl = m.pendingUrl
    SaveConfiguredUrl(m.playlistUrl)
    m.catalogDirty = true
    ShowCategories()
end sub

sub CancelLoad()
    if m.task <> invalid then
        m.task.unobserveField("result")
        m.task.control = "stop"
        m.task = invalid
    end if

    if m.allChannels.Count() > 0 then
        ShowCategories()
    else
        ShowError("Carregamento cancelado", "Use Tentar para baixar a lista novamente.")
    end if
end sub

' ---------------------------------------------------------------------------
' Categorias e canais
' ---------------------------------------------------------------------------

function BuildChannelList(filterType as String, group as String, query as String) as Object
    list = []
    for each ch in m.allChannels
        include = true

        if m.adultFilter and ch.adult = true then
            include = false
        end if

        if include and filterType = "favorites" then
            if not m.favorites.DoesExist(ch.id) then
                include = false
            end if
        end if

        if include and filterType = "group" then
            if ch.group <> group then
                include = false
            end if
        end if

        if include and filterType = "search" then
            if Instr(1, LCase(ch.name), LCase(query)) = 0 then
                include = false
            end if
        end if

        if include then
            list.Push(ch)
        end if
    end for
    return list
end function

function FilteredChannels() as Object
    return BuildChannelList("all", "", "")
end function

sub RebuildCategories()
    filtered = FilteredChannels()
    m.filteredCount = filtered.Count()

    groupCounts = {}
    groupOrder = []
    for each ch in filtered
        groupName = ch.group
        if groupName = invalid or groupName = "" then
            groupName = "Outros"
        end if

        if groupCounts.DoesExist(groupName) then
            groupCounts[groupName] = groupCounts[groupName] + 1
        else
            groupCounts[groupName] = 1
            groupOrder.Push(groupName)
        end if
    end for

    if groupOrder.Count() > 1 then
        groupOrder.Sort()
    end if

    favoriteCount = 0
    for each ch in filtered
        if m.favorites.DoesExist(ch.id) then
            favoriteCount = favoriteCount + 1
        end if
    end for

    m.categories = []
    nodes = []

    allCategory = { title: "Todos os canais", kind: "all", key: "", count: m.filteredCount }
    m.categories.Push(allCategory)
    nodes.Push(MakeCategoryNode(allCategory))

    favoritesCategory = { title: "Favoritos", kind: "favorites", key: "", count: favoriteCount }
    m.categories.Push(favoritesCategory)
    nodes.Push(MakeCategoryNode(favoritesCategory))

    for each groupName in groupOrder
        category = { title: groupName, kind: "group", key: groupName, count: groupCounts[groupName] }
        m.categories.Push(category)
        nodes.Push(MakeCategoryNode(category))
    end for

    root = CreateObject("roSGNode", "ContentNode")
    root.AppendChildren(nodes)
    m.categoryGrid.content = root
    m.catalogDirty = false
end sub

function MakeCategoryNode(category as Object) as Object
    node = CreateObject("roSGNode", "CategoryContent")
    node.title = TruncateText(category.title, 24)
    node.description = CountText(category.count)
    node.categoryType = category.kind
    node.categoryKey = category.key
    return node
end function

sub ShowCategories()
    StopAppend()
    HidePanels()
    m.loading = false
    m.view = "categories"
    m.categoryFilter = "all"
    m.currentGroup = ""
    m.searchQuery = ""

    if m.playlistUrl = "" or not IsHttpUrl(m.playlistUrl) then
        m.viewTitle.text = "Nenhuma lista"
        m.viewSubtitle.text = "Adicione a URL da sua lista M3U nas Ajustes"
        UpdateNav("categories")
        SetFooter("↑  ir para Ajustes     OK  em Ajustes     Back  sair")
        ShowEmpty("Adicione sua própria lista", "Vá em Ajustes > URL da lista e informe uma URL http:// ou https://.")
        m.navSettings.setFocus(true)
        return
    end if

    if m.allChannels.Count() = 0 then
        ShowError("Lista vazia ou sem canais", "Verifique a URL nas Ajustes ou tente recarregar a lista.")
        return
    end if

    if m.catalogDirty then
        RebuildCategories()
    end if

    m.categoryGrid.visible = true

    m.viewTitle.text = "Categorias"
    subtitle = CountText(m.filteredCount) + " • " + FormatCount(m.categories.Count() - 2) + " grupos"
    if m.rawSkipped > 0 then
        subtitle = subtitle + " • " + FormatCount(m.rawSkipped) + " links ignorados"
    end if
    m.viewSubtitle.text = subtitle

    UpdateNav("categories")
    SetFooter("OK  abrir categoria     ↑  cabeçalho     Setas  navegar     Back  sair")

    if m.categories.Count() = 0 then
        ShowEmpty("Lista vazia", "Nenhum canal compatível foi encontrado.")
        m.navCategories.setFocus(true)
        return
    end if

    m.categoryGrid.setFocus(true)
end sub

sub ShowChannels(filterType as String, group as String, query as String)
    StopAppend()
    HidePanels()
    m.loading = false
    m.view = "channels"
    m.categoryFilter = filterType
    m.currentGroup = group
    m.searchQuery = query

    list = BuildChannelList(filterType, group, query)
    m.visibleChannels = list

    if filterType = "favorites" then
        m.viewTitle.text = "Favoritos"
        m.viewSubtitle.text = CountText(list.Count()) + " marcados por você"
        UpdateNav("favorites")
    else if filterType = "search" then
        m.viewTitle.text = "Resultados da busca"
        m.viewSubtitle.text = CountText(list.Count()) + " para " + Chr(34) + query + Chr(34)
        UpdateNav("search")
    else if filterType = "group" then
        m.viewTitle.text = group
        m.viewSubtitle.text = CountText(list.Count())
        UpdateNav("categories")
    else
        m.viewTitle.text = "Todos os canais"
        m.viewSubtitle.text = CountText(list.Count()) + " • " + CurrentListName(m.playlistUrl)
        UpdateNav("categories")
    end if

    SetFooter("OK  assistir     ↑  cabeçalho     Back  voltar     *  favoritar durante a reprodução")

    if list.Count() = 0 then
        if filterType = "favorites" then
            ShowEmpty("Nenhum favorito ainda", "Abra um canal e pressione * para adicionar aos favoritos.")
            m.navFavorites.setFocus(true)
        else if filterType = "search" then
            ShowEmpty("Nada encontrado", "Não encontramos canais com esse nome. Tente outra busca.")
            m.navSearch.setFocus(true)
        else
            ShowEmpty("Nenhum canal disponível", "Esta categoria não possui canais na lista atual.")
            m.navCategories.setFocus(true)
        end if
        return
    end if

    m.channelGrid.visible = true
    StartChannelContent(list)
    m.channelGrid.setFocus(true)
end sub

sub StartChannelContent(list as Object)
    StopAppend()
    m.visibleChannels = list
    m.channelIndex = 0

    root = CreateObject("roSGNode", "ContentNode")
    m.contentRoot = root
    m.channelGrid.content = root

    if m.appendTimer = invalid then
        timer = CreateObject("roSGNode", "Timer")
        timer.duration = 0.02
        timer.repeat = true
        timer.observeField("fire", "AppendChannelChunk")
        m.top.appendChild(timer)
        m.appendTimer = timer
    end if

    m.appendTimer.control = "start"
    AppendChannelChunk()
end sub

sub StopAppend()
    if m.appendTimer <> invalid then
        m.appendTimer.control = "stop"
    end if
    m.channelIndex = 0
end sub

sub AppendChannelChunk()
    total = m.visibleChannels.Count()
    if m.channelIndex >= total then
        if m.appendTimer <> invalid then
            m.appendTimer.control = "stop"
        end if
        return
    end if

    endIndex = m.channelIndex + 119
    if endIndex > total - 1 then
        endIndex = total - 1
    end if

    nodes = []
    for i = m.channelIndex to endIndex
        ch = m.visibleChannels[i]
        node = CreateObject("roSGNode", "ChannelContent")
        node.title = ch.name
        node.description = ShortGroupName(ch.group)
        node.url = ch.url
        node.HDPosterUrl = ch.logo
        node.channelId = ch.id
        node.groupName = ch.group
        node.favorite = m.favorites.DoesExist(ch.id)
        nodes.Push(node)
    end for

    if m.contentRoot <> invalid then
        m.contentRoot.AppendChildren(nodes)
    end if

    m.channelIndex = endIndex + 1
    if m.channelIndex >= total and m.appendTimer <> invalid then
        m.appendTimer.control = "stop"
    end if
end sub

sub onCategorySelected()
    index = m.categoryGrid.itemSelected
    if index < 0 or index >= m.categories.Count() then
        return
    end if

    category = m.categories[index]
    if category.kind = "all" then
        ShowChannels("all", "", "")
    else if category.kind = "favorites" then
        ShowChannels("favorites", "", "")
    else
        ShowChannels("group", category.key, "")
    end if
end sub

sub onChannelSelected()
    index = m.channelGrid.itemSelected
    if index < 0 or index >= m.visibleChannels.Count() then
        return
    end if

    m.playingList = m.visibleChannels
    m.playingIndex = index
    OpenPlayer()
end sub

' ---------------------------------------------------------------------------
' Ajustes
' ---------------------------------------------------------------------------

sub ShowSettings()
    StopAppend()
    HidePanels()
    m.loading = false
    m.view = "settings"

    m.viewTitle.text = "Ajustes"
    m.viewSubtitle.text = "Adicione sua URL da lista M3U/M3U8 e defina as preferências"
    UpdateNav("settings")
    SetFooter("OK  selecionar     ↑  cabeçalho     Back  voltar")

    BuildSettings()
    m.settingGrid.visible = true
    m.settingGrid.setFocus(true)
end sub

sub BuildSettings()
    nodes = []
    currentPreset = PresetForUrl(m.playlistUrl)

    customSelected = (currentPreset = invalid)
    customDescription = "Informe a URL completa da sua lista M3U ou M3U8 (http:// ou https://)"
    if m.playlistUrl <> invalid and m.playlistUrl <> "" then
        customDescription = TruncateText(m.playlistUrl, 86)
    end if
    customValue = "Editar"
    if customSelected and m.playlistUrl <> "" then
        customValue = "Atual"
    end if
    nodes.Push(MakeSettingNode("URL da lista", customDescription, "customUrl", "custom", "", customValue, customSelected and m.playlistUrl <> "", "check"))

    adultValue = "Desativado"
    if m.adultFilter then
        adultValue = "Ativado"
    end if
    nodes.Push(MakeSettingNode("Filtrar conteúdo adulto", "Oculta canais e grupos adultos da lista", "adult", "adult", "", adultValue, m.adultFilter, "check"))

    reloadDesc = "Baixar novamente a lista informada"
    if m.playlistUrl <> "" then
        reloadDesc = "Baixar novamente " + CurrentListName(m.playlistUrl)
    end if
    nodes.Push(MakeSettingNode("Recarregar lista", reloadDesc, "reload", "reload", "", "Agora", false, "chevron"))
    nodes.Push(MakeSettingNode("Sobre o ChanIPTV", "Versão 1.0 • Player M3U genérico para Roku", "about", "about", "", "Ver", false, "chevron"))

    root = CreateObject("roSGNode", "ContentNode")
    root.AppendChildren(nodes)
    m.settingGrid.content = root
end sub

function MakeSettingNode(title as String, description as String, settingType as String, key as String, url as String, value as String, selected as Boolean, trailing as String) as Object
    node = CreateObject("roSGNode", "SettingContent")
    node.title = title
    node.description = description
    node.settingType = settingType
    node.settingKey = key
    node.settingUrl = url
    node.settingValue = value
    node.selected = selected
    node.trailing = trailing
    return node
end function

sub onSettingSelected()
    index = m.settingGrid.itemSelected
    root = m.settingGrid.content
    if root = invalid then
        return
    end if
    if index < 0 or index >= root.GetChildCount() then
        return
    end if

    node = root.GetChild(index)
    if node = invalid then
        return
    end if

    settingType = node.settingType
    if settingType = "preset" then
        LoadPlaylist(node.settingUrl)
    else if settingType = "customUrl" then
        ShowCustomUrlDialog()
    else if settingType = "adult" then
        ToggleAdultFilter(index)
    else if settingType = "reload" then
        LoadPlaylist(m.playlistUrl)
    else if settingType = "about" then
        ShowAbout()
    end if
end sub

sub ToggleAdultFilter(index as Integer)
    m.adultFilter = not m.adultFilter
    SaveAdultFilter(m.adultFilter)
    m.catalogDirty = true

    root = m.settingGrid.content
    if root <> invalid and index >= 0 and index < root.GetChildCount() then
        node = root.GetChild(index)
        if node <> invalid then
            node.selected = m.adultFilter
            if m.adultFilter then
                node.settingValue = "Ativado"
                m.viewSubtitle.text = "Filtro de conteúdo adulto ativado"
            else
                node.settingValue = "Desativado"
                m.viewSubtitle.text = "Filtro de conteúdo adulto desativado"
            end if
        end if
    end if
end sub

' ---------------------------------------------------------------------------
' Player
' ---------------------------------------------------------------------------

sub OpenPlayer()
    if m.playingList.Count() = 0 then
        return
    end if
    if m.playingIndex < 0 or m.playingIndex >= m.playingList.Count() then
        m.playingIndex = 0
    end if

    ch = m.playingList[m.playingIndex]
    m.player.channel = ch
    m.player.favorite = m.favorites.DoesExist(ch.id)
    m.player.position = "Canal " + Str(m.playingIndex + 1).Trim() + " de " + FormatCount(m.playingList.Count())
    m.player.visible = true
    m.player.playing = true
    m.player.setFocus(true)
end sub

sub ClosePlayer()
    lastIndex = m.playingIndex

    m.player.playing = false
    m.player.visible = false
    m.player.channel = invalid
    m.player.position = ""

    m.playingList = []
    m.playingIndex = 0

    if m.view = "channels" then
        if lastIndex >= 0 and lastIndex < m.visibleChannels.Count() then
            m.channelGrid.jumpToItem = lastIndex
        end if
        m.channelGrid.setFocus(true)
    else
        m.navCategories.setFocus(true)
    end if
end sub

sub onPlayerCommand()
    command = m.player.command
    if command = "" then
        return
    end if
    m.player.command = ""

    if command = "close" then
        ClosePlayer()
    else if command = "next" then
        StepChannel(1)
    else if command = "prev" then
        StepChannel(-1)
    else if command = "toggleFavorite" then
        TogglePlayingFavorite()
    end if
end sub

sub StepChannel(delta as Integer)
    total = m.playingList.Count()
    if total = 0 then
        return
    end if

    m.playingIndex = m.playingIndex + delta
    if m.playingIndex < 0 then
        m.playingIndex = total - 1
    else if m.playingIndex >= total then
        m.playingIndex = 0
    end if

    ch = m.playingList[m.playingIndex]
    m.player.channel = ch
    m.player.favorite = m.favorites.DoesExist(ch.id)
    m.player.position = "Canal " + Str(m.playingIndex + 1).Trim() + " de " + FormatCount(total)
    m.player.playing = true
end sub

sub TogglePlayingFavorite()
    if m.playingList.Count() = 0 then
        return
    end if

    ch = m.playingList[m.playingIndex]
    favorite = not m.favorites.DoesExist(ch.id)

    if favorite then
        m.favorites[ch.id] = true
    else
        m.favorites.Delete(ch.id)
    end if

    SaveFavorites(m.favorites)
    m.catalogDirty = true
    m.player.favorite = favorite
    UpdateFavoriteInGrid(ch.id, favorite)
end sub

sub UpdateFavoriteInGrid(channelId as String, favorite as Boolean)
    root = m.channelGrid.content
    if root = invalid then
        return
    end if

    for i = 0 to m.visibleChannels.Count() - 1
        ch = m.visibleChannels[i]
        if ch.id = channelId then
            if i < root.GetChildCount() then
                node = root.GetChild(i)
                if node <> invalid then
                    node.favorite = favorite
                end if
            end if
            exit for
        end if
    end for
end sub

' ---------------------------------------------------------------------------
' Navegação e cabeçalho
' ---------------------------------------------------------------------------

sub onNavCategories()
    if m.loading then
        return
    end if
    ShowCategories()
end sub

sub onNavFavorites()
    if m.loading then
        return
    end if
    ShowChannels("favorites", "", "")
end sub

sub onNavSearch()
    if m.loading then
        return
    end if
    ShowSearchDialog()
end sub

sub onNavSettings()
    if m.loading then
        return
    end if
    ShowSettings()
end sub

sub onRetry()
    if m.loading then
        return
    end if
    if m.playlistUrl = "" or not IsHttpUrl(m.playlistUrl) then
        ShowCustomUrlDialog()
        return
    end if
    if m.pendingUrl <> "" and IsHttpUrl(m.pendingUrl) then
        LoadPlaylist(m.pendingUrl)
    else
        LoadPlaylist(m.playlistUrl)
    end if
end sub

sub UpdateNav(viewName as String)
    m.navCategories.active = false
    m.navFavorites.active = false
    m.navSearch.active = false
    m.navSettings.active = false

    if viewName = "categories" then
        m.navCategories.active = true
    else if viewName = "favorites" then
        m.navFavorites.active = true
    else if viewName = "search" then
        m.navSearch.active = true
    else if viewName = "settings" then
        m.navSettings.active = true
    end if
end sub

sub SetFooter(text as String)
    m.footer.text = text
end sub

' ---------------------------------------------------------------------------
' Estados de tela
' ---------------------------------------------------------------------------

sub HidePanels()
    m.categoryGrid.visible = false
    m.channelGrid.visible = false
    m.settingGrid.visible = false
    m.loadingPanel.visible = false
    m.errorPanel.visible = false
    m.emptyPanel.visible = false

    m.channelGrid.content = invalid
    m.contentRoot = invalid
end sub

sub ShowLoading(url as String)
    m.loading = true
    StopAppend()
    HidePanels()

    m.loadingPanel.visible = true
    m.loadingSpinner.visible = true
    m.loadingTitle.text = "Carregando " + CurrentListName(url)
    m.loadingDetail.text = "Baixando e organizando os canais. Isso pode levar alguns segundos."

    m.viewTitle.text = "Carregando..."
    m.viewSubtitle.text = "Preparando sua lista de canais"
    UpdateNav("none")
    SetFooter("Back  cancelar")

    m.navCategories.setFocus(true)
end sub

sub ShowError(title as String, message as String)
    m.loading = false
    StopAppend()
    HidePanels()

    if message = invalid or message = "" then
        message = "Tente novamente em alguns instantes."
    end if

    m.errorTitle.text = title
    m.errorMessage.text = message
    m.errorHint.text = "Use Tentar para baixar de novo ou abra Ajustes para trocar/informar a lista."

    m.view = "error"
    m.viewTitle.text = "Não foi possível carregar"
    m.viewSubtitle.text = "Verifique sua conexão ou a URL da lista"
    UpdateNav("none")
    SetFooter("↑  ir para Ajustes     OK  tentar novamente     Back  voltar")

    m.errorPanel.visible = true
    m.retryButton.setFocus(true)
end sub

sub ShowEmpty(title as String, message as String)
    HidePanels()
    m.emptyPanel.visible = true
    m.emptyTitle.text = title
    m.emptyMessage.text = message
end sub

' ---------------------------------------------------------------------------
' Diálogos
' ---------------------------------------------------------------------------

sub ShowSearchDialog()
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    dialog.title = "Buscar canal"
    dialog.message = ["Digite parte do nome do canal que você procura."]
    dialog.buttons = ["Cancelar", "Buscar"]
    dialog.text = ""
    dialog.observeField("buttonSelected", "onSearchDialogClosed")

    m.dialogNode = dialog
    m.top.dialog = dialog
end sub

sub onSearchDialogClosed()
    dialog = m.dialogNode
    if dialog = invalid then
        return
    end if

    selected = dialog.buttonSelected
    query = dialog.text
    query = query.Trim()
    m.top.dialog = invalid
    m.dialogNode = invalid

    if selected = 1 and query <> "" then
        ShowChannels("search", "", query)
    end if
end sub

sub ShowCustomUrlDialog()
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    dialog.title = "URL da lista M3U"
    dialog.message = ["Cole o endereço completo da lista M3U ou M3U8.", "Apenas endereços http:// e https:// são aceitos."]
    dialog.buttons = ["Cancelar", "Carregar"]
    dialog.text = m.playlistUrl
    dialog.observeField("buttonSelected", "onUrlDialogClosed")

    m.dialogNode = dialog
    m.top.dialog = dialog
end sub

sub onUrlDialogClosed()
    dialog = m.dialogNode
    if dialog = invalid then
        return
    end if

    selected = dialog.buttonSelected
    url = dialog.text
    url = url.Trim()
    m.top.dialog = invalid
    m.dialogNode = invalid

    if selected = 1 then
        if IsHttpUrl(url) then
            LoadPlaylist(url)
        else
            ShowMessage("URL inválida", ["A lista precisa começar com http:// ou https://.", "Exemplo: https://exemplo.com/lista.m3u"])
        end if
    end if
end sub

sub ShowAbout()
    ShowMessage("Sobre o ChanIPTV", [
        "ChanIPTV 1.0 • Player M3U genérico para Roku.",
        "Você precisa informar sua própria URL de lista M3U/M3U8 nas Ajustes.",
        "Os canais, nomes e logotipos pertencem aos seus respectivos proprietários. O aplicativo não hospeda, grava ou distribui conteúdo.",
        "Desenvolvido com SceneGraph e BrightScript."
    ])
end sub

sub ShowMessage(title as String, lines as Object)
    dialog = CreateObject("roSGNode", "StandardMessageDialog")
    dialog.title = title
    dialog.message = lines
    dialog.buttons = ["Fechar"]
    dialog.observeField("buttonSelected", "onMessageClosed")

    m.dialogNode = dialog
    m.top.dialog = dialog
end sub

sub onMessageClosed()
    m.top.dialog = invalid
    m.dialogNode = invalid
end sub

' ---------------------------------------------------------------------------
' Teclas
' ---------------------------------------------------------------------------

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then
        return false
    end if

    lower = LCase(key)

    if lower = "up" then
        if m.loading or m.player.visible then
            return false
        end if
        if HeaderHasFocus() then
            return false
        end if

        if m.view = "settings" then
            m.navSettings.setFocus(true)
        else if m.view = "channels" then
            if m.categoryFilter = "favorites" then
                m.navFavorites.setFocus(true)
            else if m.categoryFilter = "search" then
                m.navSearch.setFocus(true)
            else
                m.navCategories.setFocus(true)
            end if
        else
            m.navCategories.setFocus(true)
        end if
        return true
    end if

    if lower = "down" then
        if m.loading or m.player.visible or not HeaderHasFocus() then
            return false
        end if

        if m.view = "settings" and m.settingGrid.visible then
            m.settingGrid.setFocus(true)
            return true
        else if m.view = "channels" and m.channelGrid.visible then
            m.channelGrid.setFocus(true)
            return true
        else if m.view = "categories" and m.categoryGrid.visible then
            m.categoryGrid.setFocus(true)
            return true
        else if m.view = "error" and m.errorPanel.visible then
            m.retryButton.setFocus(true)
            return true
        end if
        return false
    end if

    if lower = "left" then
        if HeaderHasFocus() and not m.loading and not m.player.visible then
            MoveHeaderFocus(-1)
            return true
        end if
        return false
    end if

    if lower = "right" then
        if HeaderHasFocus() and not m.loading and not m.player.visible then
            MoveHeaderFocus(1)
            return true
        end if
        return false
    end if

    if lower = "back" then
        if m.loading then
            CancelLoad()
            return true
        end if

        if m.player.visible then
            ClosePlayer()
            return true
        end if

        if m.view = "settings" or m.view = "channels" then
            ShowCategories()
            return true
        end if

        if m.view = "error" then
            if m.allChannels.Count() > 0 then
                ShowCategories()
                return true
            end if
            if m.playlistUrl <> "" then
                ShowSettings()
                return true
            end if
            return false
        end if

        if m.view = "categories" then
            return false
        end if
    end if

    return false
end function
