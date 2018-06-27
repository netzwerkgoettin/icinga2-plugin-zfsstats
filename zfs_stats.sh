#!/usr/bin/env bash
# Script by Marianne M. Spiller <marianne.spiller@dfki.de>
# 20180627 - print dataset and filesystem stats when -d is not given
# 20180118 - initial commit

PROG=`basename $0`
##---- Defining Icinga 2 exit states
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

##---- Ensure we're using GNU tools
DATE="/usr/gnu/bin/date"
GREP="/usr/gnu/bin/grep"
WC="/usr/gnu/bin/wc"

read -d '' USAGE <<- _EOF_
$PROG - list all available datasets, filesystem and print usage instructions
$PROG [ -c <critical_space> ] [ -w <warning_space> ] -d <dataset>
  -c : Optional: CRITICAL space left for dataset (default: ???)
  -d : dataset to check
  -w : Optional: WARNING space left for dataset (default: ???)
_EOF_

_usage() {
  echo "==== USAGE ===="
  echo "$USAGE"
  exit $STATE_WARNING
}

_getopts() {
  while getopts 'c:d:hw:' OPT ; do
    case $OPT in
      c)
        CRITICAL_PERCENT="$OPTARG"
        ;;
      d)
        ZFS_DATASET="$OPTARG"
        ;;
      h)
        _usage
        ;;
      w)
        WARNING_PERCENT="$OPTARG"
        ;;
      *) echo "Invalid option --$OPTARG1"
        _usage
        ;;
    esac
  done
}

_performance_data() {
cat <<- _EOF_
|used=$USED;$WARNING_VALUE;$CRITICAL_VALUE;0;$QUOTA available=$AVAIL;;;;$QUOTA refer=$REFER;;;;$QUOTA
_EOF_
}

_print_stats() {
  echo "==== ZFS DATASETS ===="
  zpool list
  echo " "
  echo "==== ZFS FILESYSTEMS ===="
  zfs list -t filesystem
  echo " "
}

_getopts $@

if [ -z "$ZFS_DATASET" ] ; then
  ## We're missing a dataset, so we'll print the stats
  _print_stats
  _usage
fi

if ! zfs list $ZFS_DATASET > /dev/null 2>&1; then
  echo "'$ZFS_DATASET' is not a ZFS dataset - try $PROG without any parameter to get a list of valid datasets!"
  exit $STATE_UNKNOWN
fi

if [ -z "$WARNING_PERCENT" ] ; then
  ## Default: 10%
  WARNING_PERCENT="10"
fi

if [ -z "$CRITICAL_PERCENT" ] ; then
  ## Default: 5%
  CRITICAL_PERCENT="5"
fi

USED=`zfs list -Hp -o used $ZFS_DATASET`
AVAIL=`zfs list -Hp -o avail $ZFS_DATASET`
AVAIL_READABLE=`zfs list -H -o avail $ZFS_DATASET`
REFER=`zfs list -Hp -o refer $ZFS_DATASET`
QUOTA=`zfs get -Hp -o value quota $ZFS_DATASET`

if [ "$QUOTA" -eq 0 ] ; then
  echo "WARNING: no quota set for $ZFS_DATASET. You should consider to set limits. Using overall limits now."
  QUOTA="$AVAIL"
  QUOTA_READABLE="- no quota -"
else
  QUOTA_READABLE=`zfs get -H -o value quota $ZFS_DATASET`
fi

DIFF=$(( $QUOTA-$USED ))
WARNING_VALUE=$(( $USED*$WARNING_PERCENT/100|bc -l ))
CRITICAL_VALUE=$(( $USED*$CRITICAL_PERCENT/100|bc -l ))

##----------- Informational output follows
read -d '' FYI <<- _EOF_
Dataset information about $ZFS_DATASET:

  - Quota:     $QUOTA_READABLE
  - Available: $AVAIL_READABLE

_EOF_

if [ "$DIFF" -lt "$WARNING_VALUE" ] ; then
  echo "CRITICAL: only $AVAIL_READABLE available, dataset $ZFS_DATASET nearly full; consider increasing quota or deleting data."
  echo "$FYI"
  _performance_data
  exit $STATE_CRITICAL
elif [ "$DIFF" -lt "$CRITICAL_VALUE" ] ; then
  echo "WARNING: only $AVAIL_READABLE available, dataset $ZFS_DATASET is getting full. Please investigate."
  echo "$FYI"
  _performance_data
  exit $STATE_WARNING
else 
  echo "OK: $AVAIL_READABLE available on $ZFS_DATASET, that's fairly enough."
  echo "$FYI"
  _performance_data
  exit $STATE_OK
fi
