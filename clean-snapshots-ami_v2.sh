#!/bin/bash
#created by that guy Rodney Ellis
cat << "EOF"
                    ##        .            
              ## ## ##       ==            
           ## ## ## ##      ===            
       /""""""""""""""""\___/ ===        
      {                      /  ===-  
       \______ o          __/            
         \    \        __/             
          \____\______/                    
EOF
#########################################################################
###!!!!!!!!!!!     Please note the dry-run flag set        !!!!!!!!!!!###
#########################################################################
echo "....................."
echo "....................."
echo "....................."

echo "Please set run type delete or check, use "delete" or "check" "
read RUN_TYPE

if [ -z "$RUN_TYPE" ]; then
   echo "Please use the exact naming"
   exit 1
fi

if [ "$RUN_TYPE" = "delete" ]; then
    echo "Running in delete mode"
    RUN_TYPE="0"
    else
    echo "Running in check mode"
    RUN_TYPE="100000"
fi

REGION=$1
if [ -z "$REGION" ]; then
   echo "How to run the Script: ./clean-snapshots.sh <aws-region> <exclude-snapshot-id>"
   exit 1
fi

EXCLUDE_SNAPSHOT=$2
if [ -z "$EXCLUDE_SNAPSHOT" ]; then
    echo "No Snapshot will be excluded"
    else
    EXCLUDE_SNAPSHOT=$2
    echo "The following snapshot-id will be excluded "$EXCLUDE_SNAPSHOT
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text | awk {'print $1'})

WORK_DIR=/tmp/snapshots-cleaner
#Create Directories 
echo "Creating directories ... "
mkdir -p /tmp/snapshots-cleaner
touch $WORK_DIR/all_snapshots
touch $WORK_DIR/snapshots_attached_to_ami

#Create the comparison files in the tmp directory od snapshots attached to images and all snapshots in the account.
echo "Creating comparison files .... "
aws ec2 --region $REGION describe-snapshots --owner-ids $AWS_ACCOUNT_ID --query Snapshots[*].SnapshotId --output text | tr '\t' '\n' | sort >  $WORK_DIR/all_snapshots
aws ec2 --region $REGION describe-images --filters Name=state,Values=available --owners $AWS_ACCOUNT_ID --query "Images[*].BlockDeviceMappings[*].Ebs.SnapshotId" --output text | tr '\t' '\n' | sort >  $WORK_DIR/snapshots_attached_to_ami
echo $EXCLUDE_SNAPSHOT >> $WORK_DIR/snapshots_attached_to_ami

#Filter out snapshot that are not liked to AMI's.
echo "Comparing results ... "
ORPHANED_SNAPSHOT_IDS=$(comm -13 <(sort "$WORK_DIR/snapshots_attached_to_ami") <(sort "$WORK_DIR/all_snapshots"))

sleep 3

if [ -z "$ORPHANED_SNAPSHOT_IDS" ]; then
  echo "OK - no orphaned (not attached to any AMI) snapshots found"
  exit 0
fi

ORPHANED_SNAPSHOTS=$(echo $ORPHANED_SNAPSHOT_IDS | grep "snap")

ORPHANED_SNAPSHOTS_COUNT=$(echo "$ORPHANED_SNAPSHOT_IDS" | wc -l)
echo "Count of orphaned snapshots ... " $ORPHANED_SNAPSHOTS_COUNT

sleep 3

if (( $ORPHANED_SNAPSHOTS_COUNT \> $RUN_TYPE )); then
  echo "Starting to delete orphaned snapshots ..... "
  IFS=$'\n'
  for snapshot_id in $ORPHANED_SNAPSHOT_IDS
  do
  echo "Deleting Snapshot" $snapshot_id
  aws ec2 --dry-run --region $REGION delete-snapshot --snapshot-id $snapshot_id
  done
  exit 1
else
  echo "OK - $ORPHANED_SNAPSHOTS_COUNT orphaned (not attached to any AMI) found"
  if (( $ORPHANED_SNAPSHOTS_COUNT \> 0 )); then
    echo "Below is a list of orphaned snapshot ID's ... "

    sleep 3

      for snapshot_id in $ORPHANED_SNAPSHOT_IDS
      do
      SNAP_TIME=$(aws ec2 describe-snapshots --region $REGION --snapshot-ids $snapshot_id --query 'Snapshots[*].{Description:Description,ID:SnapshotId,Volume:VolumeId,Time:StartTime}' --output text )
      echo $SNAP_TIME
  done
    echo "It's done"
  fi
  exit 0
fi
