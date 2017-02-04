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

output = open("Times.txt", 'w')
output.write("Calibration time: " + str(calibrationTime) + "\n")
output.write("Spread time: " + str(spreadTime) + "\n")

collectionTime = collectionTime/collectionAmount
roundTime = roundTime/roundAmount

output.write("Collection time: " + str(collectionTime) + "; Rounds: " + str(collectionAmount) + "; Standard deviation: " + str(pstdev(collectionTimes)) + "\n")
output.write("Round time: " + str(roundTime) + "; Rounds: " + str(roundAmount) + "; Standard deviation: " + str(pstdev(roundTimes)) +"\n")



#connections = []

#for i in range(0,33):
#	connections.append([])

#lastSource = 0
#lastRadio = 0
#for line in simulationFile:
#	if "<source>" in line:
#		lastSource = line[len("        <source>"):-len("</source> ")]	
#	if "<radio>" in line:
#		lastRadio = int(line[len("          <radio>"):-len("</radio> ")])
#	
#		connections[lastRadio].append(lastSource)
#
#sample = open(sys.argv[2], 'r')
#
#counter = int(1)
#for line in sample:
#	for mote in connections[counter]:
#		if mote not in line:
#			print(mote + " NOT IN ", counter)
#	counter+=1	
	


