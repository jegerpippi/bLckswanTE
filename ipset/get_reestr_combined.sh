#!/bin/sh
# get rublacklist and resolve it

SCRIPT=$(readlink -f "$0")
EXEDIR=$(dirname "$SCRIPT")

. "$EXEDIR/def.sh"

ZREESTR="$TMPDIR/reestr.txt"
#ZURL_REESTR=https://reestr.rublacklist.net/api/current
ZURL_REESTR=https://raw.githubusercontent.com/zapret-info/z-i/master/dump.csv

getuser

dig_reestr()
{
 # $1 - grep ipmask
 # $2 - iplist
 # $3 - ipban list

 local DOMMASK='^.*;[^ ;:/]+\.[^ ;:/]+;'
 local TMP="$TMPDIR/tmp.txt"
 # find entries with https or without domain name - they should be banned by IP
 (grep -avE "$DOMMASK" "$ZREESTR" ; grep -a "https://" "$ZREESTR") |
  grep -oE "$1" | cut_local | sort -u >$TMP

 cat "$TMP" | zz "$3"

 # other IPs go to regular zapret list
 grep -oE "$1" "$ZREESTR" | cut_local | grep -xvFf "$TMP" | sort -u | zz "$2"

 rm -f "$TMP"
}


# assume all https banned by ip
curl -k --fail --max-time 150 --connect-timeout 5 --retry 3 --max-filesize 125829120 "$ZURL_REESTR" -o "$ZREESTR" ||
{
 echo reestr list download failed
 exit 2
}
dlsize=$(wc -c "$ZREESTR" | cut -f 1 -d ' ')
if test $dlsize -lt 1048576; then
 echo reestr ip list is too small. can be bad.
 exit 2
fi
#sed -i 's/\\n/\r\n/g' $ZREESTR

[ "$DISABLE_IPV4" != "1" ] && {
 dig_reestr '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]+)?' "$ZIPLIST" "$ZIPLIST_IPBAN"
}

[ "$DISABLE_IPV6" != "1" ] && {
 dig_reestr '([0-9,a-f,A-F]{1,4}:){7}[0-9,a-f,A-F]{1,4}(/[0-9]+)?' "$ZIPLIST6" "$ZIPLIST_IPBAN6"
}

rm -f "$ZREESTR"

"$EXEDIR/create_ipset.sh"