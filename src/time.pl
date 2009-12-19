%%%%%%%%%%%%%%%%
%%    Time    %%
%%%%%%%%%%%%%%%%

%%%%% Time Units %%%%%

% Time is expressed in units of 30 minutes

time_unit(X) :-
	number(X),
	X >= 0,
	X < 48.

first_time_unit(0).

last_time_unit(47).

% Advancing time units

next_time_unit(47,0).

next_time_unit(X,Y):- 
	time_unit(X),Y is X+1, 
	time_unit(Y).

%%%%% Hour / Minute %%%%%

hour(X) :-
	number(X),
	X >= 0,
	X < 24.
	
minute(X) :-
	number(X),
	X >= 0,
	X < 60.

% Converting time units to the total amount of minutes

total_minutes(TimeUnit,Minutes) :-
	time_unit(TimeUnit),
	Minutes is TimeUnit * 30.

% Time Unit -> Hour,Minute
time_hour_minute(TimeUnit,Hour,Minute) :-
	time_unit(TimeUnit),
	total_minutes(TimeUnit,TotalMinutes),
	Minute is TotalMinutes mod 60,
	Hour is truncate( TotalMinutes / 60),!.

% Hour,Minute -> TimeUnit
time_hour_minute(TimeUnit,Hour,Minute) :-
	Minutes is Hour * 60 + Minute,
	TimeUnit is Minutes / 30,
	!.


%%%%% Date %%%%%

% Internally, days are represented as numbers.
% Externally, the corresponding names are used.

day_name(0,sunday).
day_name(1,monday).
day_name(2,tuesday).
day_name(3,wednesday).
day_name(4,thursday).
day_name(5,friday).
day_name(6,saturday).

% Weekend

weekend(saturday).
weekend(sunday).

day(Day) :-
	number(Day),
	Day > 0,
	Day < 32.

first_day(1).

next_day(32,1).

% Next Day
% Note: the given day may not exist in all months.
% Always user the Data data structure and its operations
% to perform calculations of days combined with month.

next_day(OldDay,NewDay):-
	NewDay is OldDay + 1,
	day(NewDay).
	
%%%%% Month %%%%%

% Internally, months are represented as numbers.
% Externally, months are represented by their names.

month_name(1,january).
month_name(2,february).
month_name(3,maart).
month_name(4,april).
month_name(5,may).
month_name(6,june).
month_name(7,july).
month_name(8,august).
month_name(9,september).
month_name(10,october).
month_name(11,november).
month_name(12,december).

month(Month) :-
	number(Month),
	Month > 0,
	Month < 13.

last_month(12).

first_month(1).

next_month(12,1).

next_month(OldMonth,NewMonth):-
	NewMonth is OldMonth + 1,
	month(NewMonth).

% The last days of each month
% This also depends on the year (leap-years).

end_of_month(29,2,Year):-
	leap_year(Year),
	!.
end_of_month(28,2,Year):-
	not(leap_year(Year)),
	!.

end_of_month(30,Month,_):-
	Month \= 2,
	divisible(Month,2).

end_of_month(31,Month,_):-
	Month \= 2,
	not(divisible(Month,2)).

%%%%% Year %%%%%

% The program is not backwards compatible with BC years.

year(Year) :-
	number(Year),
	Year > 0.
	
next_year(OldYear,NewYear):-
	NewYear is OldYear + 1.

divisible(X,Y):-
	Z is X rem Y,
	Z = 0.

end_of_year(31,12).

leap_year(Year) :-
	divisible(Year,4),
	not(divisible(Year,100)).

leap_year(Year) :-
	divisible(Year,400).

%%%%% Date %%%%%

% Dates exist out of a day, month and year.
% All these elements are represented by numbers.

date_day([Day,_,_],Day).
date_month([_,Month,_],Month).
date_year([_,_,Year],Year).

date([Day,Month,Year]):-
	day(Day),
	month(Month),
	year(Year).

% Date calculations

next_date([OldDay,OldMonth,OldYear],[NewDay,NewMonth,NewYear]):-
	end_of_year(OldDay,OldMonth),
	first_day(NewDay),
	first_month(NewMonth),
	next_year(OldYear,NewYear), 
	!.
	
next_date([OldDay,OldMonth,Year],[NewDay,NewMonth,Year]):-
	end_of_month(OldDay,OldMonth,Year),
	first_day(NewDay),
	next_month(OldMonth,NewMonth),
	!.
	
next_date([Day,Month,Year],[NewDay,Month,Year]):-
	next_day(Day,NewDay).

%%%%% Doomsday %%%%%

% The Doomsday rule is used for the mapping Date -> Dayname
% See http://rudy.ca/doomsday.html for an explanation of its working

% There have been irregularities in calendars so that the rule does not
% always yield correct results for past dates.
% It should work correctly for dates since 1th january 2000.

% doomsday(month,year,doomsday)
doomsday(1,_,31).
doomsday(3,_,7).
doomsday(4,_,4).
doomsday(5,_,9).
doomsday(6,_,6).
doomsday(7,_,11).
doomsday(8,_,8).
doomsday(9,_,5).
doomsday(10,_,10).
doomsday(11,_,7).
doomsday(12,_,12).

doomsday(2,2000,2).

doomsday(2,Year,DoomsDay):-
	doomsday(2,2000,D2000),
	Y is Year-2000,
	LeapYears is truncate(Y/4),
	DayCount is D2000+Y+LeapYears,
	DoomsDay is DayCount mod 7,
	!.

daycount(Day,MonthDoomsDay,YearDoomsDay,Count):-
	Count is Day - MonthDoomsDay + YearDoomsDay,
	Count > 0,
	!.

daycount(Day,MonthDoomsDay,YearDoomsDay,Count):-
	member(Weeks,[0,1,2,3,4]),
	Offset is Weeks * 7,
	Count is Day - MonthDoomsDay + YearDoomsDay + Offset.

weekday([Day,Month,Year],WeekDay):-
	doomsday(Month,Year,MonthDoomsDay),
	doomsday(2,Year,YearDoomsDay),
	daycount(Day,MonthDoomsDay,YearDoomsDay,DayCount),
	WeekDayNumber is DayCount mod 7,
	day_name(WeekDayNumber,WeekDay).

%%%%% Moment %%%%%

% A moment is a unique moment in time.
% It consists out of a date and a timeunit.
% Two moments are always at least 30 minutes separated
% from each other.

% Note that a moment has no duration.

moment_date([Date,_],Date).
	moment_time_unit([_,TimeUnit],TimeUnit).

moment([Date,TimeUnit]) :-
	date(Date),
	time_unit(TimeUnit).

next_moment([OldDate,OldTimeUnit],[NewDate,NewTimeUnit]):-
	date(OldDate),
	time_unit(OldTimeUnit),
	last_time_unit(OldTimeUnit),
	first_time_unit(NewTimeUnit),
	next_date(OldDate,NewDate),
	date(NewDate),
	time_unit(NewTimeUnit),
	!.

next_moment([OldDate,OldTimeUnit],[OldDate,NewTimeUnit]):-
	date(OldDate),
	time_unit(OldTimeUnit),
	next_time_unit(OldTimeUnit,NewTimeUnit),
	time_unit(NewTimeUnit).

earlier(FirstMoment,SecondMoment):- 
	moment_date(FirstMoment,FirstDate),
	moment_date(SecondMoment,SecondDate),
	% compare years
	date_year(FirstDate,FirstYear),
	date_year(SecondDate,SecondYear),
	FirstYear < SecondYear,
	!.

earlier(FirstMoment,SecondMoment):- 
	moment_date(FirstMoment,FirstDate),
	moment_date(SecondMoment,SecondDate),
	% common years
	date_year(FirstDate,Year),
	date_year(SecondDate,Year),
	% compare months
	date_month(FirstDate,FirstMonth),
	date_month(SecondDate,SecondMonth),
	FirstMonth < SecondMonth,
	!.

earlier(FirstMoment,SecondMoment):- 
	moment_date(FirstMoment,FirstDate),
	moment_date(SecondMoment,SecondDate),
	% common years
	date_year(FirstDate,Year),
	date_year(SecondDate,Year),
	% common months
	date_month(FirstDate,Month),
	date_month(SecondDate,Month),
	% compare days
	date_day(FirstDate,FirstDay),
	date_day(SecondDate,SecondDay),
	FirstDay < SecondDay,
	!.

earlier(FirstMoment,SecondMoment):- 
	% common dates
	moment_date(FirstMoment,Date),
	moment_date(SecondMoment,Date),
	% compare time units
	moment_time_unit(FirstMoment,FirstTimeUnit),
	moment_time_unit(SecondMoment,SecondTimeUnit),
	FirstTimeUnit < SecondTimeUnit,
	!.

earlier_or_equal(Moment,Moment).

earlier_or_equal(FirstMoment,SecondMoment):-
	earlier(FirstMoment,SecondMoment).

add_time_unit(Moment,0,Moment):-!.

add_time_unit(Moment,TimeUnit,NewMoment):-
	NewTimeUnit is TimeUnit - 1,
	next_moment(Moment,NextMoment),
	add_time_unit(NextMoment,NewTimeUnit,NewMoment).

%%%%% TimeSpan %%%%%

% A timespan is a interval of time.
% It consists out of a begin date and an end date.

% A timespan has a duration that is at least 30 minutes.

time_span_begin_moment([BeginMoment,_],BeginMoment).
time_span_end_moment([_,EndMoment],EndMoment).

time_span([BeginMoment,EndMoment]):-
	moment(BeginMoment),
	moment(EndMoment),
	earlier(BeginMoment,EndMoment).

% Overlapping timespans

overlap(FirstTimeSpan,SecondTimeSpan):-
	% common begin moments
	time_span_begin_moment(FirstTimeSpan,Moment),
	time_span_begin_moment(SecondTimeSpan,Moment).

overlap(FirstTimeSpan,SecondTimeSpan) :-
	time_span_begin_moment(FirstTimeSpan,FirstBeginMoment),
	time_span_begin_moment(SecondTimeSpan,SecondBeginMoment),
	time_span_end_moment(FirstTimeSpan,FirstEndMoment),
	% the first time span starts before the second one
	earlier(FirstBeginMoment,SecondBeginMoment),
	% and the second one begins before the first one ends
	earlier(SecondBeginMoment,FirstEndMoment),
	!.

overlap(FirstTimeSpan,SecondTimeSpan) :-
	time_span_begin_moment(FirstTimeSpan,FirstBeginMoment),
	time_span_begin_moment(SecondTimeSpan,SecondBeginMoment),
	time_span_end_moment(SecondTimeSpan,SecondEndMoment),
	% the second time span starts before the first one
	earlier(SecondBeginMoment,FirstBeginMoment),
	% and the first one begins before the seconde one ends
	earlier(FirstBeginMoment,SecondEndMoment),
	!.

% Timespan calculations

next_time_span(OldTimeSpan,NewTimeSpan):-
	time_span_begin_moment(OldTimeSpan,OldBeginMoment),
	time_span_begin_moment(NewTimeSpan,NewBeginMoment),
	time_span_end_moment(OldTimeSpan,OldEndMoment),
	time_span_end_moment(NewTimeSpan,NewEndMoment),
	% move begin and end moments
	next_moment(OldBeginMoment,NewBeginMoment),
	next_moment(OldEndMoment,NewEndMoment).

time_span_begins_on_weekday(TimeSpan,WeekDay):-
	time_span_begin_moment(TimeSpan,BeginMoment),
	moment_date(BeginMoment,BeginDate),
	weekday(BeginDate,WeekDay).

earlier_time_span(FirstTimeSpan,SecondTimeSpan):-
	time_span_begin_moment(FirstTimeSpan,FirstBeginMoment),
	time_span_begin_moment(SecondTimeSpan,SecondBeginMoment),
	earlier(FirstBeginMoment,SecondBeginMoment).

time_span_next_date(OldTimeSpan,NewTimeSpan):-
	time_span_begin_moment(OldTimeSpan,OldBeginMoment),
	time_span_end_moment(OldTimeSpan,OldEndMoment),
	moment_date(OldBeginMoment,OldBeginDate),
	moment_date(OldEndMoment,OldEndDate),
	moment_time_unit(OldBeginMoment,BeginTimeUnit),
	moment_time_unit(OldEndMoment,EndTimeUnit),
	% move dates
	next_date(OldBeginDate,NewBeginDate),
	next_date(OldEndDate,NewEndDate),
	[[NewBeginDate,BeginTimeUnit],[NewEndDate,EndTimeUnit]] = NewTimeSpan.


%%%%%% Current Moment %%%%%

% The current moment is based on the system time.
% Note that moments have an accuracy of 30 minutes,
% while the system time is much more precise.

current_moment([[Day,Month,Year],TimeUnit]):-
	get_time(Time),
	convert_time(Time,Year,Month,Day,Hour,Minute,_,_),
	time_hour_minute(RealTimeUnit,Hour,Minute),
	TimeUnit is truncate(RealTimeUnit).

