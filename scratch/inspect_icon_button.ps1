$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Stylesheet.html"
$out = @()
if (Test-Path $path) {
    $content = [System.IO.File]::ReadAllText($path)
    $lines = $content -split "\r?\n"
    $i = 0
    foreach ($line in $lines) {
        $i++
        if ($line.Contains("icon-button")) {
            $out += "Line $($i): $($line.Trim())"
            # Print next 5 lines
            for ($j = 1; $j -le 5; $j++) {
                $out += "  Line $($i+$j): $($lines[$i+$j-1].Trim())"
            }
        }
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\icon_button_styles.txt" -Encoding utf8
Write-Host "Done"
