#!/bin/bash

# Authors - Neil "regalstreak" Agarwal, Harsh "MSF Jarvis" Shandilya, Tarang "DigiGoon" Kagathara
# 2017
# -----------------------------------------------------
# Modified by - Rokib Hasan Sagar @rokibhasansagar
# To be used via Travis CI to Release on GitHub/AFH
# -----------------------------------------------------

# Definitions
DIR=$(pwd)
ROMNAME=$1
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
    cd $DIR; mkdir -p $ROMNAME/shallow; cd $ROMNAME/shallow

    # Initialize the repo data fetching
    repo init -q -u $LINK -b $BRANCH --depth 1

    # Sync it up!
    time repo sync -c -f -q --force-sync --no-clone-bundle --no-tags -j32

    echo -e $CL_RED"SHALLOW Source Syncing done"$CL_RST

    cd $DIR/$ROMNAME/
	
    mkdir $ROMNAME-$BRANCH-repo-$(date +%Y%m%d)
    
    # Differntiate .repo folder and checked-out files
    mv shallow/.repo/ $ROMNAME-$BRANCH-repo-$(date +%Y%m%d)
    mv shallow $ROMNAME-$BRANCH-norepo-$(date +%Y%m%d)
    
    # Show Total Sizes of the .repo folder and non-repo files
    echo -en $CL_GRN"The total size of the consolidated .repo is ---  "$CL_RST
    du -sh $ROMNAME-$BRANCH-repo-$(date +%Y%m%d)
    echo -en $CL_GRN"The total size of the checked-out files are ---  "$CL_RST
    du -sh $ROMNAME-$BRANCH-norepo-$(date +%Y%m%d)
    echo -e "\n"

    # Compress .repo folder
    mkdir repoparts
    export XZ_OPT=-6
    time tar -I pxz -cf - $ROMNAME-$BRANCH-repo-$(date +%Y%m%d)/ | split -b 1024M - repoparts/$ROMNAME-$BRANCH-repo-$(date +%Y%m%d).tar.xz.
    SHALLOW_R="repoparts/$ROMNAME-$BRANCH-repo-$(date +%Y%m%d).tar.xz.*"

    # Show Total Sizes of the compressed .repo
    echo -en $CL_BLU"Final Compressed size of the consolidated .repo is ---  "$CL_RST
    du -sh repoparts
    echo -e "\n"

    # Basic Cleanup
    rm -rf $ROMNAME-$BRANCH-repo-$(date +%Y%m%d)

    # Compress the non-repo floders as well
    mkdir norepoparts
    export XZ_OPT=-9e
    time tar -I pxz -cf - $ROMNAME-$BRANCH-norepo-$(date +%Y%m%d)/ | split -b 1024M - norepoparts/$ROMNAME-$BRANCH-norepo-$(date +%Y%m%d).tar.xz.
    SHALLOW_NR="norepoparts/$ROMNAME-$BRANCH-norepo-$(date +%Y%m%d).tar.xz.*"

    # Show Total Sizes of the compressed norepo
    echo -en $CL_BLU"Final Compressed size of the checked-out files are ---  "$CL_RST
    du -sh norepoparts
    echo -e "\n"

    # Basic Cleanup
    rm -rf $ROMNAME-$BRANCH-norepo-$(date +%Y%m%d)

    echo -e $CL_RED" SHALLOW Source Compression Done "$CL_RST

    sortSyncedParts
    Upload2FTP

    cd $DIR/$ROMNAME

    echo -e $CL_RED"\nCongratulations! Job Done!"$CL_RST

}

sortSyncedParts(){

    echo -e $CL_RED" SHALLOW Source  .. - ..  Begin to sort "$CL_RST

    cd $DIR/$ROMNAME
    rm -rf upload
    mkdir -p upload/$ROMNAME/$BRANCH

    mv $SHALLOW_R upload/$ROMNAME/$BRANCH
    mv $SHALLOW_NR upload/$ROMNAME/$BRANCH

    echo -e $CL_PFX" Done sorting "$CL_RST

    # Md5s
    echo -e $CL_PFX" Taking md5sums "$CL_RST

    cd $DIR/$ROMNAME/upload/$ROMNAME/$BRANCH
    md5sum $ROMNAME-$BRANCH-repo* > $ROMNAME-$BRANCH-repo-$(date +%Y%m%d).parts.md5sum
    md5sum $ROMNAME-$BRANCH-norepo* > $ROMNAME-$BRANCH-norepo-$(date +%Y%m%d).parts.md5sum

}

Upload2FTP(){

    echo -e $CL_XOS" Begin to upload "$CL_RST

    cd $DIR/$ROMNAME/upload
    
    # Upload
    SHALLOWUP_R="$ROMNAME/$BRANCH/$ROMNAME-$BRANCH-repo-$(date +%Y%m%d).*"
    SHALLOWUP_NR="$ROMNAME/$BRANCH/$ROMNAME-$BRANCH-norepo-$(date +%Y%m%d).*"
    wput $SHALLOWUP_R ftp://"$FTPUser":"$FTPPass"@"$FTPHost"/
    wput $SHALLOWUP_NR ftp://"$FTPUser":"$FTPPass"@"$FTPHost"/

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
