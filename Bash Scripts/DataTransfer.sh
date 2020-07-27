# Created by Davis Henckel 10/21/2019
# Most recent update 01/22/2020

#Intro
echo "----------------------------------------------------------------------------"
echo "This script is designed to transfer user data as efficiently as possible."
echo "*Note* this script will not transfer any library data or any iCloud data."
echo "This script will also not transfer any extra items in the root of the profile"
echo "----------------------------------------------------------------------------"
echo

#Getting source--------------------------------------------------------------------------------
cd /Volumes/Macintosh\ HD/Users/
echo "----------------------------------------------------------------------------"
echo "Available home folders for transfer:"
ls
echo "----------------------------------------------------------------------------"
while [ true ]
do
	echo "Is there more than one home folder(y/n)?: "
	read userInput
	if [ $userInput = "y" ]
	then
		break
	elif [ $userInput = "n" ]
	then
		break
	fi
done

#Initialize folders for the 5 possible profiles.
firstFolder="e"
secondFolder="e"
thirdFolder="e"
fourthFolder="e"
fifthFolder="e"

#More than one profile----------------------------------------------------------------------------
if [ $userInput = "y" ]
then
	while [ true ]
	do
		echo "How many are there, can transfer up to 5(Enter an integer)?"
		read howMany
		if [ $howMany = "1" ] || [ $howMany = "2" ] || [ $howMany = "3" ] || [ $howMany = "4" ] || [ $howMany = "5" ]
		then
			break
		fi
	done
	for (( i=0;i<$howMany;i++ ))
	do
		curVal=`expr $i + 1`
		echo "$curVal folder: "
		read aFolder
		if [ $i = 0 ]
		then
			firstFolder=$aFolder
		fi
		if [ $i = 1 ]
		then
			secondFolder=$aFolder
		fi
		if [ $i = 2 ]
		then
			thirdFolder=$aFolder
		fi
		if [ $i = 3 ]
		then
			fourthFolder=$aFolder
		fi
		if [ $i = 4 ]
		then
			fifthFolder=$aFolder
		fi
	done
#End more than one profile----------------------------------------------------------------------------

#Only one profile
else
	echo "What is the name of the home folder that you want transferred?"
	read userInput
	fileName=/Volumes/Macintosh\ HD/Users/$userInput
	cd /
	cd "$fileName"
	echo "The path is: "
	pwd
	echo
	while [ true ]
	do
		echo "Is this path correct? (y/n)"
		read user_input
		if [ $user_input = "y" ]
		then
			break
		elif [ $user_input = "n" ]
		then
			break
		fi
	done
	if [ $user_input = "y" ]
	then
		echo
	else
		echo "Failed, do not have correct path. Make sure the drive is mounted.">&2
		exit 1
	fi 
fi
#End of getting source-----------------------------------------------------------------------------

#Getting destination ------------------------------------------------------------------------------
cd /Volumes/
echo "----------------------------------------------------------------------------"
echo "Available Volumes.(Make sure the device is mounted):"
ls
echo "----------------------------------------------------------------------------"
echo "What is your destination?"
read destName
echo
cd /
cd Volumes
cd "$destName"
echo "Current path is: "
pwd
while [ true ]
do
	echo "If this is correct enter "y". If not hit any other key"
	read user_input
	if [ $user_input = "y" ]
	then
		break
	elif [ $user_input = "n" ]
	then
		break
	fi
done
if [ $user_input = "y" ]
then
	echo
else
	echo "Failed, do not have correct destination. Make sure the drive is mounted.">&2
	exit 1
fi 
#End of getting destination --------------------------------------------------------------------------

#Getting destination folder name----------------------------------------------------------------------
echo "What would you like the destination folder to be named?: "
read copyFolder
if [ -f "$copyFolder" ]
then
	echo "Directory already exists! Delete it first or pick a different name.">&2
	exit 1
fi
mkdir "$copyFolder"
cd "$copyFolder"
#End of destination folder name------------------------------------------------------------------------

#Only execute this if there is only one profile.
if [ $firstFolder = "e" ]
then
	mkdir $userInput
	cd "$userInput"
	echo "Destination is: "
	destin=/Volumes/"$destName"/"$copyFolder"/$userInput/
	echo $destin
fi


#There are multiple profiles---------------------------------------------------------------------------
if [ $firstFolder != "e" ]
then
	cd /
	cd Volumes/"$destName"/"$copyFolder"
	mkdir $firstFolder
	cd /
	firstSource=/Volumes/Macintosh\ HD/Users/$firstFolder
	destin=/Volumes/"$destName"/"$copyFolder"/$firstFolder/
	cp -vr "$firstSource"/{Desktop,Documents,Downloads,Movies,Music,Pictures,Public} "$destin"
	if [ $howMany = "1" ]
	then
		echo "Transfer Complete! Verify the data is accurate and transfer anything else relevant once in the OS!"
		exit 0
	fi 
fi 
if [ $secondFolder != "e" ]
then
	cd /
	cd Volumes/"$destName"/"$copyFolder"
	mkdir $secondFolder
	cd /
	secondSource=/Volumes/Macintosh\ HD/Users/$secondFolder
	destin=/Volumes/"$destName"/"$copyFolder"/$secondFolder/
	cp -vr "$secondSource"/{Desktop,Documents,Downloads,Movies,Music,Pictures,Public} "$destin"
	if [ $howMany = "2" ]
	then
		echo "Transfer Complete! Verify the data is accurate and transfer anything else relevant once in the OS!"
		exit 0
	fi 
fi 
if [ $thirdFolder != "e" ]
then
	cd /
	cd Volumes/"$destName"/"$copyFolder"
	mkdir $thirdFolder
	cd /
	thirdSource=/Volumes/Macintosh\ HD/Users/$thirdFolder
	destin=/Volumes/"$destName"/"$copyFolder"/$thirdFolder/
	cp -vr "$thirdSource"/{Desktop,Documents,Downloads,Movies,Music,Pictures,Public} "$destin"
	if [ $howMany = "3" ]
	then
		echo "Transfer Complete! Verify the data is accurate and transfer anything else relevant once in the OS!"
		exit 0
	fi 
fi 
if [ $fourthFolder != "e" ]
then
	cd /
	cd Volumes/"$destName"/"$copyFolder"
	mkdir $fourthFolder
	cd /
	fourthSource=/Volumes/Macintosh\ HD/Users/$fourthFolder
	destin=/Volumes/"$destName"/"$copyFolder"/$fourthFolder/
	cp -vr "$fourthSource"/{Desktop,Documents,Downloads,Movies,Music,Pictures,Public} "$destin"
	if [ $howMany = "4" ]
	then
		echo "Transfer Complete! Verify the data is accurate and transfer anything else relevant once in the OS!"
		exit 0
	fi 
fi 
if [ $fifthFolder != "e" ]
then
	cd /
	cd Volumes/"$destName"/"$copyFolder"
	mkdir $fifthFolder
	cd /
	fifthSource=/Volumes/Macintosh\ HD/Users/$fifthFolder
	destin=/Volumes/"$destName"/"$copyFolder"/$fifthFolder/
	cp -vr "$fifthSource"/{Desktop,Documents,Downloads,Movies,Music,Pictures,Public} "$destin"
fi
#End of multiple profiles ---------------------------------------------------------------------------

#If there is only one profile
if [ $firstFolder = "e" ]
then
	cd /
	cp -vr "$fileName"/{Desktop,Documents,Downloads,Movies,Music,Pictures,Public} "$destin"
fi

#End of script
echo "Transfer Complete! Verify the data is accurate and transfer anything else relevant once in the OS!"
exit 0


