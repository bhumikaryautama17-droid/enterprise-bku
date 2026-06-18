$files = @("Code.js", "SetupSheets.js", "JavaScript.html", "index_local_preview.html")
foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content -Raw $file
        $openB = $content.Split('{').Length - 1
        $closeB = $content.Split('}').Length - 1
        $openP = $content.Split('(').Length - 1
        $closeP = $content.Split(')').Length - 1
        $openSq = $content.Split('[').Length - 1
        $closeSq = $content.Split(']').Length - 1
        Write-Host "$file - Braces: $openB / $closeB | Parens: $openP / $closeP | Brackets: $openSq / $closeSq"
    } else {
        Write-Host "$file not found"
    }
}
