sub Init()
    m.top.functionName = "FetchPlaylist"
end sub

sub FetchPlaylist()
    url = m.top.url
    result = {
        ok: false
        error: ""
        channels: []
        total: 0
        skipped: 0
    }

    if url = invalid then
        result.error = "Nenhuma URL de lista foi informada."
        m.top.result = result
        return
    end if

    url = url.Trim()
    if url = "" then
        result.error = "Nenhuma URL de lista foi informada."
        m.top.result = result
        return
    end if

    if not IsStreamUrl(url) then
        result.error = "A URL da lista deve começar com http:// ou https://."
        m.top.result = result
        return
    end if

    port = CreateObject("roMessagePort")
    transfer = CreateObject("roUrlTransfer")
    transfer.SetMessagePort(port)
    transfer.SetUrl(url)
    transfer.SetUserAgent("ChanIPTV/1.0 (Roku)")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.EnableEncodings(true)
    transfer.RetainBodyOnError(true)

    if not transfer.AsyncGetToString() then
        result.error = "Não foi possível iniciar o download da lista."
        m.top.result = result
        return
    end if

    body = ""
    status = 0
    failure = ""
    elapsed = 0
    finished = false

    while not finished and elapsed < 45000
        msg = wait(250, port)
        elapsed = elapsed + 250
        if type(msg) = "roUrlEvent" then
            code = msg.GetResponseCode()
            if code <> 0 then
                status = code
                failure = msg.GetFailureReason()
                rawBody = msg.GetString()
                if type(rawBody) = "roString" or type(rawBody) = "String" then
                    body = rawBody
                else
                    body = ""
                end if
                finished = true
            end if
        end if
    end while

    if not finished then
        transfer.AsyncCancel()
        result.error = "Tempo esgotado ao baixar a lista. Verifique sua conexão e tente novamente."
        m.top.result = result
        return
    end if

    if status < 200 or status >= 300 then
        if status < 0 then
            result.error = "Falha de rede ao acessar a lista."
            if failure <> invalid and failure <> "" then
                result.error = result.error + " " + failure
            end if
        else
            result.error = "O servidor respondeu com HTTP " + Str(status).Trim() + "."
        end if
        m.top.result = result
        return
    end if

    if Len(body) = 0 then
        result.error = "A lista baixada está vazia."
        m.top.result = result
        return
    end if

    parsed = ParsePlaylist(body)
    if parsed.channels.Count() = 0 then
        result.error = "Nenhum canal compatível foi encontrado nessa lista."
        result.skipped = parsed.skipped
        m.top.result = result
        return
    end if

    result.ok = true
    result.channels = parsed.channels
    result.total = parsed.channels.Count()
    result.skipped = parsed.skipped
    m.top.result = result
end sub
