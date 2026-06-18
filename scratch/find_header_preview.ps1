$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\index_local_preview.html"
$out = @()
if (Test-Path $path) {
    $content = [System.IO.File]::ReadAllText($path)
    $lines = $content -split "\r?\n"
    $i = 0
    foreach ($line in $lines) {
        $i++
        if ($line.Contains("header-right") -or $line.Contains("notif-bell-btn") -or $line.Contains("btn-profile-signature")) {
            $out += "Line $($i): $($line.Trim())"
            # Print next 5 lines
            for ($j = 1; $j -le 5; $j++) {
                $out += "  Line $($i+$j): $($lines[$i+$j-1].Trim())"
            }
        }
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\header_preview_lines.txt" -Encoding utf8
Write-Host "Done"
