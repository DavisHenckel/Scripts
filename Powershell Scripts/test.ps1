param ( #define parameter list
    [string]$LocNum,
    [string]$EmpNum,
    [string]$Name,
    [string]$JobTitle
)

#Output contents to ensure they are correct
Write-Host("Location number in test.ps1 is:$LocNum")
Write-Host("Employee Number in test.ps1 is:$EmpNum")
Write-Host("Name in test.ps1 is:$Name")
Write-Host("Job Title in test.ps1 is:$JobTitle")


$Split = $Name.split(" ")

$first = $Split[0]

$last = $Split[1]

$firstI = $first.substring(0,1)

$lastI = $last.substring(0,1)

$firstlastname = ($first + $last)

$firstdotlastname = ($first + "." + $last)

$FirstIlastname = ($firstI + $last)

$firstnameLastI = ($first + $lastI)

Write-Host ($firstdotlastname)