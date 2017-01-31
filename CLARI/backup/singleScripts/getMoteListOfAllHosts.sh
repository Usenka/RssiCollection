#!/bin/bash

list=($(cat $pieList))

for hostIp in ${list[@]}
do 
  echo $hostIp
  result=$(./getMoteListOfRemoteHost.sh $hostIp)
  echo $result
  echo "do something"
done
