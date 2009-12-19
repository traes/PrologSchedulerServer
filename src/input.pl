%%%%%%%%%%%%%%%%%
%%    Input    %%
%%%%%%%%%%%%%%%%%

% This file provides the necessary input predicates.
% Depending on the mode of the program (server of single-user),
% the input has to be redirected to the standard output or
% a network socket.
% Note that the network socket is represented by 2 streams:
% an input stream and an outputstream.
% Since this file only provides input support, only the input stream
% is used.
% Do not try to send any output to this stream.
% If you have to show information to the user, use the facilities
% provided in the output.pl file

%%%%% Input Streams %%%%%

% There can be multiple sessions when using server-mode,
% all this sessions have there own input- and output streams.
% On any given moment, the current inputstream can be determined
% using the "inputstream" predicate.
% Do not change this predicate, since it may only be modified when
% taking the synchronization  of the various threads into account.

:- dynamic(inputstream/1).

%%%%% Debugging %%%%

% When debugging is enabled, debug_enabled is set

:- dynamic(debug_enabled/0).

enable_debug :-
	asserta(debug_enabled).

disable_debug :-
	retract(debug_enabled).

%%%%% Request Input %%%%%

% server 
ask(Response) :-
	inputstream(In),
	read(In,Response),
	!.

% single-user
ask(Response) :- read(Response).

%%%%% Request Persmission %%%%%

permitted :-
	show('yes/no'),
	ask('yes'),
	newline,show('permission granted'),newline.

%%%%% Check Number %%%%%

% When the program is running in server mode,
% the readln predicate can not be used anymore.
% Therefore the read_line_to_codes is used, and
% the codes are changed to the corresponding atoms.
% Unfortunately, this transitions does not take into
% account that some atoms might represent numbers.
% This leads to very subtle bugs that can not be found
% by displaying the atoms since they look the same
% as the numbers they represent.

% single-user (no problem)
check_number(X,X):-
      number(X),
      !.
      
% server mode (correct the representation)
check_number(X,Y):-
      atom_number(X,Y).

%%%%% Stop %%%%%

% In single-user mode, the user can stop the program
% by entering the "stop" command.
% This command does not only stop the multi-organizer program,
% but also stops the underlying Prolog interpreter.

% Note that the "halt" predicate is not used in server mode.
% When in server mode, the stop predicate is caught by the
% read-eval-print loop and handled seperately.
% This is necessary since one has to be sure that the session
% of the user does not hold any locks anymore, and that the
% network sockets are closed properly

stop :- halt.

%%%%%%%%%%%%%%%%%%%%%
%% Command Grammar %%
%% Auxiliary Rules %%
%%%%%%%%%%%%%%%%%%%%%

% This grammar describes the translation from commands in
% natural english into executable prolog commands.
% This grammar is only used for parsing input,
% for the output the rules in the file 'output.pl' are used

%%%%% Persons %%%%%

% Persons can be selected in the following ways:
%	 - internal persons
%	 - external persons
%	 - groups of persons

persons([]) --> [].

% internal
persons([X|Y]) --> 
	[X],
	persons(Y),
		{person(intern,X)}.
	
% external
persons([X|Y]) --> 
	[extern,X],
	persons(Y),
		{person(extern,X)}.
	
% group
persons(Z) --> 
	[group,G],
	persons(Y),
		{group_members(M,G),
		append(M,Y,Z)}.


%%%%% Moment %%%%

% Moments are determined with a day, month, year and timeunits.
% Timeunits are adapted to an accuracy of 30 minutes.
% When no moment is determined, the current moment is used
% The current moment is based on the system time

get_moment([[Day,Month,Year],TimeUnit]) --> 
	[DayAttom,MonthName,YearAttom,at,HourAttom,:,MinuteAttom],
		{month_name(Month,MonthName),
		check_number(DayAttom,Day),
		check_number(YearAttom,Year),
		check_number(HourAttom,Hour),
		check_number(MinuteAttom,Minute),
		time_hour_minute(TimeUnit,Hour,Minute)
		}.

%%%%% Time Span %%%%%

% A time span consists of a begin moment and an end moment.
% The end moment can also be implicitly given, using a duration.
% When no begin moment is given, the current moment is used.
% When no end moment is give, a duration of 30 minuts is assumed.

get_time_span([BeginMoment,EndMoment]) -->  
	[from],
	get_moment(BeginMoment),
	[till],
	get_moment(EndMoment).


get_time_span([BeginMoment,EndMoment]) --> 
	[as, soon, as, possible],
		{current_moment(BeginMoment),
		 next_moment(BeginMoment,EndMoment)}.

get_time_span([BeginMoment,EndMoment]) --> 
	[asap],
		{current_moment(BeginMoment),
		next_moment(BeginMoment,EndMoment)}.

get_time_span([BeginMoment,EndMoment]) -->  
	[on],
	get_moment(BeginMoment),
	[with, duration, Hours, hours, and, Minutes, minutes],
		{time_hour_minute(TimeUnits,Hours,Minutes),
		add_time_unit(BeginMoment,TimeUnits,EndMoment)}.

%%%%% Appointment %%%%

% An appointment can be uniquely identified with one member of
% the participating persons, and the beginmoment.
% This holds as long as the database has no conflicts because
% a person can not take part in multiple meetings at the same time

get_appointment(Appointment) -->
	[with, Person, that, begins, on],
	get_moment(BeginMoment),
		{appointment(Appointment),
		 app_act_time_span(Appointment,ActualTimeSpan),
		 time_span_begin_moment(ActualTimeSpan,BeginMoment),
		 app_persons(Appointment,AppointmentPersons),
		 member(Person,AppointmentPersons)}.
		 
%%%%% Constraints %%%%%

% Constraints are determined by their name (type) and argument.
% Negations of constraints are considered as different constraints.
% When there is no argument used (eg. on_weekend), "no_argument" is
% given as the value of the argument.
% This is convention is only used for debugging purposes, and should
% not the working of the program should not rely on it.

constraints([]) --> [].
constraints([X|Y]) --> constraint(X),constraints(Y).

constraint([on_weekday,DayName]) --> [on, weekday, DayName],{day_name(_,DayName)}.
constraint([not_on_weekday,DayName]) --> [not, on, weekday, DayName],{day_name(_,DayName)}.
constraint([on_weekend,no_argument]) --> [on, a, weekend].
constraint([not_on_weekend,no_argument]) --> [not, on, a, weekend].
constraint([during_office_hours,no_argument]) --> [during, office, hours].
constraint([not_during_office_hours,no_argument]) --> [not, during, office, hours].
constraint([begin_before_moment,Moment]) --> [begin, before],get_moment(Moment).
constraint([begin_after_moment,Moment]) --> [begin, after],get_moment(Moment).
constraint([later_than,TimeUnit]) --> [later, than, Hour,:,Minute],{time_hour_minute(TimeUnit,Hour,Minute)}.
constraint([earlier_than,TimeUnit]) --> [earlier, than, Hour,:,Minute],{time_hour_minute(TimeUnit,Hour,Minute)}.
constraint([on_holiday,no_argument]) --> [on, a, holiday].
constraint([not_on_holiday,no_argument]) --> [not, on, a, holiday].

%%%%%%%%%%%%%%%%%%%%%
%% Command Grammar %%
%%    Commands     %%
%%%%%%%%%%%%%%%%%%%%%

%%%%% Persons %%%%%

command(show_intern_persons) --> [show, intern, persons].
command(make_intern_person(Person)) --> [make, intern, person, Person].

%%%%%% Groups %%%%%

command(add_to_group(Persons,Group)) --> [add],	persons(Persons),[to, group, Group].
command(remove_from_group(Persons,Group)) --> [remove], persons(Persons),[from, group, Group].
command(delete_group(Group)) --> [delete, group, Group].
command(show_group(Group)) --> [show, group, Group].


%%%%% Appointments %%%%%

% Creating Appointments:
% Appointments can be made using different commands.
% Some commands are shorter than others, and user default values for the unspecified parameters

% Some example appointment commands:
% make appointment between alice bob from 3 january 2006 at 14 : 30 till 3 january 2006 at 15 : 00 constrained on weekday wednesday
% make appointment between alice bob from 3 january 2006 at 00 : 30 till 3 january 2006 at 01 : 00 constrained later than 12 : 30 
% make appointment between alice extern kwik bob from 3 january 2006 at 14 : 30 till 3 january 2006 at 15 : 00 constrained on weekday wednesday
% make appointment between alice bob on 3 january 2006 at 14 : 30 with duration 0 hours and 30 minutes

command(create_appointment([Persons,[],TimeSpan])) --> 
	[make, appointment], 
		[between],persons(Persons), 
		get_time_span(TimeSpan).

command(create_appointment([Persons,Constraints,TimeSpan])) --> 
	[make, appointment], 
		[between],persons(Persons), 
		get_time_span(TimeSpan),
		[constrained], constraints(Constraints).

% Deleting Appointments

command(delete_all_appointments) --> [delete, all, appointments].

% Showing Appointments

command(show_appointments) --> [show, appointments]. % all
command(show_appointment(Appointment)) --> [show, appointment],get_appointment(Appointment). % one

% Retracting Appointments

command(retract(appointment(Appointment))) --> [delete, appointment],get_appointment(Appointment).

%%%%% Database %%%%%

command(write_database_to_file(FileName)) --> [save, database, as, FileName].
command(ensure_loaded(Filename)) --> [load, database, from, Filename].
command(execute_file(Filename)) --> [execute, Filename].

%%%%% Debugging %%%%%

command(enable_debug) --> [enable, debug].
command(disable_debug) --> [disable, debug].

%%%%% Other %%%%%

% Show busy persons for a given timespan
command(show_busy(Person,TimeSpan)) --> [is, Person, busy],get_time_span(TimeSpan),{person(intern,Person)}.

% Show the curren time
command(show_current_time) --> [show, current, time].

% Stop the program and underlying interpreter
command(stop) --> [stop]. 

%%%%% Testing %%%%%
% for bug-hunting purposes only,
% should be commented out in production version

command(shell('clear')) --> [clear]. % clear screen
command(fail) --> [break]. % break out of driver loop (enter continue. to continue) 
command(shell('banner -w 100 "8)"')) --> [test, smiley].
command(show([[Day,Month,Year],TimeUnit])) --> 
	[test,moment,Day,MonthName,Year,at,Hour,:,Minute],
		{month_name(Month,MonthName),
		time_hour_minute(TimeUnit,Hour,Minute)}.


%%%%%%%%%%%%%%%%%%%%%%
%%    Interpreter   %%
%%%%%%%%%%%%%%%%%%%%%%

% parse error
parse_error :- show('unknown command'),newline.

% get input from user (single-user only)
human_command(HumanCommand):-
	show('#:'),
	readln(HumanCommand).

% translate human command into prolog command
command_translation(HumanCommand,PrologCommand):-
	phrase(command(PrologCommand),HumanCommand),!.

command_translation(_,parse_error).

% show debug information
debug_info(Info):-
	debug_enabled,
	show('DEBUG INFO:'),
	show(Info),
	newline,
	!.

debug_info(_).

%%%%% Codes to Atoms list %%%%%

% first_word(Input,Output,Word)

first_word([],[],[]).

first_word([32|Rest],Rest,[]).

first_word([First|Rest],TotalResult,[First|Word]):-
	first_word(Rest,TotalResult,Word).

% words(NumberList,AtomList)

words([],[]).

words(List,[Word|RestWords]):-
	first_word(List,Rest,WordNumbers),
	atom_codes(Word,WordNumbers),
	words(Rest,RestWords).

%%%%% Driver Loop %%%%%
% Get input and process it.
% Note that this is not a complete read-eval-print loop,
% since there is no print phase.
% Ouput is only generated by executing "show" commands,
% and therefore belongs to the eval part of the loop.

% This loop is only used in single-user mode.
% The loop for the server mode can be found in the file
% "server.pl" and contains additional rulse to manage
% the synchronisation and communication of the threads

% user-level
driver_loop:-
	human_command(HumanCommand),
	command_translation(HumanCommand,PrologCommand),
	debug_info(PrologCommand),
	PrologCommand,
	driver_loop.

translate_and_execute(HumanCommand) :-
	command_translation(HumanCommand,PrologCommand),
	PrologCommand.

execute_file(Filename):-
	read_file_to_terms(Filename,Terms,[]),
	forall(member(Term,Terms),translate_and_execute(Term)).


