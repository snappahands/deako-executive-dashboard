$lines = Get-Content 'c:\Users\slypi\Downloads\converison_by_division_2026-04-20T1542.csv'
$data = $lines[1..($lines.Count-1)] | ForEach-Object {
    $c = $_ -split ','
    if ($c.Count -lt 7) { return }
    [pscustomobject]@{
        type=$c[0]; period=$c[1].Substring(0,7); div=$c[3]
        eligible=[int]$c[4]; packs=[int]$c[5]
        rate=[Math]::Round([double]$c[6]*100,2)
    }
} | Where-Object { $_ -ne $null }

function ToJs($arr) {
    $items = $arr | ForEach-Object {
        $d = $_.div -replace "'","\\'"
        "{div:'$d',p:'$($_.period)',e:$($_.eligible),pk:$($_.packs),r:$($_.rate)}"
    }
    return '[' + ($items -join ',') + ']'
}

$monthly   = $data | Where-Object { $_.type -eq 'monthly' }   | Sort-Object div,period
$quarterly = $data | Where-Object { $_.type -eq 'quarterly' } | Sort-Object div,period
$yearly    = $data | Where-Object { $_.type -eq 'yearly' }    | Sort-Object div,period

$out = "const CONV_DATA={monthly:" + (ToJs $monthly) + ",quarterly:" + (ToJs $quarterly) + ",yearly:" + (ToJs $yearly) + "};"
Set-Content 'C:\Users\slypi\ClaudeProjects\BrianDashboard\conv_data.js' $out -Encoding UTF8
Write-Host "Written. monthly=$($monthly.Count) quarterly=$($quarterly.Count) yearly=$($yearly.Count)"
