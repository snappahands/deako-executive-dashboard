# Parse CSV and aggregate by agent name
$lines = Get-Content 'c:\Users\slypi\Downloads\export_2026-04-03T1553.csv'
$csvAgents = @{}

foreach ($line in $lines[1..($lines.Count-1)]) {
    $cols = $line -split ','
    if ($cols.Count -lt 10) { continue }
    $name = $cols[1]
    try { $h3=[double]$cols[7]; $p3=[double]$cols[8]; $tp=[double]$cols[9] } catch { continue }
    if (-not $csvAgents[$name]) {
        $csvAgents[$name] = @{
            email=''; phone=''; communities=@()
            homes3=0; packs3=0; totalPacks=0
            primaryComm=''; primaryCommHomes=-1
        }
    }
    $a = $csvAgents[$name]
    if (-not $a.email -and $cols[2]) { $a.email = $cols[2] }
    if (-not $a.phone -and $cols[3]) { $a.phone = $cols[3] }
    $a.homes3 += $h3
    $a.packs3 += $p3
    $a.totalPacks += $tp
    $comm = $cols[5]
    if ($comm -and $h3 -ge $a.primaryCommHomes) { $a.primaryComm = $comm; $a.primaryCommHomes = $h3 }
}

# Parse existing rainmakers.js
$rmContent = Get-Content 'c:\Users\slypi\ClaudeProjects\BrianDashboard\rainmakers.js' -Raw
$entries = [regex]::Matches($rmContent, '\{"n":"([^"]+)","d":"([^"]+)","p25":(\d+),"p10":(\d+),"p8":(\d+),"t":(\d+)\}')

Write-Host "Agents in rainmakers.js: $($entries.Count)"

$notFound = 0; $found = 0; $bigDiff = @()
$newEntries = New-Object System.Collections.Generic.List[string]

foreach ($m in $entries) {
    $name = $m.Groups[1].Value
    $d    = $m.Groups[2].Value
    $p25  = [int]$m.Groups[3].Value
    $p10  = [int]$m.Groups[4].Value
    $p8   = [int]$m.Groups[5].Value
    $t    = [int]$m.Groups[6].Value

    $c = $csvAgents[$name]
    if ($c) {
        $found++
        $csvT = [int]$c.totalPacks
        if ([Math]::Abs($csvT - $t) -gt 5) { $bigDiff += "$name : rainmakers=$t  CSV=$csvT" }

        # Escape special chars for JSON
        $em = $c.email    -replace '\\','\\' -replace '"','\"'
        $ph = $c.phone    -replace '\\','\\' -replace '"','\"'
        $cm = $c.primaryComm -replace '\\','\\' -replace '"','\"'
        $h3 = [int]$c.homes3
        $l3 = [int]$c.packs3

        $newEntries.Add("{`"n`":`"$name`",`"d`":`"$d`",`"p25`":$p25,`"p10`":$p10,`"p8`":$p8,`"t`":$t,`"em`":`"$em`",`"ph`":`"$ph`",`"cm`":`"$cm`",`"h3`":$h3,`"l3`":$l3}")
    } else {
        $notFound++
        $newEntries.Add("{`"n`":`"$name`",`"d`":`"$d`",`"p25`":$p25,`"p10`":$p10,`"p8`":$p8,`"t`":$t,`"em`":`"`",`"ph`":`"`",`"cm`":`"`",`"h3`":0,`"l3`":0}")
    }
}

Write-Host "Matched: $found | Not in CSV: $notFound"
Write-Host "Big discrepancies (>5 packs): $($bigDiff.Count)"
$bigDiff | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }

$output = "const RAINMAKERS = [" + ($newEntries -join ",") + "];"
Set-Content 'c:\Users\slypi\ClaudeProjects\BrianDashboard\rainmakers.js' $output -Encoding UTF8
Write-Host "Done. Written $($newEntries.Count) entries."
