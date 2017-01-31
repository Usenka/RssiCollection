#/bin/bash
application=$1
remoteIp=$2

scp $application "$user"@"$remoteIp"
