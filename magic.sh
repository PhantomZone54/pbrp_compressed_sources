#!/bin/bash

# Authors - Neil "regalstreak" Agarwal, Harsh "MSF Jarvis" Shandilya, Tarang "DigiGoon" Kagathara
# 2017
# -----------------------------------------------------
# Modified by - Rokib Hasan Sagar @rokibhasansagar
# To be used via Travis CI to Release on GitHub/AFH
# -----------------------------------------------------

# Definitions
DIR=$(pwd)
RecName=$1
LINK=$2
BRANCH=$3
GitHubMail=$4
GitHubName=$5
FTPHost=$6
FTPUser=$7
FTPPass=$8

# Colors
CL_XOS="\033[34;1m"
CL_PFX="\033[33m"
CL_INS="\033[36m"
CL_RED="\033[31m"
CL_GRN="\033[32m"
CL_YLW="\033[33m"
CL_BLU="\033[34m"
CL_MAG="\033[35m"
CL_CYN="\033[36m"
CL_RST="\033[0m"

# Show total Disc Sizes before all operations
echo -e $CL_GRN"Total Disc Sizes are:"$CL_RST; df -hlT

# Get the latest repo
mkdir ~/bin
PATH=~/bin:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# Github Authorization
git config --global user.email $GitHubMail
git config --global user.name $GitHubName
git config --global color.ui true


# Main Function
doSync(){
    cd $DIR; mkdir -p $RecName/shallow; cd $RecName/shallow

    # Initialize the repo data fetching
    repo init -q -u $LINK -b $BRANCH --depth 1

    # Sync it up!
    time repo sync -c -f -q --force-sync --no-clone-bundle --no-tags -j32

    echo -e $CL_RED"SHALLOW Source Syncing done"$CL_RST

    cd $DIR/$RecName/
	
    mkdir $RecName-$BRANCH-repo-$(date +%Y%m%d)
    
    mv shallow/.repo/ $RecName-$BRANCH-repo-$(date +%Y%m%d)

    # Show Total Sizes of the .repo folder and non-repo files
    echo -en $CL_GRN"The total size of the consolidated .repo is ---  "$CL_RST
    du -sh $RecName-$BRANCH-repo-$(date +%Y%m%d)
    echo -en $CL_GRN"The total size of the checked-out files are ---  "$CL_RST
    du -sh shallow

    # Remove the unnecessary uncompressed checked-out files
    rm -rf shallow

    # Compress .repo folder in one piece
    echo -e $CL_RED"Compressing files ---  "$CL_RST
    export XZ_OPT=-9
    time tar -I pxz -cf $RecName-$BRANCH-repo-$(date +%Y%m%d).tar.xz $RecName-$BRANCH-repo-$(date +%Y%m%d)/

    # Show Total Sizes of the compressed .repo
    echo -en $CL_BLU"Final Compressed size of the consolidated .repo is ---  "$CL_RST
    du -sh $RecName-$BRANCH-repo-$(date +%Y%m%d).tar.xz
    echo -e "\n"

    # Basic Cleanup
    rm -rf $RecName-$BRANCH-repo-$(date +%Y%m%d)/

    echo -e $CL_RED" SHALLOW Source Compression Done "$CL_RST

    sortSyncedParts
    Upload2FTP

    cd $DIR/$RecName

    echo -e $CL_RED"\nCongratulations! Job Done!"$CL_RST

}

sortSyncedParts(){

    echo -e $CL_RED" SHALLOW Source  .. - ..  Begin to sort "$CL_RST

    cd $DIR/$RecName
    rm -rf upload
    mkdir -p upload/$RecName/$BRANCH

    mv $RecName-$BRANCH-repo-$(date +%Y%m%d).tar.xz upload/$RecName/$BRANCH/

    echo -e $CL_PFX" Done sorting "$CL_RST

    # Md5s
    echo -e $CL_PFX" Taking md5sums "$CL_RST

    cd $DIR/$RecName/upload/$RecName/$BRANCH
    md5sum * > $RecName-$BRANCH-repo-$(date +%Y%m%d).md5sum

}

Upload2FTP(){

    echo -e $CL_XOS" Begin to upload "$CL_RST

    cd $DIR/$RecName/upload
    
    # Upload
    SHALLOWUP="$RecName/$BRANCH/$RecName-$BRANCH-repo*"
    wput $SHALLOWUP ftp://"$FTPUser":"$FTPPass"@"$FTPHost"/

    echo -e $CL_XOS" Done uploading "$CL_RST

}

# Do All The Stuff
doallstuff(){

    # Compress shallow source
    doSync

}


# So at last do everything
doallstuff
if [ $? -eq 0 ]; then
    echo "Everything done!"
fi
