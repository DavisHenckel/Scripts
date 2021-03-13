

Function GetUserInput { #Collects user input based off template sent from HR This will not collect lines with less than 2 characters to avoid collecting empty lines.
    $InputParams = [System.Collections.ArrayList]@()
    Write-Host("Enter the user's information (Enter 2 blank lines to stop collecting input):")
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
        $InputParams.Add($UserInput) | Out-Null #prevent adding integers

    }
    return $InputParams
}

Function ValidateInput ($UserInfoArgs) { #ensures input given is in a valid format. After this function is run, there should only be 5 Entries in the array list

    for ($i = 0; $i -lt $UserInfoArgs.Count; $i++) { #If a line is not valid or doesn't contain what we are looking for. Remove it from the list entirely and decrement counter
        if ($i -eq 0 -and ($UserInfoArgs[$i] -Match "Dept" -eq 0 -or $UserInfoArgs[$i] -Match "Location" -eq 0)) { #validate first line
            $UserInfoArgs.Remove($UserInfoArgs[$i])
            if ($i -eq $UserInfoArgs.Count) {
                Write-Host "Never found Location Number... Check format and try again"
                exit
            }
            $i--
            continue
        }
        if ($i -eq 1 -and ($UserInfoArgs[$i] -Match "Employee Number" -eq 0)) { #validate second line
            $UserInfoArgs.Remove($UserInfoArgs[$i])
            if ($i -eq $UserInfoArgs.Count) {
                Write-Host "Never found Employee Number... Check format and try again"
                exit
            }
            $i--
            continue
        }
        if ($i -eq 2 -and ($UserInfoArgs[$i] -Match "User Name" -eq 0)) { #validate third line
            $UserInfoArgs.Remove($UserInfoArgs[$i])
            if ($i -eq $UserInfoArgs.Count) {
                Write-Host "Never found User Name... Check format and try again"
                exit
            }
            $i--
            continue
        }
        if ($i -eq 3 -and ($UserInfoArgs[$i] -Match "Preferred Name for Email" -eq 0)) { #validate fourth line
            $UserInfoArgs.Remove($UserInfoArgs[$i])
            if ($i -eq $UserInfoArgs.Count) {
                Write-Host "Never found Prefered name for Email... Check format and try again"
                exit
            }
            $i--
            continue
        }
        if ($i -eq 4 -and ($UserInfoArgs[$i] -Match "Job Title" -eq 0)) { #validate fifth line
            $UserInfoArgs.Remove($UserInfoArgs[$i])
            if ($i -eq $UserInfoArgs.Count) {
                Write-Host "Never found Job Title... Check format and try again"
                exit
            }
            $i--
            continue
        }
        elseif ($i -gt 4) {
            $UserInfoArgs.Remove($UserInfoArgs[$i]) #remove the line since these are the only 5 that will enter data into AD.
        }                
    }
    return $UserInfoArgs
}

Function UserInputToParameters ($UserInfoArgs) { #Interprets the user input and puts them in a new arraylist. Also helps to validate input more specifically.
    $ModifiedParams = [System.Collections.ArrayList]@()
    for ($i = 0; $i -lt $UserInfoArgs.Count; $i++) {
        if ($i -eq 0) {
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("Dept / Location: ","")
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace(" ","") #Reomve extra space if it exists
            $UserInfoArgs[$i] = $UserInfoArgs[$i].SubString(0,3) #take only next 3 chars
            if ($UserInfoArgs[$i].Length -ne 3) {
                Write-Host ("ERROR, Location Code is not 3 digits. Enter the correct Location Code:`n")
                $UserInfoArgs[$i] = Read-Host
            }
            $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null #prevent adding integers
        }
        if ($i -eq 1) {
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("Employee Number:","")
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace(" ","") #Reomve extra space if it exists
            if ($UserInfoArgs[$i].Length -ne 4) {
                Write-Host ("ERROR, Employee ID is not 4 digits. Enter the correct Employee ID:`n")
                $UserInfoArgs[$i] = Read-Host 
            }
            $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null #prevent adding integers
        }
        if ($i -eq 2) {
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("User Name: ","")
            $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null #prevent adding integers
        }
        if ($i -eq 3) {
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace(" ","") #Reomve spaces if they exist
            if ($UserInfoArgs[$i] -eq "PreferredNameforEmail:") {
                continue
            }
            else {
                $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("Preferred Name for Email: ","")
                $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("."," ") #Replace . with space to fit name format    
                $UserInfoArgs[$i] = $UserInfoArgs[$i].SubString(0, $UserInfoArgs[$i].IndexOf('@'))
                $ModifiedParams[2] = $UserInfoArgs[$i] # set name to be the email name.                
            }
        }
        if ($i -eq 4) {
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("Job Title: ","")
            $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null #prevent adding integers
            break;
        }
    }
    return $ModifiedParams
}

Function ConfirmInputCorrect($ModifiedParams) {
    while(1) {
        Write-Host("Data Collected:`n================`n ")
        for ($i = 0; $i -lt 4; $i++) {
            switch ($i) {
                0 { $ToPrint = $ModifiedParams[$i]
                    Write-Host("Location Code:$ToPrint`n")}
                1 { $ToPrint = $ModifiedParams[$i]
                    Write-Host("Employee ID:$ToPrint`n")}
                2 { $ToPrint = $ModifiedParams[$i]
                    Write-Host("User Name:$ToPrint`n")}
                3 { $ToPrint = $ModifiedParams[$i]
                    Write-Host("Job Title:$ToPrint`n")}
                default { Write-Host("This won't ever happen")}
            }
        }
        $UserInput = Read-Host -Prompt ("Is this data correct? (y/n)")
        if ($UserInput -eq 'y' -or $UserInput -eq 'Y') {
            break
        }
        if ($UserInput -eq 'n' -or $UserInput -eq 'N') {
            Write-Host("Closing Script, try again...")
            cmd /c pause
            exit
        }
        Clear-Host
        Write-Host("Invalid Input. Enter (y/n)`n")
    }
    return $UserInput
} 
Function Main { #Main function -- Don't need this. Just for my organization
    [System.Collections.ArrayList]$UserInfoData = GetUserInput
    [System.Collections.ArrayList]$ModifiedData = ValidateInput($UserInfoData)
    [System.Collections.ArrayList]$ModifiedParams = UserInputToParameters($ModifiedData)
    $Proceed = ConfirmInputCorrect($ModifiedParams)
    if ($Proceed -eq 'y' -or $Proceed -eq 'Y') {
        #Call newUserScript and pass $ModifiedParams[0], $ModifiedParams[1], $ModifiedParams[2], $ModifiedParams[3]
        #These are location number, Employee number, Users Name, and Job Title respectively
    }
}

Main #call main function
cmd /c pause
