import mechanize
import json
import time as T
import numpy as np
import scipy.io
import csv


'''Author Grant Gunnison, Last modified 2/10/16'''


url ='https://api.forecast.io/forecast/4500ed9ab5c368b9ea32eca07d5c942b/'


'''
Arguments:

location: latitude,longitude (String)
		  
		  Coordinates must be given with 
		  a comma in between, but no spaces


keys:    name of the data entry required from the json (List)

Returns: csv with 1 days worth of two columns of data time, temp 
	   : provides hourly data
'''
def get_forecast_json(location, keys = 'all'):
	
	br = mechanize.Browser()
	br.set_handle_robots(False)
	response = br.open(url+ location).read()
	max_qsol = 300

	if keys == 'all':
		json_dict = json.loads(response)

	elif isinstance(keys, (list)):

		forecast_dict = {}
		json_dict = json.loads(response)

		for key in keys:
			forecast_dict[key] = json_dict[key]

		json_dict = forecast_dict


	hour_list = []
	for entry in json_dict['hourly']['data']:
		hour_list.append((int(entry['time']), float(entry['apparentTemperature'])))
	

	with open('weatherdata1.csv', 'wb') as csvfile:
		wr = csv.writer(csvfile)
		for entry in hour_list:
			wr.writerow(entry)


if __name__ == '__main__':
	get_forecast_json('42.514794,-71.652153', ['hourly'])