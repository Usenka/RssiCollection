#!/bin/bash

application=$1
curDir=$(pwd)
binaryOutpuFolder=binaries

mkdir $outpuFolder 2>/dev/null

gotoApplicationPath(){
  local path=""
  for item in ${TinyOSCustomApps[@]}
  do
    echo "checking $item"
    if [ -d $item/$1 ]
    then
      path=$item/$1
      break
    fi
  done

  if [ "" == "$path" ]
  then
    for item in ${tinyOSAppSubPaths[@]}
    do
      if [ -d $TinyOSAppPath/$item/$1 ]
      then
	path=$TinyOSAppPath/$item/$1
	break
      fi
    done
  fi

  if [ "" == "$path" ]
  then
    if [ -d $ConfigPath/tinyosApps/$1 ]
    then
      path=$ConfigPath/tinyosApps/$1
    fi
  fi

  if [ "" != $path ]
  then
    cd $path
    return 0
  fi
  return 1
}

compile(){
  if [ "$1" == "--help" ]
  then
    echo
    echo "PARAMS: NONE"
    echo
    echo "This function compiles the tinyos-application of the current directory for telosb."
  else
    make clean > /dev/null
    make telosb >/dev/null
    if [ $? != 0 ]
    then
      echo "---ERROR: compiling failed---"
      return 1
    else
      echo "Application successfully compiled"
      return 0
    fi
  fi
}

gotoApplicationPath $application
compile
cp build/telosb/main.exe $curDir/$binaryOutpuFolder/"$application".exe
cd $curDir
