%%%%%%%%%%%%%%%%%%%%%%%%
%%    Appointments    %%
%%%%%%%%%%%%%%%%%%%%%%%%

% rule for storing appointments in database
:- dynamic(appointment/1).

% get elements of an appointment
app_persons([Persons,_,_,_],Persons).
app_constraints([_,Constraints,_,_],Constraints).
app_req_time_span([_,_,RequestedTimeSpan,_],RequestedTimeSpan).
app_act_time_span([_,_,_,ActualTimeSpan],ActualTimeSpan).

% set the actual time span
app_set_act_time_span([P,C,R,_],ActualTimeSpan,[P,C,R,ActualTimeSpan]).

% check whether a person has an appointment during a given timespan
busy(Person,TimeSpan) :-
	appointment(ExistingAppointment),
	app_persons(ExistingAppointment,BusyPersons),
	app_act_time_span(ExistingAppointment,BusyTimeSpan),
	member(Person,BusyPersons),
	overlap(TimeSpan,BusyTimeSpan).

% check whether a list of persons are available during a given time span
available_persons([],_).

available_persons([FirstPerson | OtherPersons], TimeSpan) :-
	not(busy(FirstPerson,TimeSpan)),
	available_persons(OtherPersons,TimeSpan).

% check whether all participants can take part in the appointment
app_persons_ok(Appointment):-
	app_persons(Appointment,Persons),
	app_act_time_span(Appointment,TimeSpan),
	available_persons(Persons,TimeSpan).
	

% decide whether an appointment is valid
possible_appointment(Appointment) :-
	app_persons_ok(Appointment),
	app_constraints_ok(Appointment).

% remove all appointments from the database
delete_all_appointments :- retractall(appointment(_)).

