Connect-ExchangeOnline


$UserEmail = "benutzer@domain.de"
$Operations = @("FileDownloaded", "FileAccessed", "FileDeleted", "FileCopied", "SharingSet", "FolderMoved", "FolderDeleted")

$AuditLogs = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) -UserIds $UserEmail -RecordType SharePointFileOperation -Operations $Operations |
ForEach-Object {
    $AuditData = $_.AuditData | ConvertFrom-Json
    [PSCustomObject]@{
        CreationDate = $_.CreationDate
        UserIds = $_.UserIds
        Operations = $_.Operations
        FilePath = $AuditData.ObjectId
        IP = $AuditData.ClientIP
        GeoLocation = $AuditData.GeoLocation
        UserAgent = $AuditData.UserAgent
    }
}
#Daten Anzeigen lassen
$AuditLogs  | Sort-Object CreationDate -Descending |
Select-Object CreationDate, UserIds, Operations, FilePath, IP, GeoLocation, UserAgent |
Format-Table -Wrap -AutoSize
# Export als JSON Datei
$AuditLogs | ConvertTo-Json -Depth 3 | Out-File "AuditLogData.json"


Disconnect-ExchangeOnline -Confirm:$false
