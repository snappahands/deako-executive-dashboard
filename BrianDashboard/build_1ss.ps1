$lines = Get-Content 'c:\Users\slypi\Downloads\DRH Homes with 1SS.csv'
$monthly   = @{}
$quarterly = @{}
$yearly    = @{}

foreach ($line in $lines[1..($lines.Count-1)]) {
    $c = $line -split ','
    if ($c.Count -lt 5) { continue }
    $div = $c[1].Trim()
    $po1 = $c[4].Trim()
    if (-not $div -or -not $po1 -or $po1.Length -lt 7) { continue }

    $mo = $po1.Substring(0,7)   # YYYY-MM
    $yr = $po1.Substring(0,4)   # YYYY
    try {
        $month = [int]$po1.Substring(5,2)
        $qStart = if($month -le 3){'01'} elseif($month -le 6){'04'} elseif($month -le 9){'07'} else{'10'}
        $qp = "$yr-$qStart"
    } catch { continue }

    $mk = "$div|$mo";  if (-not $monthly[$mk])   { $monthly[$mk]   = 0 }; $monthly[$mk]++
    $qk = "$div|$qp";  if (-not $quarterly[$qk]) { $quarterly[$qk] = 0 }; $quarterly[$qk]++
    $yk = "$div|$yr";  if (-not $yearly[$yk])    { $yearly[$yk]    = 0 }; $yearly[$yk]++
}

function ToJs($ht) {
    $items = $ht.GetEnumerator() | Sort-Object Name | ForEach-Object {
        $parts = $_.Name -split '\|'
        $d = $parts[0] -replace "'","\'"
        "{div:'$d',p:'$($parts[1])',n:$($_.Value)}"
    }
    return '[' + ($items -join ',') + ']'
}

$out = "const SS1_DATA={monthly:" + (ToJs $monthly) + ",quarterly:" + (ToJs $quarterly) + ",yearly:" + (ToJs $yearly) + "};"
Set-Content 'C:\Users\slypi\ClaudeProjects\BrianDashboard\ss1_data.js' $out -Encoding UTF8
Write-Host "Written. monthly=$($monthly.Count) quarterly=$($quarterly.Count) yearly=$($yearly.Count)"
Write-Host "Unique divisions: $(($monthly.Keys | ForEach-Object {($_ -split '\|')[0]}) | Sort-Object -Unique | Measure-Object).Count"
