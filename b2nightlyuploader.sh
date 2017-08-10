#!/bin/bash

# B2 sync script to upload local database files to backblaze b2 storage
# Script run format:   ./b2sync.sh bucket/folder
# Example run format:  ./b2sync.sh production/2016-01/databasedirectory

# Notes:
# Can be run just including the month #$ ./b2sync.sh production/2016-01 
# Outputs to screen and to /b2logs/b2sync.timestamp file

# Exclusion list should be checked before running to be sure only including .enc encrypted files
# Current directory can be checked using:  find . -type f | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort -u

DATE=`date +%Y-%m-%d`
DBDATE=`date +%Y-%m --date='yesterday'` #date for yesterday's backup files
TIMESTAMP=`date +'%F.%T'` #timestamp for logs file
SCRIPTDIRECTORY='/home/backblaze'       # where script is saved
BACKUPSDIRECTORY='/mnt/backupfiles'       # backups directory
B2LOGSDIR='/home/backblaze/b2logs' # where logs are saved (if does not exist, script creates it)

BUCKET='production'
LASTLOG=`ls -t $SCRIPTDIRECTORY/b2logs/ | head -n1`
EXCLIST='(.*bz2$)|(.*sh$)|(.*ssl$)|(.*gz$)|(.*pem$)|(.*pub$)|(.*jd$)|(.*sql$)' #exclusion list

EMAIL='backblaze@example.com'

# Checks for or makes /b2logs/ directory in folder where script is run
mkdir -p $B2LOGSDIR
cp $SCRIPTDIRECTORY/message.txt $SCRIPTDIRECTORY/message.copy.txt

if grep -q ECONNRESET $SCRIPTDIRECTORY/b2logs/$LASTLOG; then    # if /b2logs/file contains error then 
        echo "Error found in last upload, resyncing"
        echo "Error found in last upload, resyncing" >> $SCRIPTDIRECTORY/message.copy.txt
        /usr/local/bin/b2 cancel_all_unfinished_large_files $BUCKET >> $SCRIPTDIRECTORY/message.copy.txt
        cat $B2LOGSDIR/$LASTLOG >> $SCRIPTDIRECTORY/message.copy.txt    # add last log details to email 
else
        echo "Previous backups complete without error"
        echo "Previous backups complete without error" >> $SCRIPTDIRECTORY/message.copy.txt
fi
        echo "Transferring files to Backblaze B2: $BUCKET/$DBDATE"
        cd $BACKUPSDIRECTORY
        /usr/local/bin/b2 sync --debugLogs --noProgress --excludeRegex $EXCLIST $BUCKET/$DBDATE b2://$BUCKET/$DBDATE 2>&1 | tee $B2LOGSDIR/b2sync.$TIMESTAMP
        cat $B2LOGSDIR/$LASTLOG >> $SCRIPTDIRECTORY/message.copy.txt    # add upload details to email

echo >> $SCRIPTDIRECTORY/message.copy.txt
echo >> $SCRIPTDIRECTORY/message.copy.txt
echo "Uploads complete!" >> $SCRIPTDIRECTORY/message.copy.txt

/usr/sbin/ssmtp $EMAIL < $SCRIPTDIRECTORY/message.copy.txt


