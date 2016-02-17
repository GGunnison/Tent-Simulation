import matplotlib.pyplot as plt
import datetime
import numpy as np 
import csv

'''Author Grant Gunnison, Last modified 2/10/16'''

'''Plots two time series of data'''


file1 = '/Users/GrantGunnison/Dropbox/Research/Tent Simulation/weatherdata.csv'
file2 = '/Users/GrantGunnison/Dropbox/Research/Tent Simulation/temp_check.txt'


reader = csv.reader(open(file1, 'rU'), dialect=csv.excel_tab)
temp_arrayX = []
temp_arrayY	= []
for line in reader:
	temp_arrayX.append((int(line[0][0:10])))
	temp_arrayY.append((float(line[0][11:15])))



reader = csv.reader(open(file2, 'rU'), dialect=csv.excel_tab)
temp_array1X = []
temp_array1Y = []
for line in reader:
	temp_array1X.append((int(line[0][0:10])))
	temp_array1Y.append((float(line[0][18:22])))

first_line, = plt.plot(temp_arrayX, temp_arrayY)
second_line, = plt.plot(temp_array1X, temp_array1Y)
plt.legend([first_line, second_line], ['Dark_Sky', 'NilmExp'])
plt.show()



