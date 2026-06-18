$previewPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\index_local_preview.html"
$content = [System.IO.File]::ReadAllText($previewPath)

$idx = 488588
# Print 200 characters before and 200 characters after Index 488588
$start = $idx - 200
$sub = $content.Substring($start, 400)
Write-Host "Length of file: $($content.Length)"
Write-Host "Substring around 488588:"
Write-Host $sub

# Let's inspect the characters by converting them to code representation
$chars = $content.Substring($idx - 150, 250).ToCharArray()
$out = ""
foreach ($c in $chars) {
    if ([char]::IsControl($c)) {
        $out += "\x" + [int]$c
    } else {
        $out += $c
    }
}
Write-Host "Detailed chars:"
Write-Host $out
