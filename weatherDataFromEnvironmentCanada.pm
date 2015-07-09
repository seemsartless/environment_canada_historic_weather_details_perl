package weatherDataFromEnvironmentCanada;

use strict;

use LWP;
use LWP::RobotUA;

# To-do: Handle 'T' for trace snow, like: 1990-02-04
# To-do: Handle no data items, like May 2004

my $objectVersionNumber = "0.8"; # The first public release!

my $errorString = "";
my $warningString = "";
my $logDetails = "weatherDataFromEnvironmentCanada Log details\n";


# To-do: Better NOT to have these variables outside the new scope
my %possibleDataTemplate = (
	'ISODate'			=> "0,?,date of the weather measurement,ISO date",
	'year' 				=> "1,?,year of the weather measurement,year",
	'month' 			=> "2,?,month of the weather measurement,month",
	'day' 				=> "3,?,day of the weather measurement,day",
	'dataQuality'		=> "4,?,quality of the air,",
	'maxTemp'			=> "5,?,maximum temperature,°C",
	'maxTempFlag'		=> "6,?,maximum temperature flag,",
	'minTemp'			=> "7,?,minimum temperature,°C",
	'minTempFlag'		=> "8,?,minimum temperature flag,",	
	'meanTemp'			=> "9,?,mean temp,°C",	
	'meanTempFlag'		=> "10,?,mean temp flag,",
	'heatDegDays'		=> "11,?,heat deg days,°C",
	'heatDegDaysFlag'	=> "12,?,heat deg days flag,",
	'coolDegDays'		=> "13,?,cool deg days,°C",
	'coolDegDaysFlag'	=> "14,?,cool deg days flag,",
	'totalRain'			=> "15,?,total rain,mm",
	'totalRainFlag'		=> "16,?,total rain flag,",
	'totalSnow'			=> "17,?,total snow,cm",
	'totalSnowFlag'		=> "18,?,total snow flag,",
	'totalPrecip'		=> "19,?,total precip,mm",
	'totalPrecipFlag'	=> "20,?,total precip flag,",
	'snowOnGrnd'		=> "21,?,snow on ground,cm",
	'snowOnGrndFlag'	=> "22,?,snow on ground flag,",
	'dirMaxGust'		=> "23,?,dir of max gust,10s deg",
	'dirMaxGustFlag'	=> "24,?,dir of max gust flag,",
	'spdMaxGust'		=> "25,?,spd of max gust,km/h",
	'spdMaxGustFlag'	=> "26,?,spd of max gust flag,",		
);
my %possibleData = %possibleDataTemplate;


my @dataCols = (
	'ISODate',	
	'year', 		
	'month', 	
	'day', 		
	'dataQuality',
	'maxTemp',	
	'maxTempFlag',
	'minTemp',	
	'minTempFlag',
	'meanTemp',		
	'meanTempFlag',	
	'heatDegDays',	
	'heatDegDaysFlag',
	'coolDegDays',	
	'coolDegDaysFlag',
	'totalRain',		
	'totalRainFlag',	
	'totalSnow',		
	'totalSnowFlag',	
	'totalPrecip',	
	'totalPrecipFlag',
	'snowOnGrnd',	
	'snowOnGrndFlag',
	'dirMaxGust',	
	'dirMaxGustFlag',
	'spdMaxGust',	
	'spdMaxGustFlag',
);

sub new {
    my($class)  = shift;
    my(%params) = @_;
	$logDetails .= "\n=== new subroutine ==\n";
	%possibleData = %possibleDataTemplate;
    
    my $self  = {
    	STATIONID 				=> $params{"weatherStationID"},
		DATETORETRIEVE			=> $params{"weatherDate"},
		CACHEDIR				=> $params{"localCacheDir"},
		RELOADCACHE				=> $params{"reloadCache"},
		SPIDERAGENT				=> $params{"spiderAgent"},
		SPIDERFROM				=> $params{"spiderFrom"},		
		ENVURL					=> undef, # The full URL we'll use to get the data
		ENVHTML					=> undef,
		LOCALFILE				=> undef,
		DATALINE				=> undef,
		SUMMARYLINE				=> undef,
		
	};
    
    bless ($self, $class);
	# Want each of the month and date to be padded with a zero if it isn't already
	$self->{DATETORETRIEVE} = __ISOWithPaddedZeros($self->{DATETORETRIEVE});
	# What if the required parameters are not included?
	if (! defined $params{"weatherStationID"} ) { $errorString .= "Error e5128: weatherStationID not passed when creating new object\n"; }
	if (! defined $params{"weatherDate"} ) 		{ $errorString .= "Error e7692: weatherDate not passed when creating new object\n"; }
	
	# Verify that the required parameters are appropriate
	$errorString .= __verifyWeatherStationID( $params{"weatherStationID"} );
	$errorString .= __verifyWeatherDate( $params{"weatherDate"} );
	
	
	# Now set defaults for parameters if they are NOT passed
	if (! defined $params{"localCacheDir"} ) { 
		$self->{CACHEDIR} = 'cache/'; 
		$warningString .= "Warning w1312: localCacheDir parameter not set, will attempt to use " . $self->{CACHEDIR} . "\n";
	}
	# Either way, verify that the relative local path will work, create it if it doesn't exist
	$errorString .= __verifyOrCreateCacheDir( $self->{CACHEDIR} );
	
	if (! defined $params{"reloadCache"} ) {
		# By default use the local version of the file if it exists
		$self->{RELOADCACHE} = 0;
	}
	
	if (! defined $params{"spiderAgent"} ) {
		# If not specified, use:
		$self->{SPIDERAGENT} = "StockPerlObjWDFEC";
		$warningString .= "Warning w5133: Spider agent parameter not set, will use default of '" . $self->{SPIDERAGENT} . "'\n";
	}
	if (! defined $params{"spiderFrom"} ) {
		# If not specified, use:
		$self->{SPIDERFROM} = 'not-real-email@not-real-domain.org';
		$warningString .= "Warning w3185: Spider e-mail parameter not set, will use default of '" . $self->{SPIDERFROM} . "'\n";
	}
	# We should have everything we need now, assuming there were no errors
	if (length($errorString) > 0 ) {
		# To-do: Add more error checking here, reasonable defaults, etc...
		return $self;
	} 
	
	# OK, lets do this thing!
	
	# Build the URL we'll use:
	$self->{ENVURL} = __buildURL( $self->{STATIONID}, $self->{DATETORETRIEVE} );	
	# Build the local cache file name to use
	$self->{LOCALFILE} = __localFileName( $self->{STATIONID}, $self->{DATETORETRIEVE}, $self->{CACHEDIR} );
	
	# Get the data, locally, or via the web	
	$self->{ENVHTML} = __getEnvHTML( $self->{ENVURL} , $self->{LOCALFILE},  $self->{RELOADCACHE}, $self->{SPIDERAGENT}, $self->{SPIDERFROM} );
	
	# We're only concerned with one date - Find the line that starts with quote ISO-data quote
	
	# "ISO-Date","Year","Month","Day","Data Quality","Max Temp (°C)","Max Temp Flag","Min Temp (°C)","Min Temp Flag","Mean Temp (°C)","Mean Temp Flag",
    # "Heat Deg Days (°C)","Heat Deg Days Flag","Cool Deg Days (°C)","Cool Deg Days Flag","Total Rain (mm)","Total Rain Flag","Total Snow (cm)","Total Snow Flag","Total Precip (mm)","Total Precip Flag",
    # "Snow on Grnd (cm)","Snow on Grnd Flag","Dir of Max Gust (10s deg)","Dir of Max Gust Flag","Spd of Max Gust (km/h)","Spd of Max Gust Flag"

	my $ISODate = $self->{DATETORETRIEVE};
	$self->{ENVHTML} =~ m/($ISODate.*?)$/gims;
	my $tLine = $1;
	# Remove any and all quotation marks
	$tLine =~ s/\"//gims;

	$self->{DATALINE} = $tLine;
	
	# Now spit the $tLine into the ? parameters in the %possibleData
	my @tVals = split(',', $tLine);
	my $count  = 0;
	foreach my $oVal ( @tVals) {
		
		my $thisKey = $dataCols[$count];
		my $hashData = $possibleData{$thisKey};
		# print "\nConsider: " . $oVal . " (column $count - hash key $thisKey) $hashData \n";
		# Line was like: 0,?,Date of the weather measurement
		$hashData =~ s/\,\?\,/\,$oVal\,/gmis;
		# print "\n\tReplacement: $hashData\n";
		$possibleData{$thisKey} = $hashData;
		
		$count++;
	}
	
	# Now generate a summary string, like: Max temp: 1.2 oC - Min temp: -3.2 oC - 3.4 mm rain -... in $self->{SUMMARYLINE}
	my $thisSummary = __summaryLineValue("Max temp:", "maxTemp", "show0");
	$thisSummary   .= __summaryLineValue("Min temp:", "minTemp", "show0");
	$thisSummary   .= __summaryLineValue("Rain fall:", "totalRain", "hide0");
	$thisSummary   .= __summaryLineValue("Snow fall:", "totalSnow", "hide0");
	$thisSummary   .= __summaryLineValue("Snow on ground:", "snowOnGrnd", "hide0");
	
	$self->{SUMMARYLINE} = substr($thisSummary, 0, -3) ;
	
	return $self;
}



sub stationID {
	my $self = shift;
	return  $self->{STATIONID};
}

sub errorString {
	my $self = shift;
	return  $errorString;
}
sub wasErrors {
	my $self = shift;
	if ( length($errorString) > 0 ) {
		return 1;
	} else {
		return 0;
	}
}

sub warningString {
	my $self = shift;
	return $warningString;
}

sub rawHTMLFromEnvCan {
	my $self = shift;
	return $self->{ENVHTML};
}
sub envCanURL {
	my $self = shift;
	return $self->{ENVURL};
}
sub localFileName {
	my $self = shift;
	return $self->{LOCALFILE};
}
sub oneDataLine	{
	my $self = shift;
	return $self->{DATALINE};
}
sub spider {
	my $self = shift;
	return $self->{SPIDERFROM};
}

sub weatherSummary {
	my $self = shift;
	return $self->{SUMMARYLINE};
}

sub weatherMeasurementValue {
	my $self = shift;
	my $param = shift;
	# Return the value for the key $param
	return __weatherMesurementHelper($param, 1);	
}

sub weatherMeasurementDescription {
	my $self = shift;
	my $param = shift;
	# Return the value for the key $param
	return __weatherMesurementHelper($param, 2);	
}

sub weatherMeasurementUnits {
	my $self = shift;
	my $param = shift;
	# Return the value for the key $param
	return __weatherMesurementHelper($param, 3);	
}

sub weatherObjectVersion {
	my $self = shift;
	# Just return the version number of this object
	return $objectVersionNumber;
}


# Internal only helper functions
sub __weatherMesurementHelper {
	my $param = shift;
	my $col = shift;
	
	# Use this to find the value, description, units.... for a given hash key
	my $hashData = $possibleData{$param};
	# Line was like: 0,-8.5,Date of the weather measurement,mm
	(my @vals) = split(',', $hashData);
	return $vals[$col];
}
sub __verifyWeatherStationID {
	# If this is a valid station ID, return no error, otherwise return the error
	my $inpStationID = shift;
	my $returnValue = "";
	# Assume it should just be an integer
	# To-do: __verifyWeatherStationID :: Add more error checking - is it JUST an integer?
	# $returnValue = "Error 8031: weatherStationID value passed is not valid\n";
	return $returnValue;
}
sub __verifyWeatherDate {
	# If this is a valid date, return no error, otherwise return an error
	# To-do: __verifyWeatherDate :: Make sure it is a valid ISO date
	my $inpWeatherDate = shift;
	return "";
}

sub __verifyOrCreateCacheDir {
	# Given a relative path, see if it already exists, otherwise try and create it
	# Return an error if there is a problem
	my $inpPath = shift;
	my $returnValue = "";
	
	if (-e $inpPath) {
		# $returnValue .= "SUCCESS - $inpPath exists!\n";
	} else {
		# To-do: __verifyOrCreateCacheDir :: Try and create the directory if it doesn't already exist
		$returnValue .= "Error e41211: The relative cache path " . $inpPath . " doesn't exist, and the code isn't in place to create it, yet (sorry!)\n";
	}
	return $returnValue;
}

sub __buildURL {
	my $inpStationID = shift;
	my $inpISODate = shift;
	
	my ($tYear, $tMonth, $tDay) = split('-', $inpISODate);
	# print "Consider the date: Year: $tYear    Month: $tMonth    Day: $tDay\n";
	
	my $envCanadaURL = "http://climate.weather.gc.ca/climateData/bulkdata_e.html?format=csv&stationID=";
	$envCanadaURL .= $inpStationID;
	$envCanadaURL .= "&Year=";
	$envCanadaURL .= $tYear;
	$envCanadaURL .= "&Month=";
	$envCanadaURL .= $tMonth;
	$envCanadaURL .= "&Day=";
	$envCanadaURL .= $tDay;
	$envCanadaURL .= "&timeframe=2&submit=Download+Data";
	
	return $envCanadaURL;
}

sub __localFileName {
	my $inpStationID = shift;
	my $inpDate = shift;
	my $inpCacheDir = shift;
	
	# Local file name will be:
	my $cacheFilename = $inpCacheDir . "readEnvCanada-";
	my ($tYear, $tMonth, $tDay) = split('-', $inpDate);
	$cacheFilename .= $inpStationID . "-" . $tYear . "-" . $tMonth . ".csv";
	
	return $cacheFilename;
}


sub __getEnvHTML {
	my $inpURL = shift;
	my $inpLocalFile = shift;
	my $reloadCache = shift;
	my $spiderAgent = shift;
	my $spiderFrom = shift;
	
	# Read the URL, seeing if it is local first if specified... pretty straight forward stuff
	
	my $returnValue = "";
	
	if ( ($reloadCache == 0 ) && (-e $inpLocalFile) ) { 
		print "\nUsed the local cache version of the data from:\n\t$inpLocalFile\n";
		{
			undef local ($/);
			open INP, $inpLocalFile;
			$returnValue = <INP>;
			close INP;
		}		
	} else {
		print "\nLoad the URL from $inpURL\n";
		print "\nUsing Spider agent: '$spiderAgent' and Spider e-mail: '$spiderFrom' \n";
		my $browser = LWP::RobotUA->new($spiderAgent, $spiderFrom); # Respect robots.txt
		$browser->delay( 7/60 );
		my $response = $browser->get( $inpURL );
		die "Can't get $inpURL -- ", $response->status_line unless $response->is_success;
		$returnValue = $response->content;
		
		# Write this to disk for the next run
		open OUTP, ">$inpLocalFile";
		print OUTP $returnValue;
		close OUTP;
		
	}	
	return $returnValue;	
}

sub __summaryLineValue {
	my $inpString = shift;
	my $inpCol = shift;
	my $dealWithZero = shift; # Don't return a string if this is zero - ie snow on ground vs temp of 0.
	my $ret = $inpString . " ";
	# Skip if the value is empty
	my $tValue = __weatherMesurementHelper( $inpCol, 1);
	if (length($tValue) > 0 ) {
		$ret .= $tValue . " ";
		$ret .= __weatherMesurementHelper( $inpCol, 3) . " - "; # The units
	} else {
		# Else don't add this value to the string
		$ret = "";
	}
	# But ignore some measurements if they are zero
	if ( ($dealWithZero eq "hide0" ) && ($tValue == 0) ) {
		$ret = "";
	}
	
	return $ret;
}

sub __ISOWithPaddedZeros {
	my $ISODate = shift; # Pad the month and day, if necessary - 1968-1-5 becomes 1968-01-05
	(my $tY, my $tM, my $tD) = split('-', $ISODate);
	return $tY . "-" . sprintf("%02d", $tM) . "-" . sprintf("%02d", $tD);
}