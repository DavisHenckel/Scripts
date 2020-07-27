#Written By Davis Henckel. May 2020

#////////////////-Last Update 7/21/2020-////////////////
#Script is used to Delete and cleanup all data from an Outlook profile
#This script also re-imports PSTs that were imported in the profile.

#Getting Outlook Profile and PST info
Write-Host "=====================================================================================`n" -ForegroundColor Cyan
Write-Host "Note that shared inboxes will need to be imported manually"
Write-Host "Gathering imported PST information..."
$outlook = New-Object -ComObject 'Outlook.Application' -ErrorAction 'Stop' #Load Outlook object from current user's profile
$pstObjects = $outlook.GetNameSpace('MAPI').Stores | Where-Object {$_.ExchangeStoreType -eq 3} #Get all Outlook PSTs
[string] $desktopPath = $env:APPDATA + '../../../Desktop'
[int] $flag = 0 #keeps track of whether Skype was open
[int] $counter = 0 #counts total PSTs to import later
if (-not $pstObjects) #if there aren't any PSTs
{
    Write-Host "No PSTs imported"
}
else
{
    $pstObjects.size
    foreach($pst in $pstObjects)
    {
        cd $desktopPath
        $pst.FilePath | Out-File "PST Files.txt" -Append #add the PST path to the file
        $counter += 1 #increment the counter
    }
    Write-Host "All Imported PST file paths written to file on Desktop titled: PST Files.txt" -ForegroundColor Green
}
Write-Host "`n=====================================================================================`n" -ForegroundColor Cyan
Start-Sleep -s 2

#CLOSING OUTLOOK AND SKYPE
Write-Host "Ensuring Outlook and Skype are closed..."
Start-Sleep -s 2
$OutlookPID = Get-Process -Name outlook -ErrorAction SilentlyContinue
if (-not $?) 
{ 
    Write-Host "`nOutlook wasn't open"
}
else
{
    Stop-Process $OutlookPID
    Write-Host "`nOutlook Closed" -ForegroundColor Green
}
$SkypePID = Get-Process -Name lync -ErrorAction SilentlyContinue
if (-not $?) 
{ 
    Write-Host "`nSkype wasn't open"
}
else
{
    Stop-Process $SkypePID 
    Write-Host "`nSkype Closed" -ForegroundColor Green
    $SkypeFlag = 1
}
Write-Host "`n=====================================================================================`n" -ForegroundColor Cyan
Start-Sleep -s 2

#DELETING PROFILES VIA REGISTRY
Write-Host "Deleting Outlook Profiles...`n"
$regPath="HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles" #defines registry path for Outlook 2016
$profiles=(Get-ChildItem -Path $regPath).Name 
foreach($prof in $profiles) #find every child item (every profile)
{
    Remove-Item -Path registry::$prof -Recurse #delete the profile
}
$profiles=(Get-ChildItem -Path $regPath).Name
if (-not $profiles) #if the profiles are empty
{
    Write-Host "Profiles removed successfully`n" -ForegroundColor Green
}
else #a profile still exists
{
    Write-Host "ERROR! Not all profiles removed.`n" -ForegroundColor Red
    cmd /c pause
    Write-Host "=====================================================================================`n" -ForegroundColor Cyan
    exit(1)
}

#DELETING TEMP FILES IN APPDATA ROAMING AND LOCAL
Start-Sleep -s 2
Write-Host "`n=====================================================================================`n" -ForegroundColor Cyan
[string] $roamingAppData = $env:APPDATA + "/Microsoft/Outlook/" #define roamingAppData path
[string] $localAppData = $roamingAppData + "../../../local/Microsoft/Outlook/"#define localAppData path
cd $localAppData #navigate to local Appdata
Write-Host "Before Deleting items in Local Appdata...`n"
dir -Force #print current directory pre deletion
Start-Sleep -s 5
Remove-Item * -Include *.ost, *.obi, *.inf, *.xml, *.tmp, *.dat -Force -ErrorAction SilentlyContinue -Exclude *pst #delete all garbage files
Remove-Item "Offline Address Books", "RoamCache" -Recurse -ErrorAction SilentlyContinue #delete all garbage files
Write-Host "`nAfter Deleting...`n"
dir -Force #print current directory post deletion
Write-Host "`n=====================================================================================`n" -ForegroundColor Cyan

Start-Sleep -s 3
cd $roamingAppData #navigate to roaming appdata
Write-Host "Before deleting items in Roaming Appdata...`n"
dir -Force #print current directory pre deletion
Start-Sleep -s 5
Remove-Item * -Include *.srs, *.xml -Force -Exclude *pst, *ASK ODOT*, *ASK_ODOT*, *ASKODOT* -ErrorAction SilentlyContinue #delete all garbage items
Write-Host "`nAfter Deleting...`n"
dir  -Force #print current directory post deletion
Write-Host "`n=====================================================================================" -ForegroundColor Cyan

#ADDING NEW PROFILES AND RELAUNCHING OUTLOOK & SKYPE
Write-Host "Cleanup complete! Creating a new profile titled: NewProfile" -ForegroundColor Green
cmd /c reg add HKCU\Software\Microsoft\Office\16.0\Outlook\Profiles\NewProfile #adds the new profile titled NewProfile in the registry
cmd /c reg add "HKCU\Software\Microsoft\Office\16.0\Outlook" /v DefaultProfile /t REG_SZ /d "NewProfile" /F #sets new profile to default
Write-Host "New profile added.`n" -ForegroundColor Green
Write-Host "`n=====================================================================================" -ForegroundColor Cyan

#STARTING OUTLOOK
Write-Host "Starting Outlook..."
    while(1)
{
    $isReady = Read-Host "Type YES when Outlook has fully launched ans is ready to import PSTs." 
    if ($isReady -eq "YES")
    {
        Write-Host "Proceeding with imports..." -ForegroundColor Green 
        break
    }
    Write-Host "Invalid Input enter YES when ready to continue" -ForegroundColor Red #deals with bad input.
    continue #continue to the next iteration until user provides appropriate input.
}
Start-Process -FilePath "outlook" -WindowStyle Maximized #re-open Outlook
Start-Sleep -s 30 #wait at least 30 seconds for it to load...
if ($counter -ne 0)
{
    Write-Host "Now importing PSTs..." -ForegroundColor Green
    Add-type -assembly "Microsoft.Office.Interop.Outlook" | out-null
    $outlookProf = new-object -comobject outlook.application #retrieves the new Outlook Profile object
    $namespace = $outlookProf.GetNameSpace("MAPI") 
    $thePSTs = (Get-Content -Path $desktopPath/"PST Files.txt" -TotalCount $counter) #store all PSTs in $thePSTs
    foreach($path in $thePSTs)
    {
        dir “$path” | % { $namespace.AddStore($_.FullName) } #import all PSTs into the new profile
    }
}

if ($SkypeFlag -eq 1) #if Skype was open before, re-open it
{
   start lync.exe 
}
if ($counter -ne 0)
{
    while(1)
    {
        $myVar = Read-Host "Keep the PST Files.txt folder on the desktop? (y/n)" 
        if ($myVar -eq "y" -or $myVar -eq "Y")
        {
            Write-Host "PST Files.txt remains on desktop" -ForegroundColor Green 
            break
        }
        elseif($myVar -eq "n" -or $myVar -eq "N")
        {
            Remove-Item $desktopPath/"PST Files.txt"
            Write-Host "PST Files.txt Deleted." -ForegroundColor Green
            break
        }
        Write-Host "Invalid Input" -ForegroundColor Red #deals with bad input.
        continue #continue to the next iteration until user provides appropriate input.
    }
}
Write-Host "`n=====================================================================================" -ForegroundColor Cyan
Write-Host "`Program Complete.`nNote that shared inboxes will need to be imported manually." -ForegroundColor Yellow
cmd /c pause
