#============================================================================================
#Improvement Ideas:

#   Allow Employee Number to be 1,2,3,4, or 5 digits
#   Refactor UserInputToParameters into several functions. Probably one function for each line
#   Validate Job Titles -- maybe with excel import

#============================================================================================

#Taken from New_User_Script_2020 -- This makes the screen black if we are in an elevated shell
Function SetupEnvironment {
    

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
    $IsAddedLoc = 0 #flag to keep track of whether the location has already been added
    $IsAddedEmp = 0 #flag to keep track of whether the Employee num has already been added
    $IsAddedPrefNameEmail = 0 #flag to keep track of whether the pref email name has already been added
    for ($i = 0; $i -lt $UserInfoArgs.Count; $i++) {
        #================= Location Code Validation -- Should Make this a function at some point ================= 
        if ($i -eq 0) { 
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace(" ","") #Remove all spaces 
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("Dept/Location:","") #remove text before location num
            if ($IsAddedLoc -eq 0) { #there won't be a / if we re-entered it
                $IndexOfSlash = $UserInfoArgs[$i].IndexOf("/")
                $UserInfoArgs[$i] = $UserInfoArgs[$i].SubString(0,$IndexOfSlash)
            }
            if ($UserInfoArgs[$i].Length -ne 3 -or $UserInfoArgs[$i] -match "^\d+$" -eq 0) { #checks for length and ensures it is numeric.
                Write-Host ("`nERROR, Location Code is not 3 digits or contains non numeric characters.") -ForegroundColor Red
                $UserInfoArgs[$i] = Read-Host -Prompt ("Enter the correct Location Code")
                if ($IsAddedLoc -eq 1) {
                    $ModifiedParams[$i] = ($UserInfoArgs[$i]) #replace past value if it has already been added
                }
                else {
                    $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null
                }
                $i-- #decrement i so we will validate this again.
                $IsAddedLoc = 1 #set the flag to know we have already added this value -- don't add again
                continue
            }
            elseif ($IsAddedLoc -eq 0) { #only add if the flag is false
                $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null #prevent adding integers to the arraylist
            }
        }
        #================= End Of Location Code Validation =================


        #================= Employee Number Validation -- Should Make this a function at some point ================= 
        if ($i -eq 1) { 
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace(" ","") #Remove all spaces
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("EmployeeNumber:","")
            if ($UserInfoArgs[$i].Length -ne 4 -or $UserInfoArgs[$i] -match "^\d+$" -eq 0) { #checks for length and ensures it is numeric.
                Write-Host ("`nERROR, Employee ID is not 4 digits or contains non numeric characters.`n") -ForegroundColor Red
                $UserInfoArgs[$i] = Read-Host -Prompt ("Enter the correct Employee ID")
                if ($IsAddedEmp -eq 1) {
                    $ModifiedParams[$i] = ($UserInfoArgs[$i]) #replace past value if it has already been added
                }
                else {
                    $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null
                }
                $i-- #decrement i so we will validate this again.
                $IsAddedEmp = 1 #set the flag to know we have already added this value -- don't add again
                continue
            }
            elseif ($IsAddedEmp -eq 0) { #only add if the flag is false
                $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null #prevent adding integers to the arraylist
            }
            
        }
        #================= End Of Employee Number Validation =================


        #================= User Name Validation -- Should Make this a function at some point =================
        if ($i -eq 2) { 
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("User Name: ","") 
            if ($UserInfoArgs[$i] -match "-" -eq 1) { #if there is multiple last name. Only use the first.
                $UserInfoArgs[$i] = $UserInfoArgs[$i].SubString(0, $UserInfoArgs[$i].IndexOf('-'))
            }
            $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null #prevent adding integers to the arraylist
        }
        #================= End Of User Name Validation =================


        #================= Preferred Name for Email Validation -- Should Make this a function at some point =================
        if ($i -eq 3) { 
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace(" ","") #Remove spaces if they exist
            if ($UserInfoArgs[$i] -eq "PreferredNameforEmail:" -or $UserInfoArgs[$i] -eq "") {
                continue
            }
            else {
                $LengthAfterDotRemoval = $UserInfoArgs[$i].replace(".","").Length
                if (($UserInfoArgs[$i] -match "@wilco.coop" -eq 0 -and ($UserInfoArgs[$i] -match "@hazelnut.com" -eq 0)) -or ($UserInfoArgs[$i].Length - ($LengthAfterDotRemoval) -ne 2)) { #ensures there are 2 periods, and there is an @wilco.coop
                    Write-Host ("`nERROR, Invalid Format to Preferred Name for Email.") -ForegroundColor Red
                    Write-Host ("`nFormat is: FirstName.LastName@wilco.coop`nPress enter if there isn't a preferred email:") -ForegroundColor White
                    $UserInfoArgs[$i] = Read-Host -Prompt ("Enter preferred name for email")
                    $i-- #decrement i
                    continue
                }
                elseif ($IsAddedPrefNameEmail -eq 0) { #only add if the flag is false
                    $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("PreferredNameforEmail:","")
                    $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("."," ") #Replace . with space to fit name format    
                    $UserInfoArgs[$i] = $UserInfoArgs[$i].SubString(0, $UserInfoArgs[$i].IndexOf('@'))
                    $ModifiedParams[2] = $UserInfoArgs[$i] # set name to be the email name for easier AD modifications after the script is ran           
                }
            }
        }
        #================= End Of Preferred Name for Email Validation =================

        
        if ($i -eq 4) {
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("Job Title: ","")
            $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null #prevent adding integers to the arraylist
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
    if ($ArrayToValidate[0].Length -ne 3 -or $ArrayToValidate[0] -match "^\d+$" -eq 0) {
        $MyBool = 0
    }
    if ($ArrayToValidate[1].Length -ne 4 -or $ArrayToValidate[1] -match "^\d+$" -eq 0) {
        $MyBool = 0
    }
    if ($ArrayToValidate[2] -match "-" -eq 1) { 
        $MyBool = 0
    }
    #will add validation for job titles at some point...
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
            Write-Host "What is not correct? Enter the number" -ForegroundColor Cyan
            try { [int32]$IncorrectIndex = Read-Host } #put in a try catch so we can interpret the input as an int later.
            catch { #if the user didn't enter an integer.
                Write-Host "Must enter a number..." -ForegroundColor Red
                Start-Sleep 1
                Clear-Host
                continue #prompt again
            }
            if ($IncorrectIndex -lt 1 -or $IncorrectIndex -gt 4) { #if the user entered a number that isn't 1-4
                Write-Host "Invalid Input enter a number 1-4" -ForegroundColor Red
                Start-Sleep 1
                Clear-Host
                continue #prompt again
            }
        }
        else { #now that the input is valid...
            switch ($IncorrectIndex) { #assign the new value based on the index.
                1 { $ModifiedParams[0] = Read-Host -Prompt ("Enter the correct Location Code") }
                2 { $ModifiedParams[1] = Read-Host -Prompt ("Enter the correct Employee Number") }
                3 { $ModifiedParams[2] = Read-Host -Prompt ("Enter the correct User Name") }
                4 { $ModifiedParams[3] = Read-Host -Prompt ("Enter the correct Job Title") }
            }
            #it is safe to run IsDataValid because we already ran it once before, the only thing that could possibly be changed is the new data from this func.
            if (IsDataValid($ModifiedParams) -eq 1) { #if the new data the user entered is valid, break out of the while loop.
                break
            }
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

#Abstracts the calling of new Powershell script to this function.
Function CallNewPSScript($ModifiedParams) {
    $Arg1 = $ModifiedParams[0]
    $Arg2 = $ModifiedParams[1]
    $Arg3 = $ModifiedParams[2]
    $Arg4 = $ModifiedParams[3]
    $ArgumentList = "-LocNum $Arg1 -EmpNum $Arg2 -Name `"$Arg3`" -JobTitle `"$Arg4`""
    $ScriptPath= $PSScriptRoot+"\test.ps1"
    Invoke-Expression "& `"$ScriptPath`" $ArgumentList" #jump to new script, passing the validated data
}

#Main function -- Don't need this to be a function. Just my preference
#This function controls the program flow and calls the new user script after data has been validated.
Function Main { 
    SetupEnvironment
    Write-Host ("============================================================================") -ForegroundColor Yellow
    Write-Host ("`n================================= NEW HIRE =================================`n") -ForegroundColor Yellow
    Write-Host ("============================================================================`n") -ForegroundColor Yellow
    $Proceed = 'N'
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
                ModifyData($ModifiedParams) #allows the user to modify the data.
                $Proceed = ConfirmInputCorrect($ModifiedParams) #now that the data has been modified, confirm once again that the input is correct
                if ($Proceed -eq 'Y' -or $Proceed -eq 'y') {
                    break
                }
                else { #if the input is not correct, jump into the first line of while loop and run ModifyData again.
                    continue
                }
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
