$files = @("Code.js", "SetupSheets.js", "JavaScript.html", "index_local_preview.html")
foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content -Raw $file
        $chars = $content.ToCharArray()
        $openB = ($chars | Where-Object { $_ -eq '{' }).Count
        $closeB = ($chars | Where-Object { $_ -eq '}' }).Count
        $openP = ($chars | Where-Object { $_ -eq '(' }).Count
        $closeP = ($chars | Where-Object { $_ -eq ')' }).Count
        $openSq = ($chars | Where-Object { $_ -eq '[' }).Count
        $closeSq = ($chars | Where-Object { $_ -eq ']' }).Count
        Write-Host "$file - Braces: $openB / $closeB | Parens: $openP / $closeP | Brackets: $openSq / $closeSq"
    } else {
        Write-Host "$file not found"
    }
}
