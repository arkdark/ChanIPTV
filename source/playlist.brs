' Leitura e normalização de listas M3U/M3U8.
' Este arquivo é usado pelo PlaylistTask (thread separada).

function ParsePlaylist(raw as String) as Object
    result = {
        channels: []
        total: 0
        skipped: 0
        error: ""
    }

    if raw = invalid then
        result.error = "A lista recebida está vazia."
        return result
    end if

    text = raw
    if Len(text) >= 3 then
        bom = Chr(239) + Chr(187) + Chr(191)
        if Left(text, 3) = bom then
            text = Mid(text, 4)
        end if
    end if

    lines = text.Split(Chr(10))
    channels = []
    seen = {}
    pending = invalid
    pendingGroup = ""

    for each rawLine in lines
        line = rawLine.Trim()
        if Len(line) > 0 then
            lower = LCase(line)
            if Left(lower, 8) = "#extinf:" then
                pending = ParseExtInf(line)
                if pending <> invalid and pending.group = "" then
                    pending.group = pendingGroup
                end if
            else if Left(lower, 8) = "#extgrp:" then
                pendingGroup = Mid(line, 9)
                pendingGroup = pendingGroup.Trim()
                if pending <> invalid and pending.group = "" then
                    pending.group = pendingGroup
                end if
            else if Left(line, 1) = "#" then
                ' Comentários, #EXTVLCOPT, #EXT-X-... etc.
            else if pending <> invalid then
                if IsStreamUrl(line) then
                    if not seen.DoesExist(line) then
                        seen[line] = true
                        channels.Push(BuildChannel(pending, line))
                        result.total = result.total + 1
                    end if
                else
                    result.skipped = result.skipped + 1
                end if
                pending = invalid
            end if
        end if
    end for

    if channels.Count() > 1 then
        channels.SortBy("sortName")
    end if

    result.channels = channels
    return result
end function

function ParseExtInf(line as String) as Object
    ' Remove "#EXTINF:" e separa atributos do nome de exibição.
    body = Mid(line, 9)
    commaPos = FindAttributeComma(body)
    attrsText = body
    name = ""

    if commaPos > 0 then
        attrsText = Left(body, commaPos - 1)
        name = Mid(body, commaPos + 1)
        name = name.Trim()
    end if

    ' Remove a duração (-1, 0 etc.) do começo do trecho de atributos.
    spacePos = Instr(1, attrsText, " ")
    if spacePos > 0 then
        attrsText = Mid(attrsText, spacePos + 1)
    end if

    attrs = ParseAttributes(attrsText)
    info = {
        name: name
        group: ""
        logo: ""
        country: ""
        adult: false
    }

    if info.name = "" and attrs.DoesExist("tvg-name") then
        value = attrs["tvg-name"]
        info.name = value.Trim()
    end if
    if info.name = "" and attrs.DoesExist("tvg-id") then
        value = attrs["tvg-id"]
        info.name = value.Trim()
    end if
    if attrs.DoesExist("group-title") then
        info.group = FirstGroup(attrs["group-title"])
    end if
    if attrs.DoesExist("tvg-logo") then
        value = attrs["tvg-logo"]
        info.logo = value.Trim()
    end if
    if attrs.DoesExist("tvg-country") then
        value = attrs["tvg-country"]
        info.country = UCase(value.Trim())
    end if

    info.adult = IsAdultText(info.name, info.group)
    return info
end function

function FindAttributeComma(text as String) as Integer
    insideQuotes = false
    for i = 1 to Len(text)
        ch = Mid(text, i, 1)
        if ch = Chr(34) then
            insideQuotes = not insideQuotes
        else if ch = "," and not insideQuotes then
            return i
        end if
    end for
    return 0
end function

function ParseAttributes(text as String) as Object
    attrs = {}
    length = Len(text)
    i = 1

    while i <= length
        while i <= length and Mid(text, i, 1) = " "
            i = i + 1
        end while
        if i > length then
            exit while
        end if

        eq = Instr(i, text, "=")
        if eq = 0 then
            exit while
        end if

        key = Mid(text, i, eq - i)
        key = LCase(key.Trim())
        value = ""
        j = eq + 1

        if Mid(text, j, 1) = Chr(34) then
            j = j + 1
            closeQuote = Instr(j, text, Chr(34))
            if closeQuote = 0 then
                closeQuote = length + 1
            end if
            value = Mid(text, j, closeQuote - j)
            i = closeQuote + 1
        else
            spacePos = Instr(j, text, " ")
            if spacePos = 0 then
                spacePos = length + 1
            end if
            value = Mid(text, j, spacePos - j)
            i = spacePos
        end if

        if key <> "" then
            attrs[key] = value
        end if
    end while

    return attrs
end function

function FirstGroup(value as String) as String
    if value = invalid then
        return ""
    end if
    semicolon = Instr(1, value, ";")
    if semicolon > 0 then
        part = Left(value, semicolon - 1)
        return part.Trim()
    end if
    return value.Trim()
end function

function BuildChannel(info as Object, url as String) as Object
    name = CleanChannelName(info.name)
    group = TranslateGroup(info.group)
    if group = "" then
        group = "Outros"
    end if

    return {
        id: Md5Hex(url)
        name: name
        sortName: LCase(name)
        url: url
        logo: info.logo
        group: group
        country: info.country
        adult: info.adult
    }
end function

function CleanChannelName(value as String) as String
    if value = invalid then
        return "Canal sem nome"
    end if
    name = value.Trim()
    if name = "" then
        return "Canal sem nome"
    end if
    return name
end function

function IsStreamUrl(url as String) as Boolean
    if url = invalid then
        return false
    end if
    low = LCase(url.Trim())
    return Left(low, 7) = "http://" or Left(low, 8) = "https://"
end function

function Md5Hex(value as String) as String
    digest = CreateObject("roEVPDigest")
    digest.Setup("md5")
    hash = digest.Process(value)
    if hash = invalid then
        return value
    end if
    return hash
end function

function IsAdultText(name as String, group as String) as Boolean
    haystack = LCase(group + " " + name)
    tokens = [
        "xxx", "adult", "porn", "erotic", "erótic",
        "sexo", "sexual", "18+", "playboy", "brazzers", "onlyfans"
    ]
    for each token in tokens
        if Instr(1, haystack, token) > 0 then
            return true
        end if
    end for
    return false
end function

' ---------------------------------------------------------------------------
' Tradução dos grupos mais comuns. Grupos desconhecidos são mantidos.
' ---------------------------------------------------------------------------

function TranslateGroup(group as String) as String
    if group = invalid then
        return "Outros"
    end if
    original = group.Trim()
    if original = "" then
        return "Outros"
    end if

    key = UCase(original)
    map = GroupTranslations()
    if map.DoesExist(key) then
        return map[key]
    end if
    return original
end function

function GroupTranslations() as Object
    map = {
        ANIMATION: "Animação"
        AUTO: "Automotivo"
        BUSINESS: "Negócios"
        CLASSIC: "Clássicos"
        COMEDY: "Comédia"
        COOKING: "Culinária"
        CULTURE: "Cultura"
        DOCUMENTARY: "Documentários"
        EDUCATION: "Educação"
        ENTERTAINMENT: "Entretenimento"
        FAMILY: "Família"
        GENERAL: "Geral"
        KIDS: "Infantil"
        LEGISLATIVE: "Legislativo"
        LIFESTYLE: "Estilo de vida"
        MOVIES: "Filmes"
        MOVIE: "Filmes"
        MUSIC: "Música"
        NEWS: "Notícias"
        OUTDOOR: "Ar livre"
        POLITICS: "Política"
        RELIGIOUS: "Religioso"
        RELAX: "Relaxamento"
        SCIENCE: "Ciência"
        SERIES: "Séries"
        SHOPPING: "Compras"
        SPORTS: "Esportes"
        TRAVEL: "Viagens"
        WEATHER: "Clima"
        XXX: "Adulto"
        UNDEFINED: "Outros"
    }

    map["NOTÍCIAS"] = "Notícias"
    map["NOTICIAS"] = "Notícias"
    map["ESPORTES"] = "Esportes"
    map["FILMES"] = "Filmes"
    map["SÉRIES"] = "Séries"
    map["SERIES"] = "Séries"
    map["INFANTIL"] = "Infantil"
    map["MÚSICA"] = "Música"
    map["MUSICA"] = "Música"
    map["DOCUMENTÁRIOS"] = "Documentários"
    map["DOCUMENTARIOS"] = "Documentários"
    map["RELIGIOSO"] = "Religioso"
    map["EDUCAÇÃO"] = "Educação"
    map["EDUCACAO"] = "Educação"
    map["ENTRETENIMENTO"] = "Entretenimento"
    map["CULTURA"] = "Cultura"
    map["CIÊNCIA"] = "Ciência"
    map["CIENCIA"] = "Ciência"
    map["COMPRAS"] = "Compras"
    map["CLIMA"] = "Clima"
    map["POLÍTICA"] = "Política"
    map["POLITICA"] = "Política"
    map["FAMÍLIA"] = "Família"
    map["FAMILIA"] = "Família"
    map["VIAGENS"] = "Viagens"
    map["NEGÓCIOS"] = "Negócios"
    map["NEGOCIOS"] = "Negócios"
    map["COMÉDIA"] = "Comédia"
    map["COMEDIA"] = "Comédia"
    map["CULINÁRIA"] = "Culinária"
    map["CULINARIA"] = "Culinária"
    map["CLÁSSICOS"] = "Clássicos"
    map["CLASSICOS"] = "Clássicos"
    map["ANIMAÇÃO"] = "Animação"
    map["ANIMACAO"] = "Animação"
    map["ESTILO DE VIDA"] = "Estilo de vida"
    map["AR LIVRE"] = "Ar livre"
    map["LEGISLATIVO"] = "Legislativo"
    map["RELAXAMENTO"] = "Relaxamento"
    map["GERAL"] = "Geral"
    map["OUTROS"] = "Outros"
    map["ADULTO"] = "Adulto"
    map["TV ABERTA"] = "TV aberta"
    map["TV ABERTA "] = "TV aberta"
    map["VARIEDADES"] = "Variedades"
    map["VARIETY"] = "Variedades"
    map["RELIGION"] = "Religioso"

    return map
end function
