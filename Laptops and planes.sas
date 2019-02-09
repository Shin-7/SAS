options mprint mlogic symbolgen;

/* Preparing the data */

Libname my_work '/folders/myfolders/Classes' ;

/* Extracting information from the existing variables */

/*
Q1. Flights data contains information for all flights that departed New York City i.e. 
from John F. Kennedy International Airport (JFK), LaGuardia Airport (LGA) or 
from Newark Liberty International Airport (EWR) in 2013.
Create the following new variables:
•	Year from date variable
•	Month from date variable
•	Day from date variable
•	Hour from scheduled departure time variable
•	Departure delay – this captures the difference between departure time and 
	scheduled departure time. Here, negative times should represent early departures, 
	only if they are within a time window of 30mins.
•	Arrival delay – this captures the difference between arrival time and scheduled 
	arrival time. Here, negative times should represent early arrivals, 
	only if they are within a time window of 30mins.
*/

PROC IMPORT DATAFILE='/folders/myfolders/Classes/Case Studies/SAS Case study 1 files/flights.csv'
	DBMS=CSV
	OUT=flights replace;
	GETNAMES=YES;
RUN;


/* PROC CONTENTS DATA=flights; RUN; */

data My_work.flights1;
set flights;
length hour $2 ;
year = year(date);
month = month(date);
day = day(date);
hour = compress(substr(sched_dep_time,1,length(sched_dep_time)-2));
	if dep_time <= 60 then
		departure_delay = intck('minute',hms(substr(sched_dep_time,1,length(sched_dep_time)-2),substr(sched_dep_time,length(sched_dep_time)-1,2),00),hms(00,dep_time,00)); 
		else  departure_delay = intck('minute',hms(substr(sched_dep_time,1,length(sched_dep_time)-2),substr(sched_dep_time,length(sched_dep_time)-1,2),00),hms(substr(dep_time,1,length(dep_time)-2),substr(dep_time,length(dep_time)-1,2),00));

	if departure_delay <= -30 and dep_time <> 0 then departure_delay = departure_delay + 1440;


	if sched_arr_time <= 60 and arr_time <= 60 then 
		arrival_delay = intck('minute',hms(0,sched_arr_time,00),hms(00,arr_time,00));
	else if sched_arr_time <= 60 and arr_time > 60 then 
 		arrival_delay = intck('minute',hms(0,sched_arr_time,00),hms(substr(arr_time,1,length(arr_time)-2),substr(arr_time,length(arr_time)-1,2),00));
	else if sched_arr_time >= 60 and arr_time <= 60 then 
		arrival_delay = intck('minute',hms(substr(sched_arr_time,1,length(sched_arr_time)-2),substr(sched_arr_time,length(sched_arr_time)-1,2),00),hms(0,arr_time,00));
		else arrival_delay =intck('minute',hms(substr(sched_arr_time,1,length(sched_arr_time)-2),substr(sched_arr_time,length(sched_arr_time)-1,2),00),hms(substr(arr_time,1,length(arr_time)-2),substr(arr_time,length(arr_time)-1,2),00));

	
	if arrival_delay <= -30 and arr_time <> 0 then arrival_delay = arrival_delay + 1440;
run;


/* data my_work.flights1; */
/* set my_work.flights1; */
/* where departure_delay < -30 or arrival_delay < -30; */
/* run; */


/*
Q2. Weather data contains hourly meteorological data for John F. Kennedy International Airport 
(JFK), LaGuardia Airport (LGA) and Newark Liberty International Airport (EWR) for 2013. 
Hence, to join the Flights data with Weather data, extract the hour from the scheduled departure
time of the Flights data.

Planes dataset contains metadata for all plane tail numbers found in the FAA aircraft registry. 
This too can be attached to flights data to get information about the planes for each flight. 
For the same, we will be matching talinum variable from Flights data with the plane variable 
from the Planes dataset.
Also, create a variable to account for the years of use, years_use. This is the difference 
between the current year 2013 and manufacturing_year variable.
*/


PROC IMPORT DATAFILE='/folders/myfolders/Classes/Case Studies/SAS Case study 1 files/weather.csv'
	DBMS=CSV
	OUT=weather replace;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=weather; RUN;


data my_work.weather;
set weather;
length hours $2;
hours = substr(time, 1,find(time, ":")-1) ;
run;

proc sql;

create table new as 
select T1.*, T2.* from my_work.flights1 as T1
left join my_work.weather as T2 on T1.hour = T2.hours and T1.Origin = T2.origin and 
t1.date = t2.date
;
quit;

data MY_WORK.PLANES    ;
infile '/folders/myfolders/Classes/Case Studies/SAS Case study 1 files/planes.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat type $10. ;
informat model $15. ;
informat engine $15. ;
informat manufacturer $30. ;
input
 plane  $
 manufacturing_year
 type  $
 manufacturer  $
 model  $
 engines
 seats
 speed  $
 engine  $
 fuel_cc
 ;
 run;

Data my_work.planes;
set my_work.planes;
year_use = 2013 - manufacturing_year; 
run;

 
proc sql;

create table new1 as 
select * from my_work.flights1 as T1
inner join my_work.planes as T2 on T1.tailnum = T2.plane
;
quit;




/*
Dealing with Missing data –
Missing values are to be treated separately and are an important part of data preparation. 
If data is missing for key variables, then we might decide to delete the observation. 
If the variable is not important, we can also delete the variable.

Missing values can also be imputed. In some cases we replace missing values with aggregated 
numbers from the entire dataset, but in some cases these replacements have to be calculated 
particular to sector and used accordingly. For eg: Replacing avg income by gender instead of 
by overall population avg.

While answering the below questions, try to understand the reason for taking different 
approaches while dealing with missing data.

 
Q3.
 

(i)	In the flights data: 
•	Calculate the missing values present in each variable
•	Delete all observations where a missing value in any of the following variables: 
tail number, departure time and arrival time.
•	Replace the missing values for:
o	Arr_delay with the average delay on the specific route (origin -> destination) for the specific carrier
o	Air_time with the average airtime on the specific route (origin -> destination) for the specific carrier
*/

proc contents data = my_work.flights1 ;
run;

proc format ;
value $missfmt ' ' = 'missing' other = 'Not missing';
value missfmt . = 'missing' other = 'Not missing';
run;
	
proc freq data= my_work.flights1;
format _CHAR_ $missfmt.;
tables	_CHAR_ / missing missprint nocum nofreq nopercent;
format _NUMERIC_ missfmt.;
tables _NUMERIC_ / missing missprint nocum nopercent;
run;



data flights2;
set my_work.flights1;
if tailnum = "" then delete;
if dep_time = . then delete;
if arr_time = . then delete;
run;


proc sql;
create table averages as 
select *, avg(arrival_delay) as avg_arr_delay, avg(air_time) as avg_air_time from flights2 
group by origin, dest, carrier
;
quit;


data my_work.flights1 (drop= avg_arr_delay avg_air_time) ;
set averages;
if arrival_delay = . then arrival_delay = avg_arr_delay;
if air_time = . then air_time = avg_air_time;
run;



/* (ii)	In the weather data: */
/* •	Calculate the missing values present in each variable */
/* •	Replace the missing data for weather conditions with average weather conditions at that airport on that day. */


proc freq data= my_work.weather;
format _CHAR_ $missfmt.;
tables	_CHAR_ / missing missprint nocum nofreq nopercent;
format _NUMERIC_ missfmt.;
tables _NUMERIC_ / missing missprint nocum nopercent;
run;


proc sql;
create table averages_weather as 
select *, avg(temp) as avg_temp, avg(dewp) as avg_dewp, avg(humid) as avg_humid, 
avg(wind_dir) as avg_wind_dir, avg(wind_gust) as avg_wind_gust,  avg(wind_speed) as avg_wind_speed, 
avg(pressure) as avg_pressure from my_work.weather 
group by origin, date
;
quit;


proc contents data=my_work.weather;
run;

data my_work.weather(drop= avg_temp avg_dewp avg_humid avg_wind_dir avg_wind_gust avg_wind_speed avg_pressure); 
set averages_weather;
if temp= . then temp = avg_temp;
if dewp= . then dewp = avg_dewp;
if humid= . then humid = avg_humid;
if wind_dir= . then wind_dir = avg_wind_dir;
if wind_gust= . then wind_gust = avg_wind_gust;
if wind_speed= . then wind_speed = avg_wind_speed;
if pressure= . then pressure = avg_pressure;
run;

/* (iii)In the planes data: */
/* •	Calculate the missing values present in each variable */
/* •	Remove redundant variables with more than 70% missing values. */
/* •	Remove all the observations with any missing values.  */


proc freq data= my_work.planes;
format _CHAR_ $missfmt.;
tables	_CHAR_ / missing missprint nocum nofreq ;
format _NUMERIC_ missfmt.;
tables _NUMERIC_ / missing missprint nocum nofreq;
run;

data planes1;
set my_work.planes(drop= speed) ;
if manufacturing_year = . or fuel_cc=. then delete;
run;



/*
Formatting –
Q4
i.	Assign appropriate variable names and labels using the data dictionary provided. This is 
necessary to ensure that your final reports are in a presentable format. Carry out this exercise for each dataset provided.
*/


data my_work.flights1;
set my_work.flights1;
label
date  =  'date of departure'
dep_time =  'Actual departure time'
arr_time  = 'Actual arrival times'
sched_dep_time=  'Scheduled departure times'
sched_arr_time = 'Scheduled arrival times'
carrier  =  'Two letter carrier abbreviation'
flight  =  'Flight number'
tailnum  =  'Plane tail number'
origin  =  'Origin' 
dest = 'Destination'
distance  =  'Distance flown'
air_time  =  'Amount of time spent in the air, in minutes';
run;

data my_work.weather;
set my_work.weather;
label
origin  =  'Origin'
date =  'date of recording'
time  ='time of recording'
temp =  'Temperature in F'
dewp  = 'dewpoint in F'
humid  =  'Relative humidity'
wind_dir  =  'Wind direction (in degrees)'
wind_speed = 'speed (in mph)'
wind_gust = 'gust speed (in mph)'
precip  =  'Preciptation, in inches'
pressure  =  'Sea level pressure in millibars'
visib  =  'Visibility in miles'
;
run;

data my_work.planes;
set my_work.planes;
label
plane  =  'Tail number'
year  =  'Year manufactured'
type  =  'Type of plane'
manufacturer ='Manufacturer'
model  =  'model'
engines  =  'Number of engines'
seats  =  'Number of seats'
speed  =  'Average cruising speed in mph'
engine  =  'Type of engine'
fuel_cc  =  'Average annual fuel consumption cost'
;
run;


data my_work.airport;
set my_work.airport;
label
faa  =  'FAA airport code'
name  =  'Usual name of the aiport'
lat, lon  =  'Location of airport'
;
run;

data my_work.airlines;
set my_work.airlines;
label
carrier  =  'Two letter abbreviation'
name  =  'Full name'
;
run;


/* ii.	In the planes data, */
/* •	Format the variable average annual fuel consumption cost (fuel_cc): round off the value to  */
/* the nearest integer and use appropriate formatting. */


data my_work.planes;
set my_work.planes;
fuel_cc = round(fuel_cc);
run;



/* iii.	In the flights data, */
/* •	Add value labels to different carrier codes using airlines data. */
/* •	Add value labels to origin and destination using the airports data. */
/* •	Flight variable is unique code for a flight and should not be considered as a numerical  */
/* variable. Convert it to character variable. */


proc format lib=  WORK;
value $ f_airlines
'9E' = 'Endeavor Air Inc.'
'AA' = 'American Airlines Inc.'
'AS' = 'Alaska Airlines Inc.'
'B6' = 'JetBlue Airways'
'DL' = 'Delta Air Lines Inc.'
'EV' = 'ExpressJet Airlines Inc.'
'F9' = 'Frontier Airlines Inc.'
'FL' = 'AirTran Airways Corporation'
'HA' = 'Hawaiian Airlines Inc.'
'MQ' = 'Envoy Air'
'OO' = 'SkyWest Airlines Inc.'
'UA' = 'United Air Lines Inc.'
'US' = 'US Airways Inc.'
'VX' = 'Virgin America'
'WN' = 'Southwest Airlines Co.'
'YV' = 'Mesa Airlines Inc.'
;
value $ f_airports
'04G' = " Lansdowne Airport"
'06A' = " Moton Field Municipal Airport"
'06C' = " Schaumburg Regional"
'06N' = " Randall Airport"
'09J' = " Jekyll Island Airport"
'0A9' = " Elizabethton Municipal Airport"
'0G6' = " Williams County Airport"
'0G7' = " Finger Lakes Regional Airport"
'0P2' = " Shoestring Aviation Airfield"
'0S9' = " Jefferson County Intl"
'0W3' = " Harford County Airport"
'10C' = " Galt Field Airport"
'17G' = " Port Bucyrus-Crawford County Airport"
'19A' = " Jackson County Airport"
'1A3' = " Martin Campbell Field Airport"
'1B9' = " Mansfield Municipal"
'1C9' = " Frazier Lake Airpark"
'1CS' = " Clow International Airport"
'1G3' = " Kent State Airport"
'1OH' = " Fortman Airport"
'1RL' = " Point Roberts Airpark"
'24C' = " Lowell City Airport"
'24J' = " Suwannee County Airport"
'25D' = " Forest Lake Airport"
'29D' = " Grove City Airport"
'2A0' = " Mark Anton Airport"
'2G2' = " Jefferson County Airpark"
'2G9' = " Somerset County Airport"
'2J9' = " Quincy Municipal Airport"
'369' = " Atmautluak Airport"
'36U' = " Heber City Municipal Airport"
'38W' = " Lynden Airport"
'3D2' = " Ephraim-Gibraltar Airport"
'3G3' = " Wadsworth Municipal"
'3G4' = " Ashland County Airport"
'3J1' = " Ridgeland Airport"
'3W2' = " Put-in-Bay Airport"
'40J' = " Perry-Foley Airport"
'41N' = " Braceville Airport"
'47A' = " Cherokee County Airport"
'49A' = " Gilmer County Airport"
'49X' = " Chemehuevi Valley"
'4A4' = " Polk County Airport - Cornelius Moore Field"
'4A7' = " Clayton County Tara Field"
'4A9' = " Isbell Field Airport"
'4B8' = " Robertson Field"
'4G0' = " Pittsburgh-Monroeville Airport"
'4G2' = " Hamburg Inc Airport"
'4G4' = " Youngstown Elser Metro Airport"
'4I7' = " Putnam County Airport"
'4U9' = " Dell Flight Strip"
'52A' = " Madison GA Municipal Airport"
'54J' = " DeFuniak Springs Airport"
'55J' = " Fernandina Beach Municipal Airport"
'57C' = " East Troy Municipal Airport"
'60J' = " Ocean Isle Beach Airport"
'6A2' = " Griffin-Spalding County Airport"
'6K8' = " Tok Junction Airport"
'6S0' = " Big Timber Airport"
'6S2' = " Florence"
'6Y8' = " Welke Airport"
'70J' = " Cairo-Grady County Airport"
'70N' = " Spring Hill Airport"
'7A4' = " Foster Field"
'7D9' = " Germack Airport"
'7N7' = " Spitfire Aerodrome"
'8M8' = " Garland Airport"
'93C' = " Richland Airport"
'99N' = " Bamberg County Airport"
'9A1' = " Covington Municipal Airport"
'9A5' = " Barwick Lafayette Airport"
'A39' = " Phoenix Regional Airport"
'AAF' = " Apalachicola Regional Airport"
'ABE' = " Lehigh Valley Intl"
'ABI' = " Abilene Rgnl"
'ABL' = " Ambler Airport"
'ABQ' = " Albuquerque International Sunport"
'ABR' = " Aberdeen Regional Airport"
'ABY' = " Southwest Georgia Regional Airport"
'ACK' = " Nantucket Mem"
'ACT' = " Waco Rgnl"
'ACV' = " Arcata"
'ACY' = " Atlantic City Intl"
'ADK' = " Adak Airport"
'ADM' = " Ardmore Muni"
'ADQ' = " Kodiak"
'ADS' = " Addison"
'ADW' = " Andrews Afb"
'AET' = " Allakaket Airport"
'AEX' = " Alexandria Intl"
'AFE' = " Kake Airport"
'AFW' = " Fort Worth Alliance Airport"
'AGC' = " Allegheny County Airport"
'AGN' = " Angoon Seaplane Base"
'AGS' = " Augusta Rgnl At Bush Fld"
'AHN' = " Athens Ben Epps Airport"
'AIA' = " Alliance Municipal Airport"
'AIK' = " Municipal Airport"
'AIN' = " Wainwright Airport"
'AIZ' = " Lee C Fine Memorial Airport"
'AKB' = " Atka Airport"
'AKC' = " Akron Fulton Intl"
'AKI' = " Akiak Airport"
'AKK' = " Akhiok Airport"
'AKN' = " King Salmon"
'AKP' = " Anaktuvuk Pass Airport"
'ALB' = " Albany Intl"
'ALI' = " Alice Intl"
'ALM' = " Alamogordo White Sands Regional Airport"
'ALO' = " Waterloo Regional Airport"
'ALS' = " San Luis Valley Regional Airport"
'ALW' = " Walla Walla Regional Airport"
'ALX' = " Alexandria"
'ALZ' = " Alitak Seaplane Base"
'AMA' = " Rick Husband Amarillo Intl"
'ANB' = " Anniston Metro"
'ANC' = " Ted Stevens Anchorage Intl"
'AND' = " Anderson Rgnl"
'ANI' = " Aniak Airport"
'ANN' = " Annette Island"
'ANP' = " Lee Airport"
'ANQ' = " Tri-State Steuben County Airport"
'ANV' = " Anvik Airport"
'AOH' = " Lima Allen County Airport"
'AOO' = " Altoona Blair Co"
'AOS' = " Amook Bay Seaplane Base"
'APA' = " Centennial"
'APC' = " Napa County Airport"
'APF' = " Naples Muni"
'APG' = " Phillips Aaf"
'APN' = " Alpena County Regional Airport"
'AQC' = " Klawock Seaplane Base"
'ARA' = " Acadiana Rgnl"
'ARB' = " Ann Arbor Municipal Airport"
'ARC' = " Arctic Village Airport"
'ART' = " Watertown Intl"
'ARV' = " Lakeland"
'ASE' = " Aspen Pitkin County Sardy Field"
'ASH' = " Boire Field Airport"
'AST' = " Astoria Regional Airport"
'ATK' = " Atqasuk Edward Burnell Sr Memorial Airport"
'ATL' = " Hartsfield Jackson Atlanta Intl"
'ATT' = " Camp Mabry Austin City"
'ATW' = " Appleton"
'ATY' = " Watertown Regional Airport"
'AUG' = " Augusta State"
'AUK' = " Alakanuk Airport"
'AUS' = " Austin Bergstrom Intl"
'AUW' = " Wausau Downtown Airport"
'AVL' = " Asheville Regional Airport"
'AVO' = " Executive"
'AVP' = " Wilkes Barre Scranton Intl"
'AVW' = " Marana Regional"
'AVX' = " Avalon"
'AZA' = " Phoenix-Mesa Gateway"
'AZO' = " Kalamazoo"
'BAB' = " Beale Afb"
'BAD' = " Barksdale Afb"
'BAF' = " Barnes Municipal"
'BBX' = " Wings Field"
'BCE' = " Bryce Canyon"
'BCT' = " Boca Raton"
'BDE' = " Baudette Intl"
'BDL' = " Bradley Intl"
'BDR' = " Igor I Sikorsky Mem"
'BEC' = " Beech Factory Airport"
'BED' = " Laurence G Hanscom Fld"
'BEH' = " Southwest Michigan Regional Airport"
'BET' = " Bethel"
'BFD' = " Bradford Regional Airport"
'BFF' = " Western Nebraska Regional Airport"
'BFI' = " Boeing Fld King Co Intl"
'BFL' = " Meadows Fld"
'BFM' = " Mobile Downtown"
'BFP' = " Beaver Falls"
'BFT' = " Beaufort"
'BGE' = " Decatur County Industrial Air Park"
'BGM' = " Greater Binghamton Edwin A Link Fld"
'BGR' = " Bangor Intl"
'BHB' = " Hancock County - Bar Harbor"
'BHM' = " Birmingham Intl"
'BID' = " Block Island State Airport"
'BIF' = " Biggs Aaf"
'BIG' = " Allen Aaf"
'BIL' = " Billings Logan International Airport"
'BIS' = " Bismarck Municipal Airport"
'BIV' = " Tulip City Airport"
'BIX' = " Keesler Afb"
'BJC' = " Rocky Mountain Metropolitan Airport"
'BJI' = " Bemidji Regional Airport"
'BKC' = " Buckland Airport"
'BKD' = " Stephens Co"
'BKF' = " Buckley Afb"
'BKG' = " Branson LLC"
'BKH' = " Barking Sands Pmrf"
'BKL' = " Burke Lakefront Airport"
'BKW' = " Raleigh County Memorial Airport"
'BKX' = " Brookings Regional Airport"
'BLD' = " Boulder City Municipal Airport"
'BLF' = " Mercer County Airport"
'BLH' = " Blythe Airport"
'BLI' = " Bellingham Intl"
'BLV' = " Scott Afb Midamerica"
'BMC' = " Brigham City"
'BMG' = " Monroe County Airport"
'BMI' = " Central Illinois Rgnl"
'BMX' = " Big Mountain Afs"
'BNA' = " Nashville Intl"
'BOI' = " Boise Air Terminal"
'BOS' = " General Edward Lawrence Logan Intl"
'BOW' = " Bartow Municipal Airport"
'BPT' = " Southeast Texas Rgnl"
'BQK' = " Brunswick Golden Isles Airport"
'BRD' = " Brainerd Lakes Rgnl"
'BRL' = " Southeast Iowa Regional Airport"
'BRO' = " Brownsville South Padre Island Intl"
'BRW' = " Wiley Post Will Rogers Mem"
'BSF' = " Bradshaw Aaf"
'BTI' = " Barter Island Lrrs"
'BTM' = " Bert Mooney Airport"
'BTR' = " Baton Rouge Metro Ryan Fld"
'BTT' = " Bettles"
'BTV' = " Burlington Intl"
'BUF' = " Buffalo Niagara Intl"
'BUR' = " Bob Hope"
'BUU' = " Municipal Airport"
'BUY' = " Burlington-Alamance Regional Airport"
'BVY' = " Beverly Municipal Airport"
'BWD' = " KBWD"
'BWG' = " Bowling Green-Warren County Regional Airport"
'BWI' = " Baltimore Washington Intl"
'BXK' = " Buckeye Municipal Airport"
'BXS' = " Borrego Valley Airport"
'BYH' = " Arkansas Intl"
'BYS' = " Bicycle Lake Aaf"
'BYW' = " Blakely Island Airport"
'BZN' = " Gallatin Field"
'C02' = " Grand Geneva Resort Airport"
'C16' = " Frasca Field"
'C47' = " Portage Municipal Airport"
'C65' = " Plymouth Municipal Airport"
'C89' = " Sylvania Airport"
'C91' = " Dowagiac Municipal Airport"
'CAE' = " Columbia Metropolitan"
'CAK' = " Akron Canton Regional Airport"
'CAR' = " Caribou Muni"
'CBE' = " Greater Cumberland Rgnl."
'CBM' = " Columbus Afb"
'CCO' = " Coweta County Airport"
'CCR' = " Buchanan Field Airport"
'CDB' = " Cold Bay"
'CDC' = " Cedar City Rgnl"
'CDI' = " Cambridge Municipal Airport"
'CDK' = " CedarKey"
'CDN' = " Woodward Field"
'CDR' = " Chadron Municipal Airport"
'CDS' = " Childress Muni"
'CDV' = " Merle K Mudhole Smith"
'CDW' = " Caldwell Essex County Airport"
'CEC' = " Del Norte County Airport"
'CEF' = " Westover Arb Metropolitan"
'CEM' = " Central Airport"
'CEU' = " Clemson"
'CEW' = " Bob Sikes"
'CEZ' = " Cortez Muni"
'CFD' = " Coulter Fld"
'CGA' = " Craig Seaplane Base"
'CGF' = " Cuyahoga County"
'CGI' = " Cape Girardeau Regional Airport"
'CGX' = " Meigs Field"
'CGZ' = " Casa Grande Municipal Airport"
'CHA' = " Lovell Fld"
'CHI' = " All Airports"
'CHO' = " Charlottesville-Albemarle"
'CHS' = " Charleston Afb Intl"
'CHU' = " Chuathbaluk Airport"
'CIC' = " Chico Muni"
'CID' = " Cedar Rapids"
'CIK' = " Chalkyitsik Airport"
'CIL' = " Council Airport"
'CIU' = " Chippewa County International Airport"
'CKB' = " Harrison Marion Regional Airport"
'CKD' = " Crooked Creek Airport"
'CKF' = " Crisp County Cordele Airport"
'CKV' = " Clarksville-Montgomery County Regional Airport"
'CLC' = " Clear Lake Metroport"
'CLD' = " McClellan-Palomar Airport"
'CLE' = " Cleveland Hopkins Intl"
'CLL' = " Easterwood Fld"
'CLM' = " William R Fairchild International Airport"
'CLT' = " Charlotte Douglas Intl"
'CLW' = " Clearwater Air Park"
'CMH' = " Port Columbus Intl"
'CMI' = " Champaign"
'CMX' = " Houghton County Memorial Airport"
'CNM' = " Cavern City Air Terminal"
'CNW' = " Tstc Waco"
'CNY' = " Canyonlands Field"
'COD' = " Yellowstone Rgnl"
'COF' = " Patrick Afb"
'CON' = " Concord Municipal"
'COS' = " City Of Colorado Springs Muni"
'COT' = " Cotulla Lasalle Co"
'COU' = " Columbia Rgnl"
'CPR' = " Natrona Co Intl"
'CPS' = " St. Louis Downtown Airport"
'CRE' = " Grand Strand Airport"
'CRP' = " Corpus Christi Intl"
'CRW' = " Yeager"
'CSG' = " Columbus Metropolitan Airport"
'CTB' = " Cut Bank Muni"
'CTH' = " Chester County G O Carlson Airport"
'CTJ' = " West Georgia Regional Airport - O V Gray Field"
'CTY' = " Cross City"
'CVG' = " Cincinnati Northern Kentucky Intl"
'CVN' = " Clovis Muni"
'CVS' = " Cannon Afb"
'CVX' = " Charlevoix Municipal Airport"
'CWA' = " Central Wisconsin"
'CWI' = " Clinton Municipal"
'CXF' = " Coldfoot Airport"
'CXL' = " Calexico Intl"
'CXO' = " Lone Star Executive"
'CXY' = " Capital City Airport"
'CYF' = " Chefornak Airport"
'CYM' = " Chatham Seaplane Base"
'CYS' = " Cheyenne Rgnl Jerry Olson Fld"
'CYT' = " Yakataga Airport"
'CZF' = " Cape Romanzof Lrrs"
'CZN' = " Chisana Airport"
'DAB' = " Daytona Beach Intl"
'DAL' = " Dallas Love Fld"
'DAY' = " James M Cox Dayton Intl"
'DBQ' = " Dubuque Rgnl"
'DCA' = " Ronald Reagan Washington Natl"
'DDC' = " Dodge City Regional Airport"
'DEC' = " Decatur"
'DEN' = " Denver Intl"
'DET' = " Coleman A Young Muni"
'DFW' = " Dallas Fort Worth Intl"
'DGL' = " Douglas Municipal Airport"
'DHN' = " Dothan Rgnl"
'DHT' = " Dalhart Muni"
'DIK' = " Dickinson Theodore Roosevelt Regional Airport"
'DKB' = " De Kalb Taylor Municipal Airport"
'DKK' = " Chautauqua County-Dunkirk Airport"
'DKX' = " Knoxville Downtown Island Airport"
'DLF' = " Laughlin Afb"
'DLG' = " Dillingham"
'DLH' = " Duluth Intl"
'DLL' = " Baraboo Wisconsin Dells Airport"
'DMA' = " Davis Monthan Afb"
'DNL' = " Daniel Field Airport"
'DNN' = " Dalton Municipal Airport"
'DOV' = " Dover Afb"
'DPA' = " Dupage"
'DQH' = " Douglas Municipal Airport"
'DRG' = " Deering Airport"
'DRI' = " Beauregard Rgnl"
'DRM' = " Drummond Island Airport"
'DRO' = " Durango La Plata Co"
'DRT' = " Del Rio Intl"
'DSM' = " Des Moines Intl"
'DTA' = " Delta Municipal Airport"
'DTS' = " Destin"
'DTW' = " Detroit Metro Wayne Co"
'DUC' = " Halliburton Field Airport"
'DUG' = " Bisbee Douglas Intl"
'DUJ' = " DuBois Regional Airport"
'DUT' = " Unalaska"
'DVL' = " Devils Lake Regional Airport"
'DVT' = " Deer Valley Municipal Airport"
'DWA' = " Yolo County Airport"
'DWH' = " David Wayne Hooks Field"
'DWS' = " Orlando"
'DXR' = " Danbury Municipal Airport"
'DYS' = " Dyess Afb"
'E25' = " Wickenburg Municipal Airport"
'E51' = " Bagdad Airport"
'E55' = " Ocean Ridge Airport"
'E63' = " Gila Bend Municipal Airport"
'E91' = " Chinle Municipal Airport"
'EAA' = " Eagle Airport"
'EAR' = " Kearney Municipal Airport"
'EAT' = " Pangborn Field"
'EAU' = " Chippewa Valley Regional Airport"
'ECA' = " Iosco County"
'ECG' = " Elizabeth City Cgas Rgnl"
'ECP' = " Panama City-NW Florida Bea."
'EDF' = " Elmendorf Afb"
'EDW' = " Edwards Afb"
'EEK' = " Eek Airport"
'EEN' = " Dillant Hopkins Airport"
'EET' = " Shelby County Airport"
'EFD' = " Ellington Fld"
'EGA' = " Eagle County Airport"
'EGE' = " Eagle Co Rgnl"
'EGT' = " Wellington Municipal"
'EGV' = " Eagle River"
'EGX' = " Egegik Airport"
'EHM' = " Cape Newenham Lrrs"
'EIL' = " Eielson Afb"
'EKI' = " Elkhart Municipal"
'EKN' = " Elkins Randolph Co Jennings Randolph"
'EKO' = " Elko Regional Airport"
'ELD' = " South Arkansas Rgnl At Goodwin Fld"
'ELI' = " Elim Airport"
'ELM' = " Elmira Corning Rgnl"
'ELP' = " El Paso Intl"
'ELV' = " Elfin Cove Seaplane Base"
'ELY' = " Ely Airport"
'EMK' = " Emmonak Airport"
'EMP' = " Emporia Municipal Airport"
'ENA' = " Kenai Muni"
'END' = " Vance Afb"
'ENV' = " Wendover"
'ENW' = " Kenosha Regional Airport"
'EOK' = " Keokuk Municipal Airport"
'EPM' = " Eastport Municipal Airport"
'EQY' = " Monroe Reqional Airport"
'ERI' = " Erie Intl Tom Ridge Fld"
'ERV' = " Kerrville Municipal Airport"
'ERY' = " Luce County Airport"
'ESC' = " Delta County Airport"
'ESD' = " Orcas Island Airport"
'ESF' = " Esler Rgnl"
'ESN' = " Easton-Newnam Field Airport"
'EUG' = " Mahlon Sweet Fld"
'EVV' = " Evansville Regional"
'EWB' = " New Bedford Regional Airport"
'EWN' = " Craven Co Rgnl"
'EWR' = " Newark Liberty Intl"
'EXI' = " Excursion Inlet Seaplane Base"
'EYW' = " Key West Intl"
'F57' = " Seaplane Base"
'FAF' = " Felker Aaf"
'FAI' = " Fairbanks Intl"
'FAR' = " Hector International Airport"
'FAT' = " Fresno Yosemite Intl"
'FAY' = " Fayetteville Regional Grannis Field"
'FBG' = " Fredericksburg Amtrak Station"
'FBK' = " Ladd Aaf"
'FBS' = " Friday Harbor Seaplane Base"
'FCA' = " Glacier Park Intl"
'FCS' = " Butts Aaf"
'FDY' = " Findlay Airport"
'FFA' = " First Flight Airport"
'FFC' = " Atlanta Regional Airport - Falcon Field"
'FFO' = " Wright Patterson Afb"
'FFT' = " Capital City Airport"
'FFZ' = " Mesa Falcon Field"
'FHU' = " Sierra Vista Muni Libby Aaf"
'FIT' = " Fitchburg Municipal Airport"
'FKL' = " Franklin"
'FLD' = " Fond Du Lac County Airport"
'FLG' = " Flagstaff Pulliam Airport"
'FLL' = " Fort Lauderdale Hollywood Intl"
'FLO' = " Florence Rgnl"
'FLV' = " Sherman Aaf"
'FME' = " Tipton"
'FMH' = " Otis Angb"
'FMN' = " Four Corners Rgnl"
'FMY' = " Page Fld"
'FNL' = " Fort Collins Loveland Muni"
'FNR' = " Funter Bay Seaplane Base"
'FNT' = " Bishop International"
'FOD' = " Fort Dodge Rgnl"
'FOE' = " Forbes Fld"
'FOK' = " Francis S Gabreski"
'FRD' = " Friday Harbor Airport"
'FRI' = " Marshall Aaf"
'FRN' = " Bryant Ahp"
'FRP' = " St Lucie County International Airport"
'FSD' = " Sioux Falls"
'FSI' = " Henry Post Aaf"
'FSM' = " Fort Smith Rgnl"
'FST' = " Fort Stockton Pecos Co"
'FTK' = " Godman Aaf"
'FTW' = " Fort Worth Meacham Intl"
'FTY' = " Fulton County Airport Brown Field"
'FUL' = " Fullerton Municipal Airport"
'FWA' = " Fort Wayne"
'FXE' = " Fort Lauderdale Executive"
'FYU' = " Fort Yukon"
'FYV' = " Drake Fld"
'FZG' = " Fitzgerald Municipal Airport"
'GAD' = " Northeast Alabama Regional Airport"
'GAI' = " Montgomery County Airpark"
'GAL' = " Edward G Pitka Sr"
'GAM' = " Gambell Airport"
'GBN' = " Great Bend Municipal"
'GCC' = " Gillette-Campbell County Airport"
'GCK' = " Garden City Rgnl"
'GCN' = " Grand Canyon National Park Airport"
'GCW' = " Grand Canyon West Airport"
'GDV' = " Dawson Community Airport"
'GDW' = " Gladwin Zettel Memorial Airport"
'GED' = " Sussex Co"
'GEG' = " Spokane Intl"
'GEU' = " Glendale Municipal Airport"
'GFK' = " Grand Forks Intl"
'GGE' = " Georgetown County Airport"
'GGG' = " East Texas Rgnl"
'GGW' = " Wokal Field Glasgow International Airport"
'GHG' = " Marshfield Municipal Airport"
'GIF' = " Gilbert Airport"
'GJT' = " Grand Junction Regional"
'GKN' = " Gulkana"
'GKY' = " Arlington Municipal"
'GLD' = " Renner Fld"
'GLH' = " Mid Delta Regional Airport"
'GLS' = " Scholes Intl At Galveston"
'GLV' = " Golovin Airport"
'GNT' = " Grants Milan Muni"
'GNU' = " Goodnews Airport"
'GNV' = " Gainesville Rgnl"
'GON' = " Groton New London"
'GPT' = " Gulfport-Biloxi"
'GPZ' = " Grand Rapids Itasca County"
'GQQ' = " Galion Municipal Airport"
'GRB' = " Austin Straubel Intl"
'GRF' = " Gray Aaf"
'GRI' = " Central Nebraska Regional Airport"
'GRK' = " Robert Gray Aaf"
'GRM' = " Grand Marais Cook County Airport"
'GRR' = " Gerald R Ford Intl"
'GSB' = " Seymour Johnson Afb"
'GSO' = " Piedmont Triad"
'GSP' = " Greenville-Spartanburg International"
'GST' = " Gustavus Airport"
'GTB' = " Wheeler Sack Aaf"
'GTF' = " Great Falls Intl"
'GTR' = " Golden Triangle Regional Airport"
'GTU' = " Georgetown Municipal Airport"
'GUC' = " Gunnison - Crested Butte"
'GUP' = " Gallup Muni"
'GUS' = " Grissom Arb"
'GVL' = " Lee Gilmer Memorial Airport"
'GVQ' = " Genesee County Airport"
'GVT' = " Majors"
'GWO' = " Greenwood Leflore"
'GYY' = " Gary Chicago International Airport"
'HBG' = " Hattiesburg Bobby L. Chain Municipal Airport"
'HBR' = " Hobart Muni"
'HCC' = " Columbia County"
'HCR' = " Holy Cross Airport"
'HDH' = " Dillingham"
'HDI' = " Hardwick Field Airport"
'HDN' = " Yampa Valley"
'HDO' = " Hondo Municipal Airport"
'HFD' = " Hartford Brainard"
'HGR' = " Hagerstown Regional Richard A Henson Field"
'HHH' = " Hilton Head"
'HHI' = " Wheeler Aaf"
'HHR' = " Jack Northrop Fld Hawthorne Muni"
'HIB' = " Chisholm Hibbing"
'HIF' = " Hill Afb"
'HII' = " Lake Havasu City Airport"
'HIO' = " Portland Hillsboro"
'HKB' = " Healy River Airport"
'HKY' = " Hickory Rgnl"
'HLG' = " Wheeling Ohio County Airport"
'HLN' = " Helena Rgnl"
'HLR' = " Hood Aaf"
'HMN' = " Holloman Afb"
'HNH' = " Hoonah Airport"
'HNL' = " Honolulu Intl"
'HNM' = " Hana"
'HNS' = " Haines Airport"
'HOB' = " Lea Co Rgnl"
'HOM' = " Homer"
'HON' = " Huron Rgnl"
'HOP' = " Campbell Aaf"
'HOT' = " Memorial Field"
'HOU' = " William P Hobby"
'HPB' = " Hooper Bay Airport"
'HPN' = " Westchester Co"
'HQM' = " Bowerman Field"
'HQU' = " McDuffie County Airport"
'HRL' = " Valley Intl"
'HRO' = " Boone Co"
'HRT' = " Hurlburt Fld"
'HSH' = " Henderson Executive Airport"
'HSL' = " Huslia Airport"
'HST' = " Homestead Arb"
'HSV' = " Huntsville International Airport-Carl T Jones Field"
'HTL' = " Roscommon Co"
'HTS' = " Tri State Milton J Ferguson Field"
'HUA' = " Redstone Aaf"
'HUF' = " Terre Haute Intl Hulman Fld"
'HUL' = " Houlton Intl"
'HUS' = " Hughes Airport"
'HUT' = " Hutchinson Municipal Airport"
'HVN' = " Tweed-New Haven Airport"
'HVR' = " Havre City Co"
'HWD' = " Hayward Executive Airport"
'HWO' = " North Perry"
'HXD' = " Hilton Head Airport"
'HYA' = " Barnstable Muni Boardman Polando Fld"
'HYG' = " Hydaburg Seaplane Base"
'HYL' = " Hollis Seaplane Base"
'HYS' = " Hays Regional Airport"
'HZL' = " Hazleton Municipal"
'IAB' = " Mc Connell Afb"
'IAD' = " Washington Dulles Intl"
'IAG' = " Niagara Falls Intl"
'IAH' = " George Bush Intercontinental"
'IAN' = " Bob Baker Memorial Airport"
'ICT' = " Wichita Mid Continent"
'ICY' = " Icy Bay Airport"
'IDA' = " Idaho Falls Rgnl"
'IDL' = " Idlewild Intl"
'IFP' = " Laughlin-Bullhead Intl"
'IGG' = " Igiugig Airport"
'IGM' = " Kingman Airport"
'IGQ' = " Lansing Municipal"
'IJD' = " Windham Airport"
'IKK' = " Greater Kankakee"
'IKO' = " Nikolski Air Station"
'IKR' = " Kirtland Air Force Base"
'IKV' = " Ankeny Regl Airport"
'ILG' = " New Castle"
'ILI' = " Iliamna"
'ILM' = " Wilmington Intl"
'ILN' = " Wilmington Airborne Airpark"
'IMM' = " Immokalee"
'IMT' = " Ford Airport"
'IND' = " Indianapolis Intl"
'INJ' = " Hillsboro Muni"
'INK' = " Winkler Co"
'INL' = " Falls Intl"
'INS' = " Creech Afb"
'INT' = " Smith Reynolds"
'INW' = " Winslow-Lindbergh Regional Airport"
'IOW' = " Iowa City Municipal Airport"
'IPL' = " Imperial Co"
'IPT' = " Williamsport Rgnl"
'IRC' = " Circle City Airport"
'IRK' = " Kirksville Regional Airport"
'ISM' = " Kissimmee Gateway Airport"
'ISN' = " Sloulin Fld Intl"
'ISO' = " Kinston Regional Jetport"
'ISP' = " Long Island Mac Arthur"
'ISW' = " Alexander Field South Wood County Airport"
'ITH' = " Ithaca Tompkins Rgnl"
'ITO' = " Hilo Intl"
'IWD' = " Gogebic Iron County Airport"
'IWS' = " West Houston"
'IYK' = " Inyokern Airport"
'JAC' = " Jackson Hole Airport"
'JAN' = " Jackson Evers Intl"
'JAX' = " Jacksonville Intl"
'JBR' = " Jonesboro Muni"
'JCI' = " New Century AirCenter Airport"
'JEF' = " Jefferson City Memorial Airport"
'JES' = " Jesup-Wayne County Airport"
'JFK' = " John F Kennedy Intl"
'JGC' = " Grand Canyon Heliport"
'JHM' = " Kapalua"
'JHW' = " Chautauqua County-Jamestown"
'JKA' = " Jack Edwards Airport"
'JLN' = " Joplin Rgnl"
'JMS' = " Jamestown Regional Airport"
'JNU' = " Juneau Intl"
'JOT' = " Regional Airport"
'JRA' = " West 30th St. Heliport"
'JRB' = " Wall Street Heliport"
'JST' = " John Murtha Johnstown-Cambria County Airport"
'JVL' = " Southern Wisconsin Regional Airport"
'JXN' = " Reynolds Field"
'JYL' = " Plantation Airpark"
'JYO' = " Leesburg Executive Airport"
'JZP' = " Pickens County Airport"
'K03' = " Wainwright As"
'KAE' = " Kake Seaplane Base"
'KAL' = " Kaltag Airport"
'KBC' = " Birch Creek Airport"
'KBW' = " Chignik Bay Seaplane Base"
'KCC' = " Coffman Cove Seaplane Base"
'KCL' = " Chignik Lagoon Airport"
'KCQ' = " Chignik Lake Airport"
'KEH' = " Kenmore Air Harbor Inc Seaplane Base"
'KEK' = " Ekwok Airport"
'KFP' = " False Pass Airport"
'KGK' = " Koliganek Airport"
'KGX' = " Grayling Airport"
'KKA' = " Koyuk Alfred Adams Airport"
'KKB' = " Kitoi Bay Seaplane Base"
'KKH' = " Kongiganak Airport"
'KLG' = " Kalskag Airport"
'KLL' = " Levelock Airport"
'KLN' = " Larsen Bay Airport"
'KLS' = " Kelso Longview"
'KLW' = " Klawock Airport"
'KMO' = " Manokotak Airport"
'KMY' = " Moser Bay Seaplane Base"
'KNW' = " New Stuyahok Airport"
'KOA' = " Kona Intl At Keahole"
'KOT' = " Kotlik Airport"
'KOY' = " Olga Bay Seaplane Base"
'KOZ' = " Ouzinkie Airport"
'KPB' = " Point Baker Seaplane Base"
'KPC' = " Port Clarence Coast Guard Station"
'KPN' = " Kipnuk Airport"
'KPR' = " Port Williams Seaplane Base"
'KPV' = " Perryville Airport"
'KPY' = " Port Bailey Seaplane Base"
'KQA' = " Akutan Seaplane Base"
'KSM' = " St Marys Airport"
'KTB' = " Thorne Bay Seaplane Base"
'KTN' = " Ketchikan Intl"
'KTS' = " Brevig Mission Airport"
'KUK' = " Kasigluk Airport"
'KVC' = " King Cove Airport"
'KVL' = " Kivalina Airport"
'KWK' = " Kwigillingok Airport"
'KWN' = " Quinhagak Airport"
'KWP' = " West Point Village Seaplane Base"
'KWT' = " Kwethluk Airport"
'KYK' = " Karuluk Airport"
'KYU' = " Koyukuk Airport"
'KZB' = " Zachar Bay Seaplane Base"
'L06' = " Furnace Creek"
'L35' = " Big Bear City"
'LAA' = " Lamar Muni"
'LAF' = " Purude University Airport"
'LAL' = " Lakeland Linder Regional Airport"
'LAM' = " Los Alamos Airport"
'LAN' = " Capital City"
'LAR' = " Laramie Regional Airport"
'LAS' = " Mc Carran Intl"
'LAW' = " Lawton-Fort Sill Regional Airport"
'LAX' = " Los Angeles Intl"
'LBB' = " Lubbock Preston Smith Intl"
'LBE' = " Arnold Palmer Regional Airport"
'LBF' = " North Platte Regional Airport Lee Bird Field"
'LBL' = " Liberal Muni"
'LBT' = " Municipal Airport"
'LCH' = " Lake Charles Rgnl"
'LCK' = " Rickenbacker Intl"
'LCQ' = " Lake City Municipal Airport"
'LDJ' = " Linden Airport"
'LEB' = " Lebanon Municipal Airport"
'LEW' = " Lewiston Maine"
'LEX' = " Blue Grass"
'LFI' = " Langley Afb"
'LFK' = " Angelina Co"
'LFT' = " Lafayette Rgnl"
'LGA' = " La Guardia"
'LGB' = " Long Beach"
'LGC' = " LaGrange-Callaway Airport"
'LGU' = " Logan-Cache"
'LHD' = " Lake Hood Seaplane Base"
'LHV' = " William T. Piper Mem."
'LHX' = " La Junta Muni"
'LIH' = " Lihue"
'LIT' = " Adams Fld"
'LIV' = " Livingood Airport"
'LKE' = " Kenmore Air Harbor Seaplane Base"
'LKP' = " Lake Placid Airport"
'LMT' = " Klamath Falls Airport"
'LNA' = " Palm Beach Co Park"
'LNK' = " Lincoln"
'LNN' = " Lost Nation Municipal Airport"
'LNR' = " Tri-County Regional Airport"
'LNS' = " Lancaster Airport"
'LNY' = " Lanai"
'LOT' = " Lewis University Airport"
'LOU' = " Bowman Fld"
'LOZ' = " London-Corbin Airport-MaGee Field"
'LPC' = " Lompoc Airport"
'LPR' = " Lorain County Regional Airport"
'LPS' = " Lopez Island Airport"
'LRD' = " Laredo Intl"
'LRF' = " Little Rock Afb"
'LRU' = " Las Cruces Intl"
'LSE' = " La Crosse Municipal"
'LSF' = " Lawson Aaf"
'LSV' = " Nellis Afb"
'LTS' = " Altus Afb"
'LUF' = " Luke Afb"
'LUK' = " Cincinnati Muni Lunken Fld"
'LUP' = " Kalaupapa Airport"
'LUR' = " Cape Lisburne Lrrs"
'LVK' = " Livermore Municipal"
'LVM' = " Mission Field Airport"
'LVS' = " Las Vegas Muni"
'LWA' = " South Haven Area Regional Airport"
'LWB' = " Greenbrier Valley Airport"
'LWC' = " Lawrence Municipal"
'LWM' = " Lawrence Municipal Airport"
'LWS' = " Lewiston Nez Perce Co"
'LWT' = " Lewistown Municipal Airport"
'LXY' = " Mexia - Limestone County Airport"
'LYH' = " Lynchburg Regional Preston Glenn Field"
'LYU' = " Ely Municipal"
'LZU' = " Gwinnett County Airport-Briscoe Field"
'MAE' = " Madera Municipal Airport"
'MAF' = " Midland Intl"
'MBL' = " Manistee County-Blacker Airport"
'MBS' = " Mbs Intl"
'MCC' = " Mc Clellan Afld"
'MCD' = " Mackinac Island Airport"
'MCE' = " Merced Municipal Airport"
'MCF' = " Macdill Afb"
'MCG' = " McGrath Airport"
'MCI' = " Kansas City Intl"
'MCK' = " McCook Regional Airport"
'MCL' = " McKinley National Park Airport"
'MCN' = " Middle Georgia Rgnl"
'MCO' = " Orlando Intl"
'MCW' = " Mason City Municipal"
'MDT' = " Harrisburg Intl"
'MDW' = " Chicago Midway Intl"
'ME5' = " Banks Airport"
'MEI' = " Key Field"
'MEM' = " Memphis Intl"
'MER' = " Castle"
'MFD' = " Mansfield Lahm Regional"
'MFE' = " Mc Allen Miller Intl"
'MFI' = " Marshfield Municipal Airport"
'MFR' = " Rogue Valley Intl Medford"
'MGC' = " Michigan City Municipal Airport"
'MGE' = " Dobbins Arb"
'MGJ' = " Orange County Airport"
'MGM' = " Montgomery Regional Airport"
'MGR' = " Moultrie Municipal Airport"
'MGW' = " Morgantown Muni Walter L Bill Hart Fld"
'MGY' = " Dayton-Wright Brothers Airport"
'MHK' = " Manhattan Reigonal"
'MHM' = " Minchumina Airport"
'MHR' = " Sacramento Mather"
'MHT' = " Manchester Regional Airport"
'MHV' = " Mojave"
'MIA' = " Miami Intl"
'MIB' = " Minot Afb"
'MIE' = " Delaware County Airport"
'MIV' = " Millville Muni"
'MKC' = " Downtown"
'MKE' = " General Mitchell Intl"
'MKG' = " Muskegon County Airport"
'MKK' = " Molokai"
'MKL' = " Mc Kellar Sipes Rgnl"
'MKO' = " Davis Fld"
'MLB' = " Melbourne Intl"
'MLC' = " Mc Alester Rgnl"
'MLD' = " Malad City"
'MLI' = " Quad City Intl"
'MLJ' = " Baldwin County Airport"
'MLL' = " Marshall Don Hunter Sr. Airport"
'MLS' = " Frank Wiley Field"
'MLT' = " Millinocket Muni"
'MLU' = " Monroe Rgnl"
'MLY' = " Manley Hot Springs Airport"
'MMH' = " Mammoth Yosemite Airport"
'MMI' = " McMinn Co"
'MMU' = " Morristown Municipal Airport"
'MMV' = " Mc Minnville Muni"
'MNM' = " Menominee Marinette Twin Co"
'MNT' = " Minto Airport"
'MOB' = " Mobile Rgnl"
'MOD' = " Modesto City Co Harry Sham"
'MOT' = " Minot Intl"
'MOU' = " Mountain Village Airport"
'MPB' = " Miami Seaplane Base"
'MPI' = " MariposaYosemite"
'MPV' = " Edward F Knapp State"
'MQB' = " Macomb Municipal Airport"
'MQT' = " Sawyer International Airport"
'MRB' = " Eastern WV Regional Airport"
'MRI' = " Merrill Fld"
'MRK' = " Marco Islands"
'MRN' = " Foothills Regional Airport"
'MRY' = " Monterey Peninsula"
'MSL' = " Northwest Alabama Regional Airport"
'MSN' = " Dane Co Rgnl Truax Fld"
'MSO' = " Missoula Intl"
'MSP' = " Minneapolis St Paul Intl"
'MSS' = " Massena Intl Richards Fld"
'MSY' = " Louis Armstrong New Orleans Intl"
'MTC' = " Selfridge Angb"
'MTH' = " Florida Keys Marathon Airport"
'MTJ' = " Montrose Regional Airport"
'MTM' = " Metlakatla Seaplane Base"
'MUE' = " Waimea Kohala"
'MUI' = " Muir Aaf"
'MUO' = " Mountain Home Afb"
'MVL' = " Morrisville Stowe State Airport"
'MVY' = " Martha\\'s Vineyard"
'MWA' = " Williamson Country Regional Airport"
'MWC' = " Lawrence J Timmerman Airport"
'MWH' = " Grant Co Intl"
'MWL' = " Mineral Wells"
'MWM' = " Windom Municipal Airport"
'MXF' = " Maxwell Afb"
'MXY' = " McCarthy Airport"
'MYF' = " Montgomery Field"
'MYL' = " McCall Municipal Airport"
'MYR' = " Myrtle Beach Intl"
'MYU' = " Mekoryuk Airport"
'MYV' = " Yuba County Airport"
'MZJ' = " Pinal Airpark"
'N53' = " Stroudsburg-Pocono Airport"
'N69' = " Stormville Airport"
'N87' = " Trenton-Robbinsville Airport"
'NBG' = " New Orleans Nas Jrb"
'NBU' = " Naval Air Station"
'NCN' = " Chenega Bay Airport"
'NEL' = " Lakehurst Naes"
'NFL' = " Fallon Nas"
'NGF' = " Kaneohe Bay Mcaf"
'NGP' = " Corpus Christi NAS"
'NGU' = " Norfolk Ns"
'NGZ' = " NAS Alameda"
'NHK' = " Patuxent River Nas"
'NIB' = " Nikolai Airport"
'NID' = " China Lake Naws"
'NIP' = " Jacksonville Nas"
'NJK' = " El Centro Naf"
'NKT' = " Cherry Point Mcas"
'NKX' = " Miramar Mcas"
'NLC' = " Lemoore Nas"
'NLG' = " Nelson Lagoon"
'NME' = " Nightmute Airport"
'NMM' = " Meridian Nas"
'NNL' = " Nondalton Airport"
'NOW' = " Port Angeles Cgas"
'NPA' = " Pensacola Nas"
'NPZ' = " Porter County Municipal Airport"
'NQA' = " Millington Rgnl Jetport"
'NQI' = " Kingsville Nas"
'NQX' = " Key West Nas"
'NSE' = " Whiting Fld Nas North"
'NTD' = " Point Mugu Nas"
'NTU' = " Oceana Nas"
'NUI' = " Nuiqsut Airport"
'NUL' = " Nulato Airport"
'NUP' = " Nunapitchuk Airport"
'NUQ' = " Moffett Federal Afld"
'NUW' = " Whidbey Island Nas"
'NXP' = " Twentynine Palms Eaf"
'NXX' = " Willow Grove Nas Jrb"
'NY9' = " Long Lake"
'NYC' = " All Airports"
'NYG' = " Quantico Mcaf"
'NZC' = " Cecil Field"
'NZJ' = " El Toro"
'NZY' = " North Island Nas"
'O03' = " Morgantown Airport"
'O27' = " Oakdale Airport"
'OAJ' = " Albert J Ellis"
'OAK' = " Metropolitan Oakland Intl"
'OAR' = " Marina Muni"
'OBE' = " County"
'OBU' = " Kobuk Airport"
'OCA' = " Key Largo"
'OCF' = " International Airport"
'OEB' = " Branch County Memorial Airport"
'OFF' = " Offutt Afb"
'OGG' = " Kahului"
'OGS' = " Ogdensburg Intl"
'OKC' = " Will Rogers World"
'OLF' = " LM Clayton Airport"
'OLH' = " Old Harbor Airport"
'OLM' = " Olympia Regional Airpor"
'OLS' = " Nogales Intl"
'OLV' = " Olive Branch Muni"
'OMA' = " Eppley Afld"
'OME' = " Nome"
'OMN' = " Ormond Beach municipal Airport"
'ONH' = " Oneonta Municipal Airport"
'ONP' = " Newport Municipal Airport"
'ONT' = " Ontario Intl"
'OOK' = " Toksook Bay Airport"
'OPF' = " Opa Locka"
'OQU' = " Quonset State Airport"
'ORD' = " Chicago Ohare Intl"
'ORF' = " Norfolk Intl"
'ORH' = " Worcester Regional Airport"
'ORI' = " Port Lions Airport"
'ORL' = " Executive"
'ORT' = " Northway"
'ORV' = " Robert Curtis Memorial Airport"
'OSC' = " Oscoda Wurtsmith"
'OSH' = " Wittman Regional Airport"
'OSU' = " Ohio State University Airport"
'OTH' = " Southwest Oregon Regional Airport"
'OTS' = " Anacortes Airport"
'OTZ' = " Ralph Wien Mem"
'OWB' = " Owensboro Daviess County Airport"
'OWD' = " Norwood Memorial Airport"
'OXC' = " Waterbury-Oxford Airport"
'OXD' = " Miami University Airport"
'OXR' = " Oxnard - Ventura County"
'OZA' = " Ozona Muni"
'P08' = " Coolidge Municipal Airport"
'P52' = " Cottonwood Airport"
'PAE' = " Snohomish Co"
'PAH' = " Barkley Regional Airport"
'PAM' = " Tyndall Afb"
'PAO' = " Palo Alto Airport of Santa Clara County"
'PAQ' = " Palmer Muni"
'PBF' = " Grider Fld"
'PBG' = " Plattsburgh Intl"
'PBI' = " Palm Beach Intl"
'PBV' = " St George"
'PBX' = " Pike County Airport - Hatcher Field"
'PCW' = " Erie-Ottawa Regional Airport"
'PCZ' = " Waupaca Municipal Airport"
'PDB' = " Pedro Bay Airport"
'PDK' = " Dekalb-Peachtree Airport"
'PDT' = " Eastern Oregon Regional Airport"
'PDX' = " Portland Intl"
'PEC' = " Pelican Seaplane Base"
'PEQ' = " Pecos Municipal Airport"
'PFN' = " Panama City Bay Co Intl"
'PGA' = " Page Municipal Airport"
'PGD' = " Charlotte County-Punta Gorda Airport"
'PGV' = " Pitt-Greenville Airport"
'PHD' = " Harry Clever Field Airport"
'PHF' = " Newport News Williamsburg Intl"
'PHK' = " Pahokee Airport"
'PHL' = " Philadelphia Intl"
'PHN' = " St Clair Co Intl"
'PHO' = " Point Hope Airport"
'PHX' = " Phoenix Sky Harbor Intl"
'PIA' = " Peoria Regional"
'PIB' = " Hattiesburg Laurel Regional Airport"
'PIE' = " St Petersburg Clearwater Intl"
'PIH' = " Pocatello Regional Airport"
'PIM' = " Harris County Airport"
'PIP' = " Pilot Point Airport"
'PIR' = " Pierre Regional Airport"
'PIT' = " Pittsburgh Intl"
'PIZ' = " Point Lay Lrrs"
'PKB' = " Mid-Ohio Valley Regional Airport"
'PLN' = " Pellston Regional Airport of Emmet County Airport"
'PMB' = " Pembina Muni"
'PMD' = " Palmdale Rgnl Usaf Plt 42"
'PML' = " Port Moller Airport"
'PMP' = " Pompano Beach Airpark"
'PNC' = " Ponca City Rgnl"
'PNE' = " Northeast Philadelphia"
'PNM' = " Princeton Muni"
'PNS' = " Pensacola Rgnl"
'POB' = " Pope Field"
'POC' = " Brackett Field"
'POE' = " Polk Aaf"
'POF' = " Poplar Bluff Municipal Airport"
'PPC' = " Prospect Creek Airport"
'PPV' = " Port Protection Seaplane Base"
'PQI' = " Northern Maine Rgnl At Presque Isle"
'PQS' = " Pilot Station Airport"
'PRC' = " Ernest A Love Fld"
'PSC' = " Tri Cities Airport"
'PSG' = " Petersburg James A. Johnson"
'PSM' = " Pease International Tradeport"
'PSP' = " Palm Springs Intl"
'PSX' = " Palacios Muni"
'PTB' = " Dinwiddie County Airport"
'PTH' = " Port Heiden Airport"
'PTK' = " Oakland Co. Intl"
'PTU' = " Platinum"
'PUB' = " Pueblo Memorial"
'PUC' = " Carbon County Regional-Buck Davis Field"
'PUW' = " Pullman-Moscow Rgnl"
'PVC' = " Provincetown Muni"
'PVD' = " Theodore Francis Green State"
'PVU' = " Provo Municipal Airport"
'PWK' = " Chicago Executive"
'PWM' = " Portland Intl Jetport"
'PWT' = " Bremerton National"
'PYM' = " Plymouth Municipal Airport"
'PYP' = " Centre-Piedmont-Cherokee County Regional Airport"
'R49' = " Ferry County Airport"
'RAC' = " John H. Batten Airport"
'RAL' = " Riverside Muni"
'RAP' = " Rapid City Regional Airport"
'RBD' = " Dallas Executive Airport"
'RBK' = " French Valley Airport"
'RBM' = " Robinson Aaf"
'RBN' = " Fort Jefferson"
'RBY' = " Ruby Airport"
'RCA' = " Ellsworth Afb"
'RCE' = " Roche Harbor Seaplane Base"
'RCZ' = " Richmond County Airport"
'RDD' = " Redding Muni"
'RDG' = " Reading Regional Carl A Spaatz Field"
'RDM' = " Roberts Fld"
'RDR' = " Grand Forks Afb"
'RDU' = " Raleigh Durham Intl"
'RDV' = " Red Devil Airport"
'REI' = " Redlands Municipal Airport"
'RFD' = " Chicago Rockford International Airport"
'RHI' = " Rhinelander Oneida County Airport"
'RIC' = " Richmond Intl"
'RID' = " Richmond Municipal Airport"
'RIF' = " Richfield Minicipal Airport"
'RIL' = " Garfield County Regional Airport"
'RIR' = " Flabob Airport"
'RIU' = " Rancho Murieta"
'RIV' = " March Arb"
'RIW' = " Riverton Regional"
'RKD' = " Knox County Regional Airport"
'RKH' = " Rock Hill York Co Bryant Airport"
'RKP' = " Aransas County Airport"
'RKS' = " Rock Springs Sweetwater County Airport"
'RME' = " Griffiss Afld"
'RMG' = " Richard B Russell Airport"
'RMP' = " Rampart Airport"
'RMY' = " Brooks Field Airport"
'RND' = " Randolph Afb"
'RNM' = " Ramona Airport"
'RNO' = " Reno Tahoe Intl"
'RNT' = " Renton"
'ROA' = " Roanoke Regional"
'ROC' = " Greater Rochester Intl"
'ROW' = " Roswell Intl Air Center"
'RSH' = " Russian Mission Airport"
'RSJ' = " Rosario Seaplane Base"
'RST' = " Rochester"
'RSW' = " Southwest Florida Intl"
'RUT' = " Rutland State Airport"
'RVS' = " Richard Lloyd Jones Jr Airport"
'RWI' = " Rocky Mount Wilson Regional Airport"
'RWL' = " Rawlins Municipal Airport-Harvey Field"
'RYY' = " Cobb County Airport-Mc Collum Field"
'S46' = " Port O\\'Connor Airfield"
'SAA' = " Shively Field Airport"
'SAC' = " Sacramento Executive"
'SAD' = " Safford Regional Airport"
'SAF' = " Santa Fe Muni"
'SAN' = " San Diego Intl"
'SAT' = " San Antonio Intl"
'SAV' = " Savannah Hilton Head Intl"
'SBA' = " Santa Barbara Muni"
'SBD' = " San Bernardino International Airport"
'SBM' = " Sheboygan County Memorial Airport"
'SBN' = " South Bend Rgnl"
'SBO' = " Emanuel Co"
'SBP' = " San Luis County Regional Airport"
'SBS' = " Steamboat Springs Airport-Bob Adams Field"
'SBY' = " Salisbury Ocean City Wicomico Rgnl"
'SCC' = " Deadhorse"
'SCE' = " University Park Airport"
'SCH' = " Stratton ANGB - Schenectady County Airpor"
'SCK' = " Stockton Metropolitan"
'SCM' = " Scammon Bay Airport"
'SDC' = " Williamson-Sodus Airport"
'SDF' = " Louisville International Airport"
'SDM' = " Brown Field Municipal Airport"
'SDP' = " Sand Point Airport"
'SDX' = " Sedona"
'SDY' = " Sidney-Richland Municipal Airport"
'SEA' = " Seattle Tacoma Intl"
'SEE' = " Gillespie"
'SEF' = " Regional - Hendricks AAF"
'SEM' = " Craig Fld"
'SES' = " Selfield Airport"
'SFB' = " Orlando Sanford Intl"
'SFF' = " Felts Fld"
'SFM' = " Sanford Regional"
'SFO' = " San Francisco Intl"
'SFZ' = " North Central State"
'SGF' = " Springfield Branson Natl"
'SGH' = " Springfield-Beckly Municipal Airport"
'SGJ' = " St. Augustine Airport"
'SGR' = " Sugar Land Regional Airport"
'SGU' = " St George Muni"
'SGY' = " Skagway Airport"
'SHD' = " Shenandoah Valley Regional Airport"
'SHG' = " Shungnak Airport"
'SHH' = " Shishmaref Airport"
'SHR' = " Sheridan County Airport"
'SHV' = " Shreveport Rgnl"
'SHX' = " Shageluk Airport"
'SIK' = " Sikeston Memorial Municipal"
'SIT' = " Sitka Rocky Gutierrez"
'SJC' = " Norman Y Mineta San Jose Intl"
'SJT' = " San Angelo Rgnl Mathis Fld"
'SKA' = " Fairchild Afb"
'SKF' = " Lackland Afb Kelly Fld Annex"
'SKK' = " Shaktoolik Airport"
'SKY' = " Griffing Sandusky"
'SLC' = " Salt Lake City Intl"
'SLE' = " McNary Field"
'SLK' = " Adirondack Regional Airport"
'SLN' = " Salina Municipal Airport"
'SLQ' = " Sleetmute Airport"
'SMD' = " Smith Fld"
'SME' = " Lake Cumberland Regional Airport"
'SMF' = " Sacramento Intl"
'SMK' = " St. Michael Airport"
'SMN' = " Lemhi County Airport"
'SMO' = " Santa Monica Municipal Airport"
'SMX' = " Santa Maria Pub Cpt G Allan Hancock Airport"
'SNA' = " John Wayne Arpt Orange Co"
'SNP' = " St Paul Island"
'SNY' = " Sidney Muni Airport"
'SOP' = " Moore County Airport"
'SOW' = " Show Low Regional Airport"
'SPB' = " Scappoose Industrial Airpark"
'SPF' = " Black Hills Airport-Clyde Ice Field"
'SPG' = " Albert Whitted"
'SPI' = " Abraham Lincoln Capital"
'SPS' = " Sheppard Afb Wichita Falls Muni"
'SPW' = " Spencer Muni"
'SPZ' = " Silver Springs Airport"
'SQL' = " San Carlos Airport"
'SRQ' = " Sarasota Bradenton Intl"
'SRR' = " Sierra Blanca Regional Airport"
'SRV' = " Stony River 2 Airport"
'SSC' = " Shaw Afb"
'SSI' = " McKinnon Airport"
'STC' = " Saint Cloud Regional Airport"
'STE' = " Stevens Point Municipal Airport"
'STG' = " St. George Airport"
'STJ' = " Rosecrans Mem"
'STK' = " Sterling Municipal Airport"
'STL' = " Lambert St Louis Intl"
'STS' = " Charles M Schulz Sonoma Co"
'SUA' = " Witham Field Airport"
'SUE' = " Door County Cherryland Airport"
'SUN' = " Friedman Mem"
'SUS' = " Spirit Of St Louis"
'SUU' = " Travis Afb"
'SUX' = " Sioux Gateway Col Bud Day Fld"
'SVA' = " Savoonga Airport"
'SVC' = " Grant County Airport"
'SVH' = " Regional Airport"
'SVN' = " Hunter Aaf"
'SVW' = " Sparrevohn Lrrs"
'SWD' = " Seward Airport"
'SWF' = " Stewart Intl"
'SXP' = " Sheldon Point Airport"
'SXQ' = " Soldotna Airport"
'SYA' = " Eareckson As"
'SYB' = " Seal Bay Seaplane Base"
'SYR' = " Syracuse Hancock Intl"
'SZL' = " Whiteman Afb"
'TAL' = " Tanana Airport"
'TAN' = " Taunton Municipal Airport - King Field"
'TBN' = " Waynesville Rgnl Arpt At Forney Fld"
'TCC' = " Tucumcari Muni"
'TCL' = " Tuscaloosa Rgnl"
'TCM' = " Mc Chord Afb"
'TCS' = " Truth Or Consequences Muni"
'TCT' = " Takotna Airport"
'TEB' = " Teterboro"
'TEK' = " Tatitlek Airport"
'TEX' = " Telluride"
'TIK' = " Tinker Afb"
'TIW' = " Tacoma Narrows Airport"
'TKA' = " Talkeetna"
'TKE' = " Tenakee Seaplane Base"
'TKF' = " Truckee-Tahoe Airport"
'TKI' = " Collin County Regional Airport at Mc Kinney"
'TLA' = " Teller Airport"
'TLH' = " Tallahassee Rgnl"
'TLJ' = " Tatalina Lrrs"
'TLT' = " Tuluksak Airport"
'TMA' = " Henry Tift Myers Airport"
'TMB' = " Kendall Tamiami Executive"
'TNC' = " Tin City LRRS Airport"
'TNK' = " Tununak Airport"
'TNT' = " Dade Collier Training And Transition"
'TNX' = " Tonopah Test Range"
'TOA' = " Zamperini Field Airport"
'TOC' = " Toccoa RG Letourneau Field Airport"
'TOG' = " Togiak Airport"
'TOL' = " Toledo"
'TOP' = " Philip Billard Muni"
'TPA' = " Tampa Intl"
'TPL' = " Draughon Miller Central Texas Rgnl"
'TRI' = " Tri-Cities Regional Airport"
'TRM' = " Jacqueline Cochran Regional Airport"
'TSS' = " East 34th Street Heliport"
'TTD' = " Portland Troutdale"
'TTN' = " Trenton Mercer"
'TUL' = " Tulsa Intl"
'TUP' = " Tupelo Regional Airport"
'TUS' = " Tucson Intl"
'TVC' = " Cherry Capital Airport"
'TVF' = " Thief River Falls"
'TVI' = " Thomasville Regional Airport"
'TVL' = " Lake Tahoe Airport"
'TWA' = " Twin Hills Airport"
'TWD' = " Jefferson County Intl"
'TWF' = " Magic Valley Regional Airport"
'TXK' = " Texarkana Rgnl Webb Fld"
'TYE' = " Tyonek Airport"
'TYR' = " Tyler Pounds Rgnl"
'TYS' = " Mc Ghee Tyson"
'U76' = " Mountain Home Municipal Airport"
'UDD' = " Bermuda Dunes Airport"
'UDG' = " Darlington County Jetport"
'UES' = " Waukesha County Airport"
'UGN' = " Waukegan Rgnl"
'UIN' = " Quincy Regional Baldwin Field"
'UMP' = " Indianapolis Metropolitan Airport"
'UNK' = " Unalakleet Airport"
'UPP' = " Upolu"
'UST' = " St. Augustine Airport"
'UTM' = " Tunica Municipal Airport"
'UTO' = " Indian Mountain Lrrs"
'UUK' = " Ugnu-Kuparuk Airport"
'UUU' = " Newport State"
'UVA' = " Garner Field"
'VAD' = " Moody Afb"
'VAK' = " Chevak Airport"
'VAY' = " South Jersey Regional Airport"
'VBG' = " Vandenberg Afb"
'VCT' = " Victoria Regional Airport"
'VCV' = " Southern California Logistics"
'VDF' = " Tampa Executive Airport"
'VDZ' = " Valdez Pioneer Fld"
'VEE' = " Venetie Airport"
'VEL' = " Vernal Regional Airport"
'VGT' = " North Las Vegas Airport"
'VIS' = " Visalia Municipal Airport"
'VLD' = " Valdosta Regional Airport"
'VNW' = " Van Wert County Airport"
'VNY' = " Van Nuys"
'VOK' = " Volk Fld"
'VPC' = " Cartersville Airport"
'VPS' = " Eglin Afb"
'VRB' = " Vero Beach Muni"
'VSF' = " Hartness State"
'VYS' = " Illinois Valley Regional"
'W13' = " Eagle's Nest Airport"
'WAA' = " Wales Airport"
'WAL' = " Wallops Flight Facility"
'WAS' = " All Airports"
'WBB' = " Stebbins Airport"
'WBQ' = " Beaver Airport"
'WBU' = " Boulder Municipal"
'WBW' = " Wilkes-Barre Wyoming Valley Airport"
'WDR' = " Barrow County Airport"
'WFB' = " Ketchikan harbor Seaplane Base"
'WFK' = " Northern Aroostook Regional Airport"
'WHD' = " Hyder Seaplane Base"
'WHP' = " Whiteman Airport"
'WIH' = " Wishram Amtrak Station"
'WKK' = " Aleknagik Airport"
'WKL' = " Waikoloa Heliport"
'WLK' = " Selawik Airport"
'WMO' = " White Mountain Airport"
'WRB' = " Robins Afb"
'WRG' = " Wrangell Airport"
'WRI' = " Mc Guire Afb"
'WRL' = " Worland Municipal Airport"
'WSD' = " Condron Aaf"
'WSJ' = " San Juan - Uganik Seaplane Base"
'WSN' = " South Naknek Airport"
'WST' = " Westerly State Airport"
'WSX' = " Westsound Seaplane Base"
'WTK' = " Noatak Airport"
'WTL' = " Tuntutuliak Airport"
'WWD' = " Cape May Co"
'WWP' = " North Whale Seaplane Base"
'WWT' = " Newtok Airport"
'WYS' = " Yellowstone Airport"
'X01' = " Everglades Airpark"
'X07' = " Lake Wales Municipal Airport"
'X21' = " Arthur Dunn Airpark"
'X39' = " Tampa North Aero Park"
'X49' = " South Lakeland Airport"
'XFL' = " Flagler County Airport"
'XNA' = " NW Arkansas Regional"
'XZK' = " Amherst Amtrak Station AMM"
'Y51' = " Municipal Airport"
'Y72' = " Bloyer Field"
'YAK' = " Yakutat"
'YIP' = " Willow Run"
'YKM' = " Yakima Air Terminal McAllister Field"
'YKN' = " Chan Gurney"
'YNG' = " Youngstown Warren Rgnl"
'YUM' = " Yuma Mcas Yuma Intl"
'Z84' = " Clear"
'ZBP' = " Penn Station"
'ZFV' = " Philadelphia 30th St Station"
'ZPH' = " Municipal Airport"
'ZRA' = " Atlantic City Rail Terminal"
'ZRD' = " Train Station"
'ZRP' = " Newark Penn Station"
'ZRT' = " Hartford Union Station"
'ZRZ' = " New Carrollton Rail Station"
'ZSF' = " Springfield Amtrak Station"
'ZSY' = " Scottsdale Airport"
'ZTF' = " Stamford Amtrak Station"
'ZTY' = " Boston Back Bay Station"
'ZUN' = " Black Rock"
'ZVE' = " New Haven Rail Station"
'ZWI' = " Wilmington Amtrak Station"
'ZWU' = " Washington Union Station"
'ZYP' = " Penn Station"
;
run;


data my_work.flights1;
set my_work.flights1;
	format carrier f_airlines.;
	format origin f_airports.;
	format dest f_airports.;
run;	



data my_work.flights1;
set my_work.flights1;
flight1 = compress(put(flight, 8.));
drop flight;
rename flight1 = flight;
run;


/* Exploring the data */
/* Data manipulation to extract relevant information */

/*Q5 Busiest routes
/* i.	Identify the busiest routes for the year 2013 ie which origin-dest had the maximum flights */

proc sql outobs= 1;

create table tb1 as 
select  origin, count(origin) as cnt, dest from my_work.flights1
group by origin, dest
order by cnt desc
;
quit;

/* JFK	11262	LAX */
/* ii.	Calculate the number of flights for each of the carriers for the top five routes */


proc sql outobs= 5;
create table tb2 as 
select  origin, count(origin) as cnt, dest from my_work.flights1
group by origin, dest
order by cnt desc
;
quit;

/* 1	JFK	11262	LAX	 */
/* 2	LGA	10263	ATL	 */
/* 3	LGA	8857	ORD	 */
/* 4	JFK	8204	SFO	 */
/* 5	LGA	6168	CLT */


proc SQL ;

create table tb3 as
select carrier, count(carrier) as count_flights, tb2.origin, tb2.dest
from my_work.flights1 as t3 
right join tb2 on 
(t3.origin = tb2.origin) and (t3.dest = tb2.dest)
group by carrier, tb2.origin, tb2.dest
;
quit;

/* iii.Compare the numbers calculated in (ii) with total number of flights for each carrier */

proc SQL ;

create table tb4 as
select carrier, count(carrier) as count_flights
from my_work.flights1
group by carrier
;
quit;


/*Q6 Busiest time of the day (maximum flights taking off)

i.	Identify the busiest time of the day for each carrier.*/;

proc sql;

create table test1 as
select carrier, sched_dep_time, count(sched_dep_time) as count_flights  from my_work.flights1
group by carrier, sched_dep_time
order by carrier,count_flights desc
;
quit;


proc sort data=test1 nodupkey ;
by carrier ;
run;

data test1 ;
set test1;
sched_dep_time = input(put(sched_dep_time, 8.), hhmmss.);
format sched_dep_time time.;
run;

/*ii.	Identify the busiest time of the day for three airports, John F. Kennedy International 
Airport (JFK), LaGuardia Airport (LGA) and Newark Liberty International Airport (EWR)*/


proc sql;

create table test3 as
select origin, sched_dep_time, count(sched_dep_time) as count_flights  from my_work.flights1
group by origin, sched_dep_time
order by origin,count_flights desc
;
quit;


proc sort data=test3 nodupkey ;
by origin ;
run;

data test3 ;
set test3;
sched_dep_time = input(put(sched_dep_time, 8.), hhmmss.);
format sched_dep_time time.;
run;

/*Q7 Origin and Destinations
i.	Out of all flights departing from JFK, what percentage of flights got delayed?
ii.	Which origin airport had the least number of total delays? (Since this is origin airport, 
please track delay basis departure delay)
iii.	Which destination(s) has the highest delays?
*/
/* i; */

proc sql;

select (count(CASE WHEN departure_delay > 0 and origin = "JFK" THEN departure_delay else . END)
/(select count(flight) from my_work.flights1 where origin = "JFK" ))*100 as percent_delay 
from my_work.flights1

;
quit;

/* ii; */

proc sql outobs= 1;

select origin, count(flight) as cnt 
 from my_work.flights1
where departure_delay > 0
group by origin 
order by cnt
;
quit;


/* iii */

proc sql ;

select dest, count(flight) as cnt 
 from my_work.flights1
where departure_delay > 0
group by dest 
order by cnt desc
; title "Departure delays";
quit;

proc sql ;

select dest, count(flight) as cnt 
from my_work.flights1
where arrival_delay > 0
group by dest 
order by cnt desc
; title "Arrival Delays";
quit;


/* Forming hypotheses */

/* Checking for relationships */

/* Q8 Understanding weather conditions related with delays */
/* i.	Join the weather and flights data using the variables: date, hour and origin variables */
/* ii.	Calculate averages for the weather condition parameters provided and the departure delay, grouped by months */
/* iii. What inference can you draw from (ii) to understand which parameter correlates most with the delays. */

/* i */

proc sql;

create table join as 
select t1.month, t1.departure_delay, t1.arrival_delay, t2.* from my_work.flights1 as t1
left join my_work.weather t2 on t1.date = t2.date and t1.hour = t2.hours and t1.origin = t2.origin

;
Quit;

proc contents data= join;
run;

proc sql;
create table correlation as
select month, 
avg(departure_delay ) as avg_departure_delay ,	 
avg(dewp) as avg_dewp,	 	 	 	 
avg(humid)as avg_humid,	
avg(precip) as avg_precip,	
avg(pressure) as avg_pressure,		 	 
avg(temp) as avg_temp,
avg(visib)as avg_visib,	
avg(wind_dir) as avg_wind_dir,	 
avg(wind_gust) as avg_wind_gust,	 	 
avg(wind_speed) as avg_wind_speed
from join
group by month
;
quit;

proc corr data=correlation sscp cov plots=matrix;
   var  month;
   with avg_departure_delay	avg_dewp avg_humid avg_precip	avg_pressure	avg_temp 
   avg_visib	avg_wind_dir	avg_wind_gust	avg_wind_speed ;
run;

/* Q9 Years of operation and Fuel consumption cost */
/* i.	Is there a relationship between manufacturing date of the plane and average annual fuel 
consumption cost of the plane ie do older planes use more fuel? */
/* ii.	Also understand check the relationships between fuel consumption with other plane 
variables like number of seats, engine type, number of engines, type of plane. */

proc SQL;

select manufacturing_year, avg(fuel_cc) as average_consumption
from my_work.planes
group by manufacturing_year

;
quit;

/* Latest planes use more fuel annually as compared to older counterparts. */

proc SQL;

select engine, avg(fuel_cc) as average_consumption
from my_work.planes
group by engine

;
quit;

proc SQL;

select engines, avg(fuel_cc) as average_consumption
from my_work.planes
group by engines

;
quit;

proc SQL;

select type, avg(fuel_cc) as average_consumption
from my_work.planes
group by type

;
quit;



/* Q10 Variation of delays over the course of the day */
/* On average, how do departure delays vary over the course of a day? Does it increase or decrease? 
(You might want to analyze average departure delays for each hour and check the trend) */

proc sql;

select hour, avg(departure_delay) as average_delay_in_minutes from my_work.flights1
where departure_delay>0 
group by hour
order by 2
;
quit;

/* SAS CASE STUDY-2 

Business Context: One of the leading retail chains in London having more
than 15 stores which sells Laptops and accessories.
The company would like to define the product strategy and pricing policies 
that will maximize company projected revenues in 2009

Data Availability: The data set we will be using for our session comprises
of 4 tables:
Point of Sales POS Transactions: 2008 Year Laptop Sales information
Laptops: Laptop’s configuration &amp; product information
Store Locations: Store’s geographical information
London Postcodes: Customer’s geographical
information

Case study charter and Expectations: Please note that this is an analytics
oriented case study where your analytical and business thinking is more
important than knowledge of the tool. All questions are open-ended and
centered around business thinking and different trainees might answer
the same question differently.
When we think of a business strategy, the following are some areas that
you should answer. Any additional areas will be welcome in your final
approach.
For your final approach, you need to share the final SAS codes AND also your
final outputs, which should include summarized tables and charts
included in Excel/Word/PPT format. The output should hence explain
your inferences and insights to the analysis that you have conducted.
Your output should hence be what you would want to present finally to the
client.
*/

%macro import(ds, ds1);

PROC IMPORT DATAFILE="/folders/myfolders/Classes/Case Studies/CS2/&ds."
	DBMS=CSV
	OUT= &ds1. replace;
	GETNAMES=YES;
RUN;

%mend;
 
%macro append(ds3);
proc append base= POS_Q1 data= &ds3. ;
run;
%mend;

%import (POS_Q1.csv, POS_Q1);
%import (POS_Q2.csv, POS_Q2);
%import (POS_Q3.csv, POS_Q3);
%import (POS_Q4.csv, POS_Q4);
%import (London_postal_codes.csv, London_postal_codes);
%import (Laptops.csv, Laptops);
%import (Store_Locations.csv, Store_Locations);
%append (POS_Q2);
%append (POS_Q3);
%append (POS_Q4);

/* data my_work.POS_Q1; */
/* set POS_Q1; */
/* run; */

/* proc sql; */
/*  */
/* select T1.* from POS_Q1 as T1 */
/* left join london_postal_codes as t2 on t1.  */
/*  */
/* ; */
/* quit; */

/* PRICING – What effects changes in Prices?
1. Does laptop price change with time? (Remember you define time element and can choose between
quarters/months/weekdays/etc) */

proc tabulate data= my_work.pos_q1;
title 'Laptop prices for different configurations in 2013';
class configuration month;
var retail_price;
table configuration*mean= ""*(retail_price), 
	  month;
run;


/* 2.Are prices consistent across retail outlets? Do stores with lower average pricing also sell more? */

proc tabulate data= my_work.pos_q1;
title 'Average Laptop prices across outlets';
class store_postcode month;
var retail_price;
table store_postcode*mean= ""*(retail_price= ""), 
	  month;
run;



/* 3. How does configuration effect laptop prices? */

proc tabulate data= my_work.pos_q1;
title 'Average Laptop prices per configurations';
class configuration month ;
var retail_price;
table configuration*mean= ""*(retail_price= ""),
month;
run;


/*
LOCATION – How does location influence Sales?
(For this create the distance between Customer and Store using the Euclidean
distance formula as follows:
*/

/* 1. How far do customers travel to buy their laptops? */

data my_work.store_locations (rename=(postcode=st_postcode OS_X=st_OSX OS_Y=st_OSY)) ;
set my_work.store_locations;
run;


proc sql;

create table t6 as
select * from my_work.pos_Q1 t7 
left join my_work.store_locations t8 on t7.store_postcode = t8.st_postcode
left join my_work.london_postal_codes t9 on t7.customer_postcode = t9.postcode;

quit;

/* data test; */
/* infile datalines; */
/* input st_OSX st_OSY OS_X OS_Y; */
/* datalines; */
/* 2 3 3 4 */
/* ; run; */

data distance ;
set t6 ;
distance_km = round(sqrt((OS_X - st_OSX)**2 + (OS_Y - st_OSY)**2)/1000);
run;




/* 2. Does store proximity to customers help in increasing sales of the stores? */

proc tabulate data= distance  out=proximity_data(drop= _type_ _page_ _table_) ;
class store_postcode ;
var distance_km retail_price ;
table store_postcode,distance_km='avg distance traveled by customers'*(mean=' ') retail_price='percentage of sale'*(colpctsum=' ');
title 'Average distance travel by customer for a store and contrubution of store to total sales';
footnote 'proximity to customer helps in increase in sales of store ';
run;



/* OTHER QUESTIONS */

/*1. Which stores are selling the most? Is there any relationship between sales revenue and 
sales volume?*/;


proc tabulate data= my_work.pos_q1;
class store_postcode ;
var retail_price ;
table store_postcode,retail_price*(sum n) ;

run;


/* 2. How do different configuration features effect prices of laptops?*/;

proc contents data= my_work.laptops;
run;

proc SQL;

create table t4 as 
select Screen_Size__Inches_, Battery_Life__Hours_, RAM__GB_, Processor_Speeds__GHz_, 
HD_Size__GB_, avg(retail_price) as average_price from my_work.pos_q1 as tb1
left join my_work.laptops tb2 on tb1.configuration = tb2.configuration
group by Screen_Size__Inches_, Battery_Life__Hours_, RAM__GB_, Processor_Speeds__GHz_, 
HD_Size__GB_
;
quit;





