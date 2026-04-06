$convDivs = @('asheville','atlanta_west','baldwin','central-pennsylvania','charlotte_north','charlotte_south','cincinnati','delaware','eastern_pa','fort_wayne','greensboro','greenville','indianapolis','kansas_city','maryland','north_colorado','oregon','raleigh','raleigh_north','south_colorado','southern_colorado')

$lines = Get-Content 'c:\Users\slypi\Downloads\DRH Home Ratifications by Month.csv'
$header = $lines[0] -split ','
# Columns are descending (newest first). Trim to YYYY-MM.
$months = $header[1..($header.Count-1)] | ForEach-Object { $_.Trim().Substring(0,7) }

$monthly   = [System.Collections.Generic.List[string]]::new()
$quarterly = @{}
$yearly    = @{}

foreach ($line in $lines[1..($lines.Count-1)]) {
    $c = $line -split ','
    $div = $c[0].Trim().ToLower()
    if ($convDivs -notcontains $div) { continue }
    $d = $div -replace "'","\'"

    for ($i = 0; $i -lt $months.Count; $i++) {
        $mo  = $months[$i]
        $raw = $c[$i+1].Trim()
        if (-not $raw -or $raw -eq '') { continue }
        $val = [int]$raw
        if ($val -eq 0) { continue }

        $monthly.Add("{div:'$d',p:'$mo',n:$val}")

        $yr = $mo.Substring(0,4)
        $mNum = [int]$mo.Substring(5,2)
        $qStart = if($mNum -le 3){'01'} elseif($mNum -le 6){'04'} elseif($mNum -le 9){'07'} else{'10'}
        $qp = "$yr-$qStart"

        $qk = "$d|$qp"; if(-not $quarterly[$qk]){$quarterly[$qk]=0}; $quarterly[$qk]+=$val
        $yk = "$d|$yr";  if(-not $yearly[$yk])  {$yearly[$yk]=0};    $yearly[$yk]+=$val
    }
}

function ToJsHt($ht) {
    $items = $ht.GetEnumerator() | Sort-Object Name | ForEach-Object {
        $parts = $_.Name -split '\|'
        "{div:'$($parts[0])',p:'$($parts[1])',n:$($_.Value)}"
    }
    return '[' + ($items -join ',') + ']'
}

$out = "const RATIF_DATA={monthly:[" + ($monthly -join ',') + "],quarterly:" + (ToJsHt $quarterly) + ",yearly:" + (ToJsHt $yearly) + "};"
Set-Content 'C:\Users\slypi\ClaudeProjects\BrianDashboard\ratif_data.js' $out -Encoding UTF8
Write-Host "Written. monthly=$($monthly.Count) quarterly=$($quarterly.Count) yearly=$($yearly.Count)"
