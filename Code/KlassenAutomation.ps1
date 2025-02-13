# Check the AIP Service status
Import-Module AIPService
Connect-AipService

$serviceStatus = Get-AIPService

if ($serviceStatus.Status -eq "Disabled") {
    Write-Output "AIP Service ist derzeit deaktiviert. Wird jetzt aktiviert..."
    
    Enable-AIPService
    
    $newStatus = Get-AIPService
    if ($newStatus.Status -eq "Enabled") {
        Write-Output "AIP Service wurde erfolgreich aktiviert."
    } else {
        Write-Error "Aktivierung des AIP Service fehlgeschlagen. Bitte überprüfen Sie die Service-Konfiguration."
	sleep 5
	exit
    }
} else {
    Write-Output "AIP Service ist bereits aktiviert."
}

# Disconnect from AIP Service
Disconnect-AipService





# Verbindung zu Microsoft Purview herstellen
Connect-IPPSSession

$FirmenName = "Firma Contoso"


    # Labels erstellen
$labels = @(
	@{Name="Öffentlich"; Tooltip="Für öffentlich zugängliche Informationen"; Description="Dieses Label ist für Daten vorgesehen, die öffentlich geteilt werden können."; Color="#34d631";ContentMarkingText=""; EncryptionEnabled=$false},
        @{Name="Intern"; Tooltip="Nur für interne Nutzung"; Description="Dieses Label ist für Daten vorgesehen, die innerhalb des Unternehmens bleiben sollen."; Color="#0717f2"; ContentMarkingText=""; EncryptionEnabled=$true;EncryptionOfflineAccessDays=7},
        @{Name="Vertraulich"; Tooltip="Vertrauliche Informationen"; Description="Dieses Label schützt vertrauliche Daten."; ContentMarkingText="Vertraulich - $FirmenName"; Color="#fca103"; EncryptionEnabled=$true;EncryptionOfflineAccessDays=7 },
        @{Name="Streng Vertraulich"; Tooltip="Hochsensible Informationen"; Description="Dieses Label schützt hochsensible Daten und wendet erweiterte Verschlüsselung an."; Color="#ff0000"; ContentMarkingText="Streng Vertraulich - $FirmenName"; EncryptionEnabled=$true;EncryptionOfflineAccessDays=7}
)

    # Labels durchlaufen und erstellen
foreach ($label in $labels) {
        $labelParams = @{
        Name = $label.Name
        DisplayName = $label.Name
        Tooltip = $label.Tooltip
        Comment = $label.Description
	AdvancedSettings =  $label.Color
        EncryptionEnabled = $label.EncryptionEnabled
        EncryptionPromptUser = $true
        ContentMarkingText = $label.ContentMarkingText
        ApplyContentMarkingFooterAlignment = "Center"
        ApplyContentMarkingFooterEnabled = $true
        ApplyContentMarkingFooterFontSize = 10
        ApplyContentMarkingFooterText = $label.ContentMarkingText
        ContentType = "File, Email"
}

if ($label.EncryptionEnabled) {
        $labelParams.EncryptionOfflineAccessDays = $label.EncryptionOfflineAccessDays
}

New-Label @labelParams
}
# Verbindung beenden
Disconnect-ExchangeOnline -Confirm:$false

# Verbindung zu Azure Information Protection herstellen
Connect-AipService

# Label ID für "Intern" abrufen
$internLabel = Get-Label | Where-Object { $_.DisplayName -eq "Intern" }

# Veröffentlichungsrichtlinie für die Gruppe GF erstellen
$policyNameGF = "Richtlinie Geschäftsführung"

New-LabelPolicy `
       -Name $policyNameGF  `
       -Labels "Öffentlich", "Intern", "Vertraulich", "Streng Vertraulich" `
       -ModernGroupLocation "GF" `
       -DefaultLabelId $internLabel.Guid

# Veröffentlichungsrichtlinie für die Gruppe Mitarbeiter erstellen
$policyNameMitarbeiter = "Richtlinie Mitarbeiter"

New-LabelPolicy `
       -Name $policyNameMitarbeiter `
       -Labels "Öffentlich", "Intern" `
       -ModernGroupLocation "All" `
       -DefaultLabelId $internLabel.Guid

