param ( #define parameter list
    [string]$LocNum,
    [string]$EmpNum,
    [string]$Name,
    [string]$JobTitle
)

#Output contents to ensure they are correct
Write-Host("`nLocation number in test.ps1 is:$LocNum")
Write-Host("Employee Number in test.ps1 is:$EmpNum")
Write-Host("Name in test.ps1 is:$Name")
Write-Host("Job Title in test.ps1 is:$JobTitle")
