#Written by Davis Henckel August 20, 2020

#Displays the basic GUI for the program
Function MenuPrompt {
    while(1) {
        Clear-Host
        Write-Host Outlook Repair Tool Menu -ForegroundColor Green
        Write-Host ====================================================================================== -ForegroundColor DarkCyan
        Write-Host Available Options:`n 
        Write-Host 0: Run all commands in sequence -ForegroundColor DarkYellow
        Write-Host 1: Export PST data -ForegroundColor DarkYellow
        Write-Host 2: Close Outlook`, Teams`, and Skype -ForegroundColor DarkYellow
        Write-Host 3: Delete ALL Outlook profiles -ForegroundColor DarkYellow
        Write-Host 4: Delete Outlook profile application data -ForegroundColor DarkYellow
        Write-Host 5: Create new Outlook profiles -ForegroundColor DarkYellow
        Write-Host 6: Start Outlook -ForegroundColor DarkYellow
        Write-Host 7: Import PSTs `(must be run after Exporting PST data prior to deleting the profile`) -ForegroundColor DarkYellow
        Write-Host 8: Exit`n -ForegroundColor DarkYellow
        Write-Host ====================================================================================== -ForegroundColor DarkCyan
        $userInput = Read-Host "What would you like to do? Enter 1-8"
        if ($userinput -eq '8') {
            exit(0)
        }
        if ($userInput -eq '1' -or $userInput -eq '2' -or $userInput -eq '3' -or $userInput -eq '4' -or $userInput -eq '5' -or $userInput -eq '6' -or $userInput -eq '7' -or $userInput -eq '0') {
            return $userInput
        }
        else {
            Write-Host Invalid Input. Please enter an option 1-8 -ForegroundColor DarkRed
            Start-Sleep -s 2
        }
    }
}

#Exports all PST paths to a folder on desktop called PST Files.txt
Function ExportPSTInfo {
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
    Write-Host This will output file paths to all imported PSTs within the Default Outlook profile to`na file on the desktop called `"PST Files.txt`"  -ForegroundColor DarkGreen
    Write-Host This can later be used to import PSTs using option number `7 when a profile is rebuilt -ForegroundColor DarkGreen
    Start-Sleep 8
    Write-Host Exporting PST data... -ForegroundColor DarkGreen
    $outlook = New-Object -ComObject 'Outlook.Application' -ErrorAction 'Stop' #Load Outlook object from current user's profile
    $pstObjects = $outlook.GetNameSpace('MAPI').Stores | Where-Object {$_.ExchangeStoreType -eq 3} #Get all Outlook PSTs
    [string] $desktopPath = $env:APPDATA + '../../../Desktop'
    if (-not $pstObjects) #if there aren't any PSTs
    {
        Write-Host "No PSTs imported" -ForegroundColor DarkGreen
    }
    else
    {
        $pstObjects.size
        foreach($pst in $pstObjects)
        {
            Set-Location $desktopPath
            Write-Host Writing $pst.FilePath to PST Files.txt
            $pst.FilePath | Out-File "PST Files.txt" -Append #add the PST path to the file
        }
        Write-Host "All Imported PST file paths written to file on Desktop titled: PST Files.txt" -ForegroundColor Green
    }
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
}

#Closes Outlook, Teams, and Skype. They must be closed to perform profile deletion along with other things
Function CloseOutlook {
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
    Write-Host Closing Programs... -ForegroundColor DarkGreen
    $OutlookPID = Get-Process -Name outlook -ErrorAction SilentlyContinue
    if (-not $?)  { 
        Write-Host `nOutlook wasn`'t open. -ForegroundColor DarkGreen
    }
    else {
        Stop-Process $OutlookPID
        Write-Host "`nOutlook Closed" -ForegroundColor DarkGreen
    }
    Start-Sleep 1
    $SkypePID = Get-Process -Name lync -ErrorAction SilentlyContinue
    if (-not $?) { 
        Write-Host `nSkype wasn`'t open. -ForegroundColor DarkGreen
    }
    else {
        Stop-Process $SkypePID 
        Write-Host "`nSkype Closed" -ForegroundColor DarkGreen
    }
    Start-Sleep 1
    $TeamsPID = Get-Process -Name "Teams" -ErrorAction SilentlyContinue
    if (-not $?) {
        Write-Host `nTeams wasn`'t open. -ForegroundColor DarkGreen
    }
    else {
        Stop-Process $TeamsPID
        Write-Host "`nTeams Closed" -ForegroundColor DarkGreen
    }
    Write-Host ====================================================================================== -ForegroundColor DarkCyan

}

#Opens Outlook
Function OpenOutlook { 
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
    Write-Host Starting Outlook... -ForegroundColor DarkGreen
    Start-Process -FilePath "outlook" -WindowStyle Maximized 
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
}

#Imports PSTs once Outlook is open from PST Files.txt
Function ImportPSTs {
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
    Write-Host "Importing PSTs from Desktop/PST Files.txt..." -ForegroundColor DarkGreen
    [string] $pstPath = $env:APPDATA + '../../../Desktop/PST Files.txt'
    if (-not (Test-Path $pstPath))
    {
        Write-Host "PST Files.txt is not found on the desktop. Did you export PST data first?" -ForegroundColor Red
        Start-Sleep 2
        Write-Host ====================================================================================== -ForegroundColor DarkCyan
        return
    }
    Add-type -assembly "Microsoft.Office.Interop.Outlook" | out-null
    $outlookProf = new-object -comobject outlook.application #retrieves the new Outlook Profile object
    $namespace = $outlookProf.GetNameSpace("MAPI") 
    $thePSTs = (Get-Content -Path $pstPath) #store all PSTs in $thePSTs
    foreach($path in $thePSTs)
    {
        Get-ChildItem “$path” | ForEach-Object { $namespace.AddStore($_.FullName) } #import all PSTs into the new profile
    }
    Remove-Item $pstPath #Delete file after import complete.
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
}

#Deletes Outlook profiles by deleting reg keys
Function DeleteProfiles {
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
    Write-Host Before you do this`, be sure to notate any shared mailboxes as they won`'t be`n re-imported. Also be aware this deletes all Outlook profiles, not just the active one. -ForegroundColor Red
    while (1) {
        $proceed = Read-Host Do you want to proceed? `(y/n`)
        if ($proceed -eq 'n' -or $proceed -eq 'N') {
            return 
        }
        if ($proceed -eq 'y' -or $proceed -eq 'Y') {
            break
        }
        Write-Host Invalid Input. Please enter y or n. -ForegroundColor Red
    }
    Write-Host "Deleting Outlook Profiles..." -ForegroundColor DarkGreen
    $regPath="HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles" #defines registry path for Outlook 2016
    $profiles=(Get-ChildItem -Path $regPath).Name 
    foreach($prof in $profiles) #find every child item (every profile)
    {
        Remove-Item -Path registry::$prof -Recurse #delete the profile
    }
    $profiles=(Get-ChildItem -Path $regPath).Name
    if (-not $profiles) #if the profiles are empty
    {
        Write-Host "Profiles removed successfully`n" -ForegroundColor DarkGreen
    }
    else #a profile still exists
    {
        Write-Host "ERROR! Not all profiles removed.`n" -ForegroundColor DarkRed
    }
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
}

#Follows ODOT Documentation for deleting application data when removing a profile
Function DeleteAppdata {
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
    [string] $roamingAppData = $env:APPDATA + "/Microsoft/Outlook/" #define roamingAppData path
    [string] $localAppData = $roamingAppData + "../../../local/Microsoft/Outlook/"#define localAppData path
    Set-Location $localAppData #navigate to local Appdata
    Write-Host "Before Deleting items in Local Appdata...`n" -ForegroundColor DarkGreen
    Get-ChildItem -Force #print current Get-ChildItemectory pre deletion
    Start-Sleep -s 5
    Remove-Item * -Include *.ost, *.obi, *.inf, *.xml, *.tmp, *.nst, *.log, *.dat, ~* -Exclude *.pst -Force
    Remove-Item "Offline Address Books", "RoamCache" -Recurse -ErrorAction SilentlyContinue  -Force
    Write-Host "`nAfter Deleting...`n" -ForegroundColor DarkGreen
    Get-ChildItem -Force #print current Get-ChildItemectory post deletion
    Write-Host "`n=====================================================================================`n" -ForegroundColor DarkCyan

    Start-Sleep -s 3
    Set-Location $roamingAppData #navigate to roaming appdata
    Write-Host "Before deleting items in Roaming Appdata...`n" -ForegroundColor DarkGreen
    Get-ChildItem -Force #print current Get-ChildItemectory pre deletion
    Start-Sleep -s 5
    Remove-Item * -Include *.srs, *.xml, *.log, *.dat, ~* -Exclude *pst -Force
    Write-Host "`nAfter Deleting...`n" -ForegroundColor DarkGreen
    Get-ChildItem  -Force #print current Get-ChildItemectory post deletion
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
}

#Creates a new profile in the registry
Function CreateNewProfile {
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
    Write-Host Creating new profile titled `"NewProfile`" -ForegroundColor DarkGreen
    cmd /c reg add HKCU\Software\Microsoft\Office\16.0\Outlook\Profiles\NewProfile #adds the new profile titled NewProfile in the registry
    cmd /c reg add 'HKCU\Software\Microsoft\Office\16.0\Outlook' /v DefaultProfile /t REG_SZ /d "NewProfile" /F #sets new profile to default
    Write-Host New profile added! -ForegroundColor DarkGreen
    Write-Host ====================================================================================== -ForegroundColor DarkCyan
}

#Interprets user input using a switch statement to choose the appropriate function based on input
Function InterpretInput($userInput) {
    $userInput = [int]$userInput
    #Typically these would be run in sequence, if all goes well
    Switch ($userInput) {
        0 { RunAll }
        1 { ExportPSTInfo }
        2 { CloseOutlook }
        3 { DeleteProfiles }
        4 { DeleteAppdata }
        5 { CreateNewProfile }
        6 { OpenOutlook }
        7 { ImportPSTs }
    }
}

#Runs every command in sequence
Function RunAll {
    ExportPSTInfo
    Start-Sleep 1
    CloseOutlook
    Start-Sleep 1
    DeleteProfiles
    Start-Sleep 1
    DeleteAppData
    Start-Sleep 1
    CreateNewProfile
    Start-Sleep 1
    OpenOutlook
    Start-Sleep 1
    ImportPSTs
}

#Main Script that displays the prompt until the user presses CTRL C or presses 8 to exit. Pauses breifly after each function to show output
Function Main {
    while(1) {
        [string] $userInput = MenuPrompt #display the menu
        InterpretInput($userInput) #take appropriate action based on input
        Write-Host Returning to main menu... -ForegroundColor Yellow
        Start-Sleep -s 3 #pause to show output briefly
    }
}

#Calls main script
Main