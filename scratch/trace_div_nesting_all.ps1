function Trace-Dives($filePath) {
    Write-Host "--- Tracing $filePath ---"
    $lines = Get-Content $filePath
    $level = 0
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        # Ignore comments if any
        if ($line.Trim().StartsWith("<!--") -and $line.Trim().EndsWith("-->")) {
            continue
        }
        $opens = [regex]::Matches($line, '<div\b').Count
        $closes = [regex]::Matches($line, '</div>').Count
        $level += ($opens - $closes)
        if ($level -lt 0) {
            Write-Host "Line $($i+1): Level dropped below 0 to $level! Line content: $($line.Trim())"
            $level = 0
        }
    }
    Write-Host "Final level for $filePath : $level"
}
Trace-Dives 'index_local_preview.html'
Trace-Dives 'Index.html'
