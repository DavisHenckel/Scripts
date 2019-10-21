echo "Welcome to the GOAT Script"
echo
fileName=/Volumes/Macintosh\ HD/Users/$USER
echo "The path should be: $fileName"

echo
cd /
cd "$fileName"
echo "The path is: "
pwd
echo
echo "If this is correct enter "y". If not hit any other key"
read userInput
if [ $userInput = "y" ]
then
	echo "Great! moving on"
	echo
else
	echo "Failed, do not have correct path.">&2
	exit 1
fi 

echo
echo "What is the name of the destination? "
read destName
echo

cd /
cd Volumes
cd "$destName"
echo "Current path is: "
pwd
echo 

echo "What would you like the Copy folder to be named: "
read copyFolder
if [ -f "$copyFolder" ]
then
	echo "Directory already exists. Would you like to delete it and start over?(y) (If file is not deleted, it will be appended to)."
	read theInput
	if [ $theinput = "y"]
	then
		rm -rf $copyFolder
		echo "Directory $copyFolder deleted."
		echo "Creating $copyFolder directory"
		sleep 1
		mkdir "$copyFolder"
		echo "Directory $copyFolder created."
	elif
		echo "Moving on"
	fi
else
	mkdir "$copyFolder"
	echo "Directory $copyFolder created."
fi

cd "$copyFolder"
sleep 1
mkdir $USER
cd $USER
touch transferLog.txt
mkdir Library

cd /
clear
echo "Check transferLog.txt to view progress & results of data backup"
echo "Beginning Copy of relevant Library data..." | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
echo | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
sleep 1

cp -pvr "$fileName"/Library/Google /Volumes/"$destName"/"$copyFolder"/$USER/Library | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
echo | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt 
echo "Finished with relevant Library Data!" | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
echo --------------------------------------------------------------- | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
cp -pvr "$fileName"/Desktop /Volumes/"$destName"/"$copyFolder"/$USER | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
echo "Finished with Desktop!" | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
echo --------------------------------------------------------------- | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
cp -pvr "$fileName"/Documents /Volumes/"$destName"/"$copyFolder"/$USER | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
echo "Finished with Documents!" | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
echo --------------------------------------------------------------- | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
cp -pvr "$fileName"/Downloads /Volumes/"$destName"/"$copyFolder"/$USER | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
echo "Finished with Downloads!" | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
echo --------------------------------------------------------------- | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
cp -pvr "$fileName"/Movies /Volumes/"$destName"/"$copyFolder"/$USER | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
echo "Finished with Movies!" | tee -a /Volumes/"$destName"/"$copyFolder"| /$USER/transferLog.txt
echo --------------------------------------------------------------- | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
cp -pvr "$fileName"/Pictures /Volumes/"$destName"/"$copyFolder"/$USER | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
echo "Finished with Pictures!" | tee -a /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt
echo --------------------------------------------------------------- |tee /Volumes/"$destName"/"$copyFolder"/$USER/transferLog.txt


