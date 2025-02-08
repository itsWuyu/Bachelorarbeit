Connect-ExchangeOnline

# Zeitraum in Tagen festlegen, alles über 10 Tage geht auf Grund von Get-MessageTrace nicht dafür muss Start-HistoricalSearch genutzt werden
$ZeitRaumTage = (Get-Date).AddDays(-10)
#Nur Mails mit Anhängen
$OnlyAttachments = $false
$UserEmail = "benutzer@domain.de"
$Operations = @("Send", "SendOnBehalf", "Access", "MessageBind", "SoftDelete", "HardDelete", "MailboxLogin")

$Emaillog = Search-UnifiedAuditLog -StartDate $ZeitRaumTage  -EndDate (Get-Date) -UserIds $UserEmail -RecordType ExchangeItem -Operations $Operations | 
ForEach-Object {
    $AuditData = $_.AuditData | ConvertFrom-Json
    # Nur fortfahren, wenn Anhänge vorhanden sind
    if ($OnlyAttachments) {
        Write-Host("Nur Mails mit Anhängen")
        if (@($AuditData.Item.Attachments).Count -gt 0) {
            $messageTrace = Get-MessageTrace -MessageId "$($AuditData.Item.InternetMessageId)"
            [PSCustomObject]@{
                Zeitstempel = $_.CreationDate
                Absender = $_.UserIds
                NachrichtID = $AuditData.Id
                Empfänger = $messageTrace.RecipientAddress
                Betreff = $messageTrace.Subject
                Operation = $AuditData.Operation
                Anhang = $AuditData.Item.Attachments
                ClientIP = $AuditData.ClientIP
                ClientInfo = $AuditData.ClientInfoString
            }
        }
    }
    else {
        $messageTrace = Get-MessageTrace -MessageId "$($AuditData.Item.InternetMessageId)"
        [PSCustomObject]@{
            Zeitstempel = $_.CreationDate
            Absender = $_.UserIds
            NachrichtID = $AuditData.Id
            Empfänger = $messageTrace.RecipientAddress
            Betreff = $messageTrace.Subject
            Operation = $AuditData.Operation
            Anhang = $AuditData.Item.Attachments
            ClientIP = $AuditData.ClientIP
            ClientInfo = $AuditData.ClientInfoString
        }
    }
} 

$Emaillog | 
    Sort-Object Zeitstempel -Descending |
    Select-Object Zeitstempel, NachrichtID, Absender, Empfänger, Betreff, Operation, Anhang, ClientIP, ClientInfo |
    Format-Table -Wrap -AutoSize

# Export als JSON und CSV Datei
$Emaillog | ConvertTo-Json -Depth 3 | Out-File "EmailLogData.json"
$Emaillog | Export-Csv -Path "EmailLogData.csv" -NoTypeInformation -Encoding UTF8

Disconnect-ExchangeOnline -Confirm:$false

