param ( #define parameter list
    [string]$LocNum,
    [string]$EmpNum,
    [string]$Name,
    [string]$JobTitle
)


#eventually this would be replaced by the new user script.


Write-Host ("`n==============test.ps1==================")
#Output contents to ensure they are correct
Write-Host("`nLocation number in test.ps1 is: $LocNum`n")
Write-Host("Employee Number in test.ps1 is: $EmpNum`n")
Write-Host("Name in test.ps1 is: $Name`n")
Write-Host("Job Title in test.ps1 is: $JobTitle`n")
