use weatherDataFromEnvironmentCanada;

my $weatherDataOBJ = weatherDataFromEnvironmentCanada->new(
        'weatherStationID' => '5051',
        'weatherDate' => '1944-12-11'
);

if ( $weatherDataOBJ->wasErrors() ) {
        print "Error creating weather object\n";
        print $weatherDataOBJ->errorString();
} else {
      print "Back on December 11th, 1944 the max temperature in Toronto was ";
      print $weatherDataOBJ->weatherMeasurementValue("maxTemp") . " ";
	  print $weatherDataOBJ->weatherMeasurementUnits("maxTemp") . "\n\n";
	  print "Summary: " . $weatherDataOBJ->weatherSummary();
	  print "\n\n(Using version " . $weatherDataOBJ->weatherObjectVersion() . " of the object.)";
}

# Reads the data from: 
#    http://climate.weather.gc.ca/climateData/bulkdata_e.html?format=csv
#    &stationID=5051&Year=1944&Month=12&Day=11
#    &timeframe=2&submit=Download+Data