# Adding historic weather details to my Wholemap photos
(Thoughts on adding weather data to historic Toronto photos)

## Introduction
We can get historic weather data from the web through the Environment Canada website, and I have about 1,800 historic photos with specific dates, so why not add a new table with weather data for the dates that I have, then display that along with the other meta-data I have for each photo, like map location, exact date, etc...

## Data source - Environment Canada has historic weather data

We can get historic weather data from the web, like:
http://climate.weather.gc.ca/climateData/hourlydata_e.html?timeframe=1&Prov=ON&StationID=5051&mlyRange=1840-01-01%7C2006-12-01&Year=1958&Month=4&Day=18&cmdB2=Go# 

Here's the call to download a CSV file with the hourly weather data for all the days in the month specified:
http://climate.weather.gc.ca/climateData/bulkdata_e.html?format=csv&stationID=5051&Year=1968&Month=1&Day=15&timeframe=1&submit=Download+Data

But really we're more interested in the daily high and low, so I think this link is more useful:
http://climate.weather.gc.ca/climateData/bulkdata_e.html?format=csv&stationID=5051&Year=1968&Month=1&Day=1&timeframe=2&submit=Download+Data

## Data to store in our database

Here's the data we can get from the CSV file that we'd like to store in the wholemap database for later access:
- Station ID - the stationID parameter
- historical date
- date this data was accessed from the Environment Canada website
- URL used to access the data
- version of my data access and clean script used
- Max Temp (°C)
- Max Temp notes
- Min Temp (°C)
- Min Temp notes
- Total Rain (mm)
- Total Rain notes
- Total Snow (cm)
- Total Snow notes
- Snow on ground (cm)
- Snow on ground notes

## Background and related web pages 

No need to reinvent the wheel here, and maybe I'll do something in R for practice? Here's a detailed blog post on using the bulkdata_e.html call:

http://www.fromthebottomoftheheap.net/2015/01/14/harvesting-canadian-climate-data/

Which uses calls like:

http://climate.weather.gc.ca/climateData/bulkdata_e.html?timeframe=1&Prov=SK&StationID=28011&hlyRange=1996-01-30%7C2014-11-30&cmdB1=Go&Year=2003&Month=5&Day=27&format=csv&stationID=28011

And http://nbviewer.ipython.org/github/jvns/pandas-cookbook/blob/v0.1/cookbook/Chapter%205%20-%20Combining%20dataframes%20and%20scraping%20Canadian%20weather%20data.ipynb looked useful, too
