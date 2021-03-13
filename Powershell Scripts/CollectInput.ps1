

Function GetUserInput { #Collects user input based off template sent from HR
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

Function UserInputToParameters ($UserInfoArgs) { #Interprets the user input and puts them in a new arraylist
    $ModifiedParams = [System.Collections.ArrayList]@()
    for ($i = 0; $i -lt $UserInfoArgs.Length; $i++) {
        if ($i -eq 0) {
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace(" ","") #Reomve all spaces 
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("Dept/Location:","") #remove text before location num
            $UserInfoArgs[$i] = $UserInfoArgs[$i].SubString(0,3) #take only next 3 chars
            if ($UserInfoArgs[$i].Length -ne 3) {
                Write-Host ("ERROR, Location Code is not 3 digits Enter the correct Location Code:`n")
                $UserInfoArgs[$i] = Read-Host
            }
            $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null #prevent adding integers
        }
        if ($i -eq 1) {
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace(" ","") #Reomve all spaces
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("EmployeeNumber:","")
            if ($UserInfoArgs[$i].Length -ne 4) {
                Write-Host ("ERROR, Employee ID is not 4 digits or contains invalid characters. Enter the correct Employee ID:`n")
                $UserInfoArgs[$i] = Read-Host 
            }
            $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null #prevent adding integers
        }
        if ($i -eq 2) {
            $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("User Name: ","")
            $ModifiedParams.Add($UserInfoArgs[$i]) | Out-Null #prevent adding integers
        }
        if ($i -eq 3) {
            if ($UserInfoArgs[$i] -eq "Preferred Name for Email: " -or  $UserInfoArgs[$i] -eq "Preferred Name for Email:  ") {
                continue
            }
            else {
                $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace("Preferred Name for Email: ","")
                $UserInfoArgs[$i] = $UserInfoArgs[$i].Replace(" ","") #Reomve extra space if it exists
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
                0 { $temp = $ModifiedParams[$i]
                    Write-Host("Location Code:$temp`n")}
                1 { $temp = $ModifiedParams[$i]
                    Write-Host("Employee ID:$temp`n")}
                2 { $temp = $ModifiedParams[$i]
                    Write-Host("User Name:$temp`n")}
                3 { $temp = $ModifiedParams[$i]
                    Write-Host("Job Title:$temp`n")}
                default { Write-Host("This won't ever happen. Everything you know is a lie")}
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
        Write-Host("Invalid Input. Enter (y/n)")
    }
    return $UserInput
} 
Function Main { #Main function -- Don't need this to be a function... Just for my organization
    $UserInfoData = GetUserInput
    $ModifiedParams = UserInputToParameters($UserInfoData)
    $Proceed = ConfirmInputCorrect($ModifiedParams)
    $Arg1 = $ModifiedParams[0]
    $Arg2 = $ModifiedParams[1]
    $Arg3 = $ModifiedParams[2]
    $Arg4 = $ModifiedParams[3]
    $ArgumentList = "-LocNum $Arg1 -EmpNum $Arg2 -Name `"$Arg3`" -JobTitle `"$Arg4`""
    if ($Proceed -eq 'y' -or $Proceed -eq 'Y') {
        $ScriptPath= $PSScriptRoot+"\test.ps1"
        Invoke-Expression "& `"$ScriptPath`" $ArgumentList"
        #Call newUserScript and pass $ModifiedParams[0], $ModifiedParams[1], $ModifiedParams[2], $ModifiedParams[3]
        #These are location number, Employee number, Users Name, and Job Title respectively
    }
}

Main #call main function
cmd /c pause
