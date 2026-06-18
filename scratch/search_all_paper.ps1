$query = ".paper"
$files = Get-ChildItem -Path "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval" -Include *.html,*.js -Recurse
$out = @()
foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    if ($content.Contains($query)) {
        $out += "Found $query in: $($file.Name)"
        $lines = $content -split "\r?\n"
        $i = 0
        foreach ($line in $lines) {
            $i++
            if ($line.Contains($query)) {
                $out += "  Line $($i): $($line.Trim())"
            }
        }
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\search_all_paper_out.txt" -Encoding utf8
Write-Host "Done"
