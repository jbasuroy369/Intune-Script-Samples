[Windows.Management.MdmSessionManager, Windows.Management, ContentType = WindowsRuntime] | Out-Null
        $MDMSession = [Windows.Management.MdmSessionManager]::TryCreateSession()
        $MDMSession.StartAsync() | Out-Null

        $MDMSyncTimeout = 0
        do {
            Start-Sleep -Seconds 5
            $MDMSyncTimeout += 1
        }while (($MDMSession.State -ne "Completed") -and ($MDMSyncTimeout -lt 12))