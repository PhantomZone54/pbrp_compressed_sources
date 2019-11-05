#!/bin/bash

# Authors - Neil "regalstreak" Agarwal, Harsh "MSF Jarvis" Shandilya, Tarang "DigiGoon" Kagathara
# 2017
# -----------------------------------------------------
# Modified by - Rokib Hasan Sagar @rokibhasansagar
# To be used via Travis CI to Release on GitHub/AFH
# -----------------------------------------------------

# Definitions
DIR=$(pwd)
echo -en "Current directory is -- " && echo $DIR
RecName=$1
LINK=$2
BRANCH=$3
GitHubMail=$4
GitHubName=$5
FTPHost=$6
FTPUser=$7
FTPPass=$8


# Get the latest repo
PATH=~/bin:$PATH
curl -L https://github.com/akhilnarang/repo/raw/master/repo -o ~/bin/repo
chmod a+x ~/bin/repo

# Github Authorization
git config --global user.email $GitHubMail
git config --global user.name $GitHubName
git config --global color.ui true


# Main Function Starts Here

cd $DIR; mkdir $RecName; cd $RecName

# Initialize the repo data fetching
repo init -q -u $LINK -b $BRANCH --depth 1

# Sync it up!
time repo sync -c -f -q --force-sync --no-clone-bundle --no-tags -j32

echo -e "SHALLOW Source Syncing done"

cp -a .repo/manifests $(pwd)/
rm -rf .repo/
mkdir -p .repo && mv manifests .repo/

echo -e "All files and folders here are --- "
ls -la .

cd $DIR
mkdir upload/

echo -en "The total size of the checked-out files is ---  "
du -sh $RecName
DDF=$(du -sh -BM $RecName | awk '{print $1}' | sed 's/M//')
echo -en "Value of DDF is  --- " && echo $DDF

cd $RecName

echo -e "Compressing files --- "
echo -e "Please be patient, this will take time"

export XZ_OPT=-9e

if [ $DDF -gt 8192 ]; then
  echo -e "Compressing and Making 1.75GB parts Because of Huge Data Amount \nBe Patient..."
  time tar -I pxz -cf - * | split -b 1792M - $DIR/upload/$RecName-$BRANCH-norepo-$(date +%Y%m%d).tar.xz.
  # Show Total Sizes of the compressed .repo
  echo -en "Final Compressed size of the consolidated checked-out files is ---  "
  du -sh $DIR/upload/
else
  time tar -I pxz -cf $DIR/upload/$RecName-$BRANCH-norepo-$(date +%Y%m%d).tar.xz *
  echo -en "Final Compressed size of the consolidated checked-out archive is ---  "
  du -sh $DIR/upload/$RecName-$BRANCH-norepo*.tar.xz
fi

echo -e "Compression Done"

echo -e "Cleanup Files"
cd $DIR
rm -rf $RecName

cd $DIR/upload/

md5sum $RecName-$BRANCH-norepo* > $RecName-$BRANCH-norepo-$(date +%Y%m%d).md5sum
cat $RecName-$BRANCH-norepo-$(date +%Y%m%d).md5sum

echo -en "Final Compressed size of the checked-out files is ---  "
du -sh $DIR/upload/

echo -e " SHALLOW Source Compression Done "

echo -e " Begin to upload "
for file in $RecName-$BRANCH*; do wput $file ftp://"$FTPUser":"$FTPPass"@"$FTPHost"//$RecName-NoRepo/ ; done
echo -e " Done uploading to AFH"

echo -e "\nCongratulations! Job Done!"
echo -e " Everything done! "
