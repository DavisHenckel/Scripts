#============================================================================================
#Improvement Ideas:

#   All done! Now just test thoroughly

#============================================================================================

#Taken from New_User_Script_2020 -- This makes the screen black if we are in an elevated shell
#Added the two imports for the requires modules
Function SetupEnvironment {
    Import-Module ImportExcel
    Import-Module ActiveDirectory
    $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

    # Get the security principal for the Administrator role
    $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

    # Check to see if we are currently running "as Administrator"
    if ($myWindowsPrincipal.IsInRole($adminRole)) {
    # We are running "as Administrator" - so change the title and background color to indicate this
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
    $Host.UI.RawUI.BackgroundColor = "Black"
    clear-host
    }
}

#Collects user input based off template sent from HR 
#This will not collect lines with less than 2 characters to avoid collecting empty lines.
#This will also ensure there are at least 5 lines since we need at least that many parameters.
Function GetUserInput {
    $InputParams = [System.Collections.ArrayList]@()
    Write-Host("Paste email contents from HR (Enter 2 blank lines to stop collecting input):`n") -ForegroundColor Cyan
    $UserInput = $null
    $Flag = 0 #Keeps track of blank lines 1 means there was a blank line last iteration, 2 consecutive blank lines will end the loop.
    while(1) {
        $UserInput = Read-Host
        if ($UserInput.Length -lt 2) { #this is an empty line
            if ($Flag -eq 1) { #if flag already set to 1, we encountered a blank line last iteration
                break #exit the loop 2 consecutive blank lines
            }
            else {
                $Flag = 1
                continue #don't add an empty line to the array
            }
        }
        else { #if curret line is not a blank lines.
            $Flag = 0 #reset flag
        }
        $InputParams.Add($UserInput) | Out-Null #prevent adding integers to the arraylist

    }
    if($InputParams.Count -lt 4) {
        Write-Host "Not enough input given. Restarting program...." -ForegroundColor Red
        Start-Sleep -s 1.5
        Clear-Host
        GetUserInput #collect input again.
    }
    return $InputParams
}

#Ensures input given is in a valid format. After this function is run, there should only be 5 Entries in the array list
#Input to this function must be given in the correct order. The program doesn't yet parse the data out of order. 
#Input must be given in the order shown in lines 72-76
#This will also remove any duplicate spaces if there were typos in the template
#Example entries in the arraylist will look like this
#0: Dept / Location: [data]
#1: Employee Number:[data]
#2: User Name:[data]
#3: Preferred Name for Email: [data]
#4: Job Title: [data]
Function ValidateInput ($UserInfoArgs) { 

    for ($i = 0; $i -lt $UserInfoArgs.Count; $i++) { #If a line is not valid or doesn't contain what we are looking for. Remove it from the list entirely and decrement counter
        while ($UserInfoArgs[$i] -match "  ") { #while there are duplicate spaces in the current line   
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("  "," ") #remove duplicate spaces if there are typos
        }
        $StrLen = $UserInfoArgs[$i].length
        $Temp = $UserInfoArgs[$i]
        if ($Temp[$StrLen - 1] -eq " ") { #If the last char in the string is a space, remove it.
            $UserInfoArgs[$i] = $UserInfoArgs[$i].SubString(0, ($StrLen - 1))
        }
        if ($i -eq 0 -and ($UserInfoArgs[$i] -Match "Dept" -eq 0 -or $UserInfoArgs[$i] -Match "Location" -eq 0)) { #validate first line
            $UserInfoArgs.Remove($UserInfoArgs[$i])
            if ($i -eq $UserInfoArgs.Count) {
                Write-Host "Never found Location Number... Check format and try again" -ForegroundColor Red
                Start-Sleep 1.5
                Clear-Host
                break
            }
            $i--
            continue
        }
        if ($i -eq 1 -and ($UserInfoArgs[$i] -Match "Employee Number" -eq 0)) { #validate second line
            $UserInfoArgs.Remove($UserInfoArgs[$i])
            if ($i -eq $UserInfoArgs.Count) {
                Write-Host "Never found Employee Number... Check format and try again" -ForegroundColor Red
                Start-Sleep 1.5
                Clear-Host
                break
            }
            $i--
            continue
        }
        if ($i -eq 2 -and ($UserInfoArgs[$i] -Match "User Name" -eq 0)) { #validate third line
            $UserInfoArgs.Remove($UserInfoArgs[$i])
            if ($i -eq $UserInfoArgs.Count) {
                Write-Host "Never found User Name... Check format and try again" -ForegroundColor Red
                Start-Sleep 1.5
                Clear-Host
                break
            }
            $i--
            continue
        }
        if ($i -eq 3 -and ($UserInfoArgs[$i] -Match "Preferred Name for Email" -eq 0)) { #validate fourth line
            $UserInfoArgs.Remove($UserInfoArgs[$i])
            if ($i -eq $UserInfoArgs.Count) {
                Write-Host "Never found Prefered name for Email... Check format and try again" -ForegroundColor Red
                Start-Sleep 1.5
                Clear-Host
                break
            }
            $i--
            continue
        }
        if ($i -eq 4 -and ($UserInfoArgs[$i] -Match "Job Title" -eq 0)) { #validate fifth line
            $UserInfoArgs.Remove($UserInfoArgs[$i])
            if ($i -eq $UserInfoArgs.Count) {
                Write-Host "Never found Job Title... Check format and try again" -ForegroundColor Red
                Start-Sleep 1.5
                Clear-Host
                break
            }
            $i--
            continue
        }
        elseif ($i -gt 4) {
            $UserInfoArgs.Remove($UserInfoArgs[$i]) #remove the line since these are the only 5 that will enter data into AD.
            $i--
        }                
    }
    return $UserInfoArgs
}

#Interprets the Validated Input and puts them in a new arraylist with the actual parameters to be passed.
#This will strip all text that is not the parameter. It will also set the User Name to be the Preferred name for email if that line wasn't empty
#Example input after this function would be '//' is just a way to show what the data corresponds to. It is not included in the array
#0: [data]          //Location Number
#1: [data]          //Employee Number
#2: [data]          //User Name
#3: [data]          //Preferred Name for Email (may be empty)
#4: [data]          //Job Title
#This should be refactored at some point.
Function UserInputToParameters ($UserInfoArgs) { 
    $ModifiedParams = [System.Collections.ArrayList]@()
    for ($i = 0; $i -lt $UserInfoArgs.Count; $i++) {
        if ($i -eq 0) { #================= Location Code Validation =================
            $LocationCode = ValidateLocationCode($UserInfoArgs[$i])
            $ModifiedParams.Add($LocationCode) | Out-Null #Prevent adding integers to the arraylist
        }
        if ($i -eq 1) { #================= Employee Number Validation =================
            $EmployeeID = ValidateEmployeeID($UserInfoArgs[$i]) #validates the employee ID
            $ModifiedParams.Add($EmployeeID) | Out-Null #Prevent adding integers to the arraylist
        }
        if ($i -eq 2) {  #================= User Name Validation =================
            $UserName = ValidateUserName($UserInfoArgs[$i])
            $ModifiedParams.Add($UserName) | Out-Null #Prevent adding integers to the arraylist
        }
        if ($i -eq 3) { #================= Preferred Name for Email Validation =================
            $EmailName = ValidateEmailName($UserInfoArgs[$i]) #validates email by checking user user existence in AD returns null if nothing entered.
            if ($null -ne $EmailName) { #IF there is a preferred name for email change the user name
                $NewNameForEmail = ValidateUserName($EmailName) #ensure this user doesn't already exist in AD.
                $ModifiedParams[$i-1] = $NewNameForEmail #set the user name to the preferred name for email.
            }
        }
        if ($i -eq 4) { #================= Job Title Validation =================
            $ValidatedJob = ValidateJobTitle($UserInfoArgs[$i]) #validates job title based off access matrix spreadsheet
            $ModifiedParams.Add($ValidatedJob) | Out-Null #Prevent adding integers to the arraylist
            break; 
        }
    }
    if ($ModifiedParams.Count -ne 4) {
        Write-Host "Invalid number of lines" -ForegroundColor Red
        Start-Sleep 1.5
        Clear-Host
        return $null
    }
    return $ModifiedParams
}

#Validates data based on similar guidelines that are used in UserInputToParameters
Function IsDataValid($ArrayToValidate) { #Checks that Location Name, Employee Number and Name are valid
    $MyBool = 1 #start as true
    $LocValid = ValidateLocationCode($ArrayToValidate[0]) #validates Location code again
    $EmpValid = ValidateEmployeeID($ArrayToValidate[1]) #validates Employee ID again
    $NameValid = ValidateUserName($ArrayToValidate[2]) #validates Name again
    $JobValid = ValidateJobTitle($ArrayToValidate[3]) #validates Job Title again
    if ($null -eq $LocValid -or $null -eq $EmpValid -or $null -eq $NameValid -or $null -eq $JobValid) { 
        $MyBool = 0
    }
    return $MyBool
}

#Prints output of the 4 variables obtained from the earlier steps. 
#Returns Boolean that indicates if the input looks correct to the user.
Function ConfirmInputCorrect($ModifiedParams) {
    while(1) {
        Write-Host("Data Parsed:`n ") -ForegroundColor Cyan
        for ($i = 0; $i -lt 4; $i++) {
            switch ($i) {
                0 { $ToPrint = $ModifiedParams[$i]
                    Write-Host("Location Code: $ToPrint`n")}
                1 { $ToPrint = $ModifiedParams[$i]
                    Write-Host("Employee ID: $ToPrint`n")}
                2 { $ToPrint = $ModifiedParams[$i]
                    Write-Host("User Name: $ToPrint`n")}
                3 { $ToPrint = $ModifiedParams[$i]
                    Write-Host("Job Title: $ToPrint`n")}
                default { Write-Host("This won't ever happen") -ForegroundColor Red}
            }
        }
        $UserInput = Read-Host -Prompt ("Is the employee's information correct? (y/n)")
        if ($UserInput -eq 'y' -or $UserInput -eq 'Y') {
            break
        }
        if ($UserInput -eq 'n' -or $UserInput -eq 'N') {
            break
        }
        Clear-Host
        Write-Host("Invalid Input. Enter (y/n)`n") -ForegroundColor Red
    }
    return $UserInput
}

#This function allows a user to modify a specific portion of the data after they have pasted the template.
#Normally this will never be run, but in case there is a typo, the user can manually re-renter the data.
Function ModifyData($ModifiedParams) {
    Clear-Host
    $IncorrectIndex = -1 #start with the index as -1 to indicate we haven't entered the while loop
    $Arg1 = $ModifiedParams[0]
    $Arg2 = $ModifiedParams[1]
    $Arg3 = $ModifiedParams[2]
    $Arg4 = $ModifiedParams[3]
    While(1) {
        if ($IncorrectIndex -eq -1) { #if we are on the first iteration of the while loop.
            Write-Host "[1]: Location Number: $Arg1"
            Write-Host "[2]: Employee Number: $Arg2"
            Write-Host "[3]: User Name: $Arg3"
            Write-Host "[4]: Job Title: $Arg4"
            Write-Host "[5]: Re-enter the entire email from HR"
            Write-Host "What is not correct? Enter the number" -ForegroundColor Cyan
            try { [int32]$IncorrectIndex = Read-Host } #put in a try catch so we can interpret the input as an int later.
            catch { #if the user didn't enter an integer.
                Write-Host "Must enter a number..." -ForegroundColor Red
                Start-Sleep 1
                Clear-Host
                continue #prompt again
            }
            if ($IncorrectIndex -lt 1 -or $IncorrectIndex -gt 5) { #if the user entered a number that isn't 1-4
                Write-Host "Invalid Input enter a number 1-4" -ForegroundColor Red
                Start-Sleep 1
                Clear-Host
                $IncorrectIndex = -1
                continue #prompt again
            }
        }
        else { #now that the input is valid...
            switch ($IncorrectIndex) { #assign the new value based on the index.
                1 { $ModifiedParams[0] = Read-Host -Prompt ("Enter the correct Location Code") }
                2 { $ModifiedParams[1] = Read-Host -Prompt ("Enter the correct Employee Number") }
                3 { $ModifiedParams[2] = Read-Host -Prompt ("Enter the correct User Name") }
                4 { $ModifiedParams[3] = Read-Host -Prompt ("Enter the correct Job Title") }
                5 { return 1 } #1 will show that user wanted to re enter the entire template.
            }
            #it is safe to run IsDataValid because we already ran it once before, the only thing that could possibly be changed is the new data from this func.
            if (IsDataValid($ModifiedParams) -eq 1) { #if the new data the user entered is valid, break out of the while loop.
                return 0 #0 means 
            }
            #TODO
            else { #if for some reason the data is still not valid after the user enters it again...
                switch ($IncorrectIndex) { #display that the new input is not valid.
                    1 { Write-Host "Location Code not in valid format" -ForegroundColor Red }
                    2 { Write-Host "Employee Number not in valid format" -ForegroundColor Red }
                    3 { Write-Host "User Name not in valid format" -ForegroundColor Red }
                    4 { Write-Host "Job Title not in valid format" -ForegroundColor Red }
                }
                Start-Sleep 1.5
                Clear-Host
                continue #on the next iteration, we will not prompt the user for the invalid index, since we know what it is.
            }
        }
    }

}

#Calls New Powershell script to this function.
Function CallNewPSScript($ModifiedParams) {
    $Arg1 = $ModifiedParams[0]
    $Arg2 = $ModifiedParams[1]
    $Arg3 = $ModifiedParams[2]
    $Arg4 = $ModifiedParams[3]
    $ArgumentList = "-LocNum $Arg1 -EmpNum $Arg2 -Name `"$Arg3`" -JobTitle `"$Arg4`""
    $ScriptPath= $PSScriptRoot+"\test.ps1"
    Invoke-Expression "& `"$ScriptPath`" $ArgumentList" #jump to new script, passing the validated data
}

#Imports an Excel Sheet that has a column with all the location codes.
Function ValidateLocationCode ($LocationCode) {
    Write-Host ""
    $LocationCode = $LocationCode.Replace(" ","") #Remove all spaces 
    $LocationCode = $LocationCode.Replace("Dept/Location:","") #remove text before location num
    $IndexOfSlash = $LocationCode.IndexOf("/")
    if ($IndexOfSlash -ne -1) { #if there is a slash then do this.
        $LocationCode = $LocationCode.SubString(0,$IndexOfSlash)
    }
    Try {
        $LocCodeFile = Import-Excel \\Tech\Admin\02-ServiceDesk\Scripts\Davis\LocationCodes.xlsx
    }
    Catch {
        Write-Host "ERROR -- Could not read file. Script Exiting" -ForegroundColor Red
        cmd /c pause
        exit
    }
    $LocationCodeArray = $LocCodeFile."Location Codes"
    While (1) { #ask for location code until it is correct
        if ($LocationCodeArray.Contains($LocationCode)) {
            break
        }
        else {
            Write-Host "ERROR -- That Location Code doesn't exist. Please enter a valid Location Code" -ForegroundColor Red
            $LocationCode = Read-Host
        }
    }
    return $LocationCode
}

#Validates EmployeeID by checking in AD if the Employee ID exists, and making sure numeric characters less than 6 digits only
Function ValidateEmployeeID ($EmployeeID) {
    $EmployeeID = $EmployeeID.Replace(" ","") #Remove all spaces
    $EmployeeID = $EmployeeID.Replace("EmployeeNumber:","")
    While (1) {
        if ($EmployeeID -match "^\d+$" -eq 0 -or $EmployeeID.length -gt 5) { #checks for length and ensures it is numeric and less than 6 chars
            Write-Host ("`nERROR, Employee ID contains non numeric characters`n") -ForegroundColor Red
            $EmployeeID = Read-Host -Prompt ("Enter the correct Employee ID")
            continue
        }
        $UserTest = Get-ADUser -Filter {employeeID -eq $EmployeeID}
        if ($null -ne $UserTest) {
            Write-Host "User Already exists in AD." -ForegroundColor Red
            $EmployeeID = Read-Host -Prompt ("Enter the correct Employee ID")
            continue
        }
        else {
            return $EmployeeID
        }
    }
}

#checks in AD to ensure the user doesn't already exist.
Function ValidateUserName ($UserName) {
    $UserName= $UserName.Replace("User Name: ","") 
    if ($UserName -match "-" -eq 1) { #if there is multiple last name. Only use the first.
        $UserName = $UserName.SubString(0, $UserName.IndexOf('-'))
    }
    $UserTest = Get-ADUser -Filter {Name -eq $UserName} #check if user exists. This was taken from New_User_Script_2020.ps1
    if ($null -ne $UserTest) { #if a user exists with this name
        Write-Host "User Already exists in AD. Exiting..." -ForegroundColor Red
        cmd /c pause
        exit
    }
    else {
        return $UserName
    }
}

#Validates email name and retuns null if there is no entry.
#If there is an entry, it will ensure the user doens't exist in AD already.
Function ValidateEmailName ($EmailName) {
    $EmailName = $EmailName.Replace(" ","") #Remove spaces if they exist
    while (1) {
        if ($EmailName -eq "PreferredNameforEmail:" -or $EmailName -eq "") {
            return $null
        }
        else {
            $LengthAfterDotRemoval = $EmailName.replace(".","").Length
            if (($EmailName -match "@wilco.coop" -eq 0 -and ($EmailName -match "@hazelnut.com" -eq 0)) -or ($EmailName.Length - ($LengthAfterDotRemoval) -ne 2)) { #ensures there are 2 periods, and there is an @wilco.coop or a @hazelnut.com
                Write-Host ("`nERROR, Invalid Format to Preferred Name for Email.") -ForegroundColor Red
                Write-Host ("`nFormat is: FirstName.LastName@wilco.coop or FirstName.LastName@hazelnut.com`nPress enter if there isn't a preferred email") -ForegroundColor White
                $EmailName = Read-Host -Prompt ("Enter preferred name for email")
                continue
            }
            else { #if the format is valid
                $EmailName = $EmailName.Replace("PreferredNameforEmail:","")
                $EmailName = $EmailName.Replace("."," ") #Replace . with space to fit name format    
                $EmailName = $EmailName.SubString(0, $EmailName.IndexOf('@'))
                return $EmailName       
            }
        }
    }
}

#Imports the access matrix excel sheet with all the valid Job titles.
#Makes exceptions for jobs like Retail Stocker/Ecomm or Retail Salesperson - DEPTName
Function ValidateJobTitle ($JobTitle) {
    Write-Host ""
    $JobTitle = $JobTitle.Replace("Job Title: ","")
    Try {
        Write-Host "`nReading in Job Titles from the Access Matrix Spreadsheet to validate job title..." -ForegroundColor Cyan
        $AccessMatrixFile = Import-Excel \\Tech\Admin\02-ServiceDesk\Scripts\Davis\AccessFormMatrixCopy.xlsm -WorksheetName RawSecurity #Load the RawSecurity Worksheet
    }
    Catch {
        Write-Host "ERROR -- Could not read file. Exiting" -ForegroundColor Red
        cmd /c pause
        exit
    }
    Write-Host "Read Data From Access Matrix Successfully.`n`n" -ForegroundColor Green
    $JobTitleArray = $AccessMatrixFile."Job Titles"
    While (1) { #infinite loop
        if ($JobTitleArray.Contains($JobTitle)) {
            return $JobTitle
        }
        elseif ($JobTitle -match "Retail Salesperson") { #if the job contains Retail Salesperson, the endings are not entered in access matrix so we can't perfectly validate
            return $JobTitle
        }
        elseif ($JobTitle -match "Retail Stocker/Ecomm") { #if the job contains Retail Stocker, the endings are not entered in access matrix so we can't perfectly validate
            return $JobTitle
        }
        Write-Host "`nERROR -- That Job Title doesn't exist. Please enter a valid Job Title.`n" -ForegroundColor Red
        $JobTitle = Read-Host
    }
}
#Main function -- Don't need this to be a function. Just my preference
#This function controls the program flow and calls the new user script after data has been validated.
Function Main { 
    SetupEnvironment
    Write-Host ("============================================================================") -ForegroundColor Yellow
    Write-Host ("`n================================= NEW HIRE =================================`n") -ForegroundColor Yellow
    Write-Host ("============================================================================`n") -ForegroundColor Yellow
    $Proceed = 'N'
    $Result = 0 #This is used in the 2nd while loop, where we ask the user if they want to modify the data.
    while($Proceed -ne 'y' -or $Proceed -ne 'Y') { #loop forever until user says input is correct
        [System.Collections.ArrayList]$UserInfoData = GetUserInput #collects raw input, ignores blank & irrelevant lines. It also ensures there are at least 4 lines
        if ($UserInfoData.Count -lt 3) {
            continue #get user input again
        }
        $UserInfoData = ValidateInput($UserInfoData) #deletes lines that are not relevant and ensures there are 4 lines that contain the variables we want
        [System.Collections.ArrayList]$ModifiedParams = UserInputToParameters($UserInfoData) #Parses the data and stores the 4 variables to pass to the new user script
        if ($null -eq $ModifiedParams) { #this becomes null if there are not 4 lines that contain the variables we want.
            continue #get user input again.
        }
        $Proceed = ConfirmInputCorrect($ModifiedParams) #get new value for proceed y if user selects y, n if user selects n. Will loop until 
        if ($Proceed -eq 'y' -or $Proceed -eq 'Y') {
            CallNewPSScript($ModifiedParams) #execute new script
            cmd /c pause 
            exit 
        }
        elseif ($Proceed -eq 'N' -or $Proceed -eq 'n') { 
            While (1) { #loop until user says it's correct
                $Result = ModifyData($ModifiedParams) #allows the user to modify the data. if the function returns 1, the user opted to re-enter the template.
                if ($Result -eq 1) {
                    break #leave the loop. The user wants to re-enter the entire template.
                }
                $Proceed = ConfirmInputCorrect($ModifiedParams) #now that the data has been modified, confirm once again that the input is correct
                if ($Proceed -eq 'Y' -or $Proceed -eq 'y') {
                    break
                }
                else { #if the input is not correct, jump into the first line of while loop and run ModifyData again.
                    continue
                }
            }
            if ($Result -eq 1) { #if the user opted to re-enter the entire template
                continue
            }
            CallNewPSScript($ModifiedParams) #execute new script
            cmd /c pause
            exit
        }
        else {
            Write-Host "Proceed is not y or n...something is wrong...`nExiting"
            cmd /c pause
            exit
        }    
    }
}

Main #call main function
