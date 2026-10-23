' Configurações, listas e utilidades compartilhadas pelo app.

function ConfigDefaultUrl() as String
    return ""
end function

function ConfigPresets() as Object
    return []
end function

function IsHttpUrl(url as String) as Boolean
    if url = invalid then
        return false
    end if
    low = LCase(url.Trim())
    return Left(low, 7) = "http://" or Left(low, 8) = "https://"
end function

function PresetForUrl(url as String) as Object
    if url = invalid then
        return invalid
    end if
    for each preset in ConfigPresets()
        if LCase(preset.url) = LCase(url) then
            return preset
        end if
    end for
    return invalid
end function

function CurrentListName(url as String) as String
    if url = invalid or url = "" then
        return "Nenhuma lista"
    end if
    preset = PresetForUrl(url)
    if preset <> invalid then
        return preset.title
    end if
    return "Lista personalizada"
end function

' ---------------------------------------------------------------------------
' Registro local (preferências e favoritos)
' ---------------------------------------------------------------------------

function ConfigRead(key as String, fallback as String) as String
    section = CreateObject("roRegistrySection", "ChanIPTV")
    if section.Exists(key) then
        value = section.Read(key)
        if value <> invalid then
            return value
        end if
    end if
    return fallback
end function

sub ConfigWrite(key as String, value as String)
    section = CreateObject("roRegistrySection", "ChanIPTV")
    section.Write(key, value)
    section.Flush()
end sub

function GetConfiguredUrl() as String
    url = ConfigRead("playlistUrl", ConfigDefaultUrl())
    if url = invalid or url = "" then
        return ""
    end if
    if not IsHttpUrl(url) then
        return ""
    end if
    return url
end function

sub SaveConfiguredUrl(url as String)
    if IsHttpUrl(url) then
        ConfigWrite("playlistUrl", url)
    end if
end sub

function IsAdultFilterOn() as Boolean
    return ConfigRead("adultFilter", "1") = "1"
end function

sub SaveAdultFilter(enabled as Boolean)
    if enabled then
        ConfigWrite("adultFilter", "1")
    else
        ConfigWrite("adultFilter", "0")
    end if
end sub

function LoadFavorites() as Object
    favorites = {}
    raw = ConfigRead("favorites", "")
    if raw <> "" then
        for each id in raw.Split(",")
            id = id.Trim()
            if id <> "" then
                favorites[id] = true
            end if
        end for
    end if
    return favorites
end function

sub SaveFavorites(favorites as Object)
    ids = []
    for each id in favorites
        ids.Push(id)
    end for
    ConfigWrite("favorites", ids.Join(","))
end sub

' ---------------------------------------------------------------------------
' Texto e formatação
' ---------------------------------------------------------------------------

function FormatCount(value as Integer) as String
    text = Str(value).Trim()
    out = ""
    digits = 0
    for i = Len(text) to 1 step -1
        out = Mid(text, i, 1) + out
        digits = digits + 1
        if digits mod 3 = 0 and i > 1 then
            out = "." + out
        end if
    end for
    return out
end function

function CountText(value as Integer) as String
    if value = 1 then
        return "1 canal"
    end if
    return FormatCount(value) + " canais"
end function

function TruncateText(text as String, maxLength as Integer) as String
    if text = invalid then
        return ""
    end if
    if Len(text) <= maxLength then
        return text
    end if
    if maxLength < 2 then
        return ""
    end if
    return Left(text, maxLength - 1) + "..."
end function

function ShortGroupName(group as String) as String
    if group = invalid then
        return "Outros"
    end if
    if Len(group) <= 22 then
        return group
    end if
    return Left(group, 20) + "..."
end function

function InitialsFor(name as String) as String
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
