#Intro

echo "----------------------------------------------------------------------------"
echo "This script is designed to transfer user data as efficiently as possible."
echo "Recommend running caffeinated -dim in a second terminal window while transferring."
echo "Created by Davis Henckel 10/21/2019"
echo "Most recent update 01/20/2020"
echo "----------------------------------------------------------------------------"
echo

#Getting source
cd /Volumes/Macintosh\ HD/Users/
echo "----------------------------------------------------------------------------"
echo "Available home folders:"
ls
echo "----------------------------------------------------------------------------"
echo "What is the name of the home folder that you want transferred?"
read userInput
fileName=/Volumes/Macintosh\ HD/Users/$userInput
echo "*Note* this script will not transfer any library data or any iCloud data."
echo "This script will also not transfer any extra items in the root...of the profile"
echo
cd /
cd "$fileName"
echo "The path is: "
pwd
echo
echo "If this is correct enter "y". If not hit any other key"
read user_input
if [ $user_input = "y" ]
then
	echo
else
	echo "Failed, do not have correct path. Make sure the drive is mounted.">&2
	exit 1
fi 

#Getting destination
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
echo 
echo "What would you like the destination folder to be named?: "
read copyFolder
if [ -f "$copyFolder" ]
then
	echo "Directory already exists! Delete it first or pick a different name."
	exit 1
fi
mkdir "$copyFolder"
cd "$copyFolder"
mkdir $userInput
cd "$userInput"
echo "Destination is: "
destin=/Volumes/"$destName"/"$copyFolder"/$userInput/
echo $destin
cd /

cp -vr "$fileName"/{Desktop,Documents,Downloads,Movies,Music,Pictures,Public} "$destin"

echo "Transfer Complete! Verify the data is accurate and transfer anything else relevant once in the OS!"


