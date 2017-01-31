#!/bin/bash
remoteIp=$1

ssh "$user"@"$remoteIp" 'motelist'
