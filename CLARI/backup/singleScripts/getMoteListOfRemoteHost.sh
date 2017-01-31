#!/bin/bash

remoteHost=$1

getMoteListOfRemoteHost()
{
  remoteHost=$1
  result=$(ssh "$user"@$remoteHost 'motelist')
  echo
  echo "$result"
}

getMoteListOfRemoteHost $remoteHost