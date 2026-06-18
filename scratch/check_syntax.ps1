$content = Get-Content -Path "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\index_local_preview.html" -Raw

$braces = 0
$parentheses = 0
$brackets = 0

$inSingleComment = $false
$inMultiComment = $false
$inDoubleQuote = $false
$inSingleQuote = $false
$inTemplate = $false

$lineNum = 1
$colNum = 1

for ($i = 0; $i -lt $content.Length; $i++) {
    $char = $content[$i]
    $nextChar = if ($i + 1 -lt $content.Length) { $content[$i+1] } else { '' }
    
    # Track line numbers
    if ($char -eq "`n") {
        $lineNum++
        $colNum = 1
    } else {
        $colNum++
    }
    
    # State tracking
    if ($inSingleComment) {
        if ($char -eq "`n") {
            $inSingleComment = $false
        }
        continue
    }
    if ($inMultiComment) {
        if ($char -eq '*' -and $nextChar -eq '/') {
            $inMultiComment = $false
            $i++ # skip '/'
        }
        continue
    }
    if ($inDoubleQuote) {
        if ($char -eq '"') {
            $inDoubleQuote = $false
        }
        continue
    }
    if ($inSingleQuote) {
        if ($char -eq "'") {
            $inSingleQuote = $false
        }
        continue
    }
    if ($inTemplate) {
        if ($char -eq '`') {
            $inTemplate = $false
        }
        continue
    }
    
    # Check start of comments/strings
    if ($char -eq '/' -and $nextChar -eq '/') {
        $inSingleComment = $true
        $i++
        continue
    }
    if ($char -eq '/' -and $nextChar -eq '*') {
        $inMultiComment = $true
        $i++
        continue
    }
    if ($char -eq '"') {
        $inDoubleQuote = $true
        continue
    }
    if ($char -eq "'") {
        $inSingleQuote = $true
        continue
    }
    if ($char -eq '`') {
        $inTemplate = $true
        continue
    }
    
    # Count braces, parens, brackets
    if ($char -eq '{') { $braces++ }
    elseif ($char -eq '}') { 
        $braces-- 
        if ($braces -lt 0) {
            Write-Host "Unmatched } at original index $i (Line $lineNum, Col $colNum)"
            $lines = $content -split "\r?\n"
            Write-Host "Context Line $lineNum :" $lines[$lineNum - 1]
            $braces = 0
        }
    }
    elseif ($char -eq '(') { $parentheses++ }
    elseif ($char -eq ')') { 
        $parentheses-- 
        if ($parentheses -lt 0) {
            Write-Host "Unmatched ) at original index $i (Line $lineNum, Col $colNum)"
            $lines = $content -split "\r?\n"
            Write-Host "Context Line $lineNum :" $lines[$lineNum - 1]
            $parentheses = 0
        }
    }
    elseif ($char -eq '[') { $brackets++ }
    elseif ($char -eq ']') { 
        $brackets-- 
        if ($brackets -lt 0) {
            Write-Host "Unmatched ] at original index $i (Line $lineNum, Col $colNum)"
            $lines = $content -split "\r?\n"
            Write-Host "Context Line $lineNum :" $lines[$lineNum - 1]
            $brackets = 0
        }
    }
}

Write-Host "Final Mismatches -> Braces: $braces, Parentheses: $parentheses, Brackets: $brackets"
