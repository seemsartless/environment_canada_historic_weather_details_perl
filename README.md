# wholemap-toronto-weather Repo
(Thoughts on adding weather data to historic Toronto photos)

Environment Canada has historic weather data, like http://climate.weather.gc.ca/climateData/hourlydata_e.html?timeframe=1&Prov=ON&StationID=5051&mlyRange=1840-01-01%7C2006-12-01&Year=1958&Month=4&Day=18&cmdB2=Go# and I have about 1,800 historic photos with specific dates, so why not add a new table with weather data for the dates that I have, and add that information to the meta-data I already have?

No need to reinvent the wheel here, and maybe I'll do something in R for practice? Here's a detailed blog post on using the bulkdata_e.html call:

http://www.fromthebottomoftheheap.net/2015/01/14/harvesting-canadian-climate-data/

Which uses calls like:

http://climate.weather.gc.ca/climateData/bulkdata_e.html?timeframe=1&Prov=SK&StationID=28011&hlyRange=1996-01-30%7C2014-11-30&cmdB1=Go&Year=2003&Month=5&Day=27&format=csv&stationID=28011

And http://nbviewer.ipython.org/github/jvns/pandas-cookbook/blob/v0.1/cookbook/Chapter%205%20-%20Combining%20dataframes%20and%20scraping%20Canadian%20weather%20data.ipynb looked useful, too
