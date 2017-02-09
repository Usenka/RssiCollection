import sys
from statistics import pstdev

if len(sys.argv) is not 2:
	print("Enter the path of the output file")
	exit()

reFile = open(sys.argv[1], 'r')

startTime = 0

calibrationTime = 0
isCalibrating = 0

collectionAmount = 0
collectionTime = 0
isCollecting = 0
collectionTimes = []

spreadTime = 0
isSpreading = 0

roundAmount = 0
roundTime = 0
isSampling = 0
roundTimes = []


for line in reFile:
	line = line.rstrip('\n')
	params = line.split(" ")
	if len(params) == 3:
		params[0] = params[0].replace("[", "").replace("]", "")
		print(params[0] + " " + params[1] + " " + params[2] )
		if params[1] == "START":
			startTime = int(params[0])
			if params[2] == "calibration":
				isCalibrating = 1
			if params[2] == "collection":
				isCollecting = 1
			if params[2] == "spreading":
				isSpreading = 1
			if params[2] == "round":
				isSampling = 1
		if params[1] == "FIN":
			duration = int(params[0]) - startTime
			if params[2] == "calibration" and isCalibrating:
				isCalibrating = 0
				calibrationTime = duration
			if params[2] == "collection" and isCollecting:
				isCollecting = 0
				collectionAmount += 1
				collectionTime = collectionTime + duration
				collectionTimes.append(duration)
			if params[2] == "spreading" and isSpreading:
				isSpreading = 0
				spreadTime = duration
			if params[2] == "round" and isSampling:
				isSampling = 0
				roundAmount += 1
				roundTime = roundTime + duration
				roundTimes.append(duration)

output = open("Collection.txt", 'w')
for time in collectionTimes:
	output.write(str(time) + "\n")

output = open("Rounds.txt", "w")
for time in roundTimes:
	output.write(str(time) + "\n")


