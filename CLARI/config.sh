usr=pi

# $scriptdir is set by CLARI so when sourcing this file it will be replaced correctly.
baseDir=$scriptdir
#baseDir=$(pwd)

TinyOSAppPath="$baseDir/apps"
tinyOSAppSubPaths=('.' 'tests' 'tutorials')
TinyOSCustomApps=($baseDir/apps)

binaryOutpuFolder=binaries
log="log.txt"

nodeToIdMapping=$baseDir/configs/nodeToIdMapping.config
piToNodeMappingFiles=($(ls $baseDir/managedMotes/))

# Make this pwd independend if required.
managedMotes="$scriptdir/managedMotes"
managedMotesFiles="$managedMotes/*"
pieList=($(ls $managedMotes | tr ' ' '\n' | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' |  tr '\n' ' '))

pathToTinyOSJar=$scriptdir/tools/tinyos.jar

# Pi1 is responsible for locking:
lockkeeper="134.91.76.101"

# java net.tinyos.sf.SerialForwarder -comm sf@134.91.76.101:9002 -no-gui