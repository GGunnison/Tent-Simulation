import mechanize
import json
import time as T
import numpy as np
import scipy.io
import csv


'''Author Grant Gunnison, Last modified 1/21/16'''


url ='https://api.forecast.io/forecast/4500ed9ab5c368b9ea32eca07d5c942b/'


'''
Arguments:

location: latitude,longitude (String)
		  
		  Coordinates must be given with 
		  a comma in between, but no spaces


keys:    name of the data entry required from the json (List)

Returns: Json as a dictionary
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

	sunrise = json_dict['daily']['data'][0]['sunriseTime']
	sunset = json_dict['daily']['data'][0]['sunsetTime']
	hour_list = []
	for entry in json_dict['hourly']['data']:
		hour_list.append((entry['apparentTemperature'], entry['time'], entry['icon'], entry['cloudCover']))

	with open('weatherdata1.csv', 'wb') as csvfile:
		wr = csv.writer(csvfile, quoting=csv.QUOTE_ALL)
		wr.writerow(hour_list)

	# min_tmp_list = []
	# min_qsol_list= []
	# for hour in range(len(hour_list)-1):
		
	# 	difference = (hour_list[hour+1][0] - hour_list[hour][0])/60
	# 	temp, time = hour_list[hour][0:2]

	# 	if (hour != (len(hour_list) -2)):
			
	# 		for minute in range(61):
				
	# 			if minute %10 == 0:
	# 				temp += difference
	# 				tmp = ((temp-32)*5/9 + 273.15)-15;
	# 				time += 600
	# 				min_tmp_list.append(round(tmp, 3))
					
	# 				if time < sunrise or time > sunset:
	# 					min_qsol_list.append(0.0)
	# 				elif time > sunrise and time < sunset and hour_list[hour][2] in ['rain', 'snow', 'sleet', 'fog', 'cloudy', 'partly-cloudy-day']:
	# 					coverage_qsol = (1-hour_list[hour][4])*max_qsol
						
	# 					total_day_time = sunset -sunrise
	# 					mid_day = total_day_time/2
	# 					qsol_percentage = abs(time - mid_day)/mid_day
						
	# 					min_qsol_list.append(round(coverage_qsol*qsol_percentage*max_qsol),2)
	# 				elif time > sunrise and time < sunset:

	# 					total_day_time = sunset -sunrise
	# 					mid_day = total_day_time/2.0
	# 					if time < (mid_day + sunrise):
	# 						qsol_percentage = (time-sunrise)/mid_day
	# 						min_qsol_list.append(round((qsol_percentage*max_qsol),2))

	# 					elif time == (mid_day+ sunrise):

	# 						qsol_percentage = 1
	# 						min_qsol_list.append(round((qsol_percentage*max_qsol),2))

	# 					elif time > (mid_day + sunrise):
	# 						qsol_percentage = abs(2*mid_day - (time - sunrise))/mid_day
							
	# 						min_qsol_list.append(round((qsol_percentage*max_qsol),2))
	# 			else:
	# 				continue
	# 	else:
	# 		for minute in range(60):
			
	# 			if minute %10 == 0:
	# 				temp += difference
	# 				tmp = ((temp-32)*5/9 + 273.15)-15;
	# 				time += 600
	# 				min_tmp_list.append(round(tmp, 3))
					
	# 				if time < sunrise or time > sunset:
	# 					min_qsol_list.append(0.0)
	# 				elif time > sunrise and time < sunset and hour_list[hour][2] in ['rain', 'snow', 'sleet', 'fog', 'cloudy', 'partly-cloudy-day']:
	# 					coverage_qsol = (1-hour_list[hour][4])*max_qsol
						
	# 					total_day_time = sunset -sunrise
	# 					mid_day = total_day_time/2
	# 					qsol_percentage = abs(time - mid_day)/mid_day
						
	# 					min_qsol_list.append(round(coverage_qsol*qsol_percentage*max_qsol),2)
	# 				elif time > sunrise and time < sunset:

	# 					total_day_time = sunset -sunrise
	# 					mid_day = total_day_time/2.0
	# 					if time < (mid_day + sunrise):
	# 						qsol_percentage = (time-sunrise)/mid_day
	# 						min_qsol_list.append(round((qsol_percentage*max_qsol),2))

	# 					elif time == (mid_day+ sunrise):

	# 						qsol_percentage = 1
	# 						min_qsol_list.append(round((qsol_percentage*max_qsol),2))

	# 					elif time > (mid_day + sunrise):
	# 						qsol_percentage = abs(2*mid_day - (time - sunrise))/mid_day
							
	# 						min_qsol_list.append(round((qsol_percentage*max_qsol),2))
	# 			else:
	# 				continue


	# forecast = np.zeros((2, len(min_tmp_list)), dtype=np.object)
	# forecast[0], forecast[1] = min_tmp_list, min_qsol_list

	# print forecast

	# scipy.io.savemat('forecast.mat', mdict={'forecast': forecast})
	



if __name__ == '__main__':
	get_forecast_json('42.514794,-71.652153', ['hourly', 'daily'])


