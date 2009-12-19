%%%%%%%%%%%%%%%%%%
%%    Output    %%
%%%%%%%%%%%%%%%%%%

% When in single-user mode, the output is relayed to
% the standard output.
% In server mode, the current output stream can be determined
% with the "outputstream" predicate.
% Do not change the outputstream without taking the synchronisation
% of the threads into account

:- dynamic(outputstream/1).


%%%%% File Output %%%%%

% The database can be dumped into a file
% Doing this with the following rules, ensures that the
% data can be read in correctly afterwards.

% Terms

write_to_file(FileName,Data):-
        append(FileName),
	nl,
	write(Data),
	write('.'),
	told.

% Appointments

write_appointments_to_file(FileName):-
	forall(appointment(Appointment),write_to_file(FileName,appointment(Appointment))).

% (intern) Persons

write_persons_to_file(FileName):-
	forall(person(intern,Person),write_to_file(FileName,person(intern,Person))).

% Groups

write_groups_to_file(FileName):-
	forall(group_member(Person,Group),write_to_file(FileName,group_member(Person,Group))).

% Completer Database

write_database_to_file(FileName):-
	write_persons_to_file(FileName),
	write_groups_to_file(FileName),
	write_appointments_to_file(FileName).

%%%%%% Newline %%%%%

% server
newline :-
	outputstream(Out),
	nl(Out),
	!.

% single-user
newline :- nl.

%%%%% Simple Text %%%%%

% server
show(Text):-
	outputstream(Out),
	write(Out,Text),
	flush_output(Out),
	!.

% single-user
show(Text):-
	write(Text).

%%%%% Auxiliary %%%%%

% Text followed by a witespace

show_text(Text):-
	show(Text),
	show(' ').

% Numbers
% When a number is smaller than 10, a 0 is printed
% in front of it (e.g. 42 -> 42, 7 -> 07).

show_number(Number) :-
	Number < 10,
	show(0),
	show(Number),
	!.

show_number(Number) :-
	show(Number).

% Text followed by a newline 

print_nl(Text):- 
	show(Text),
	newline.

% Time Unit

show_time_unit(TimeUnit):-
	time_hour_minute(TimeUnit,Hour,Minute),
	show_number(Hour),
	show(':'),
	show_number(Minute).

% Date

show_date([Day,Month,Year]):-
	weekday([Day,Month,Year],WeekDay),
	month_name(Month,MonthName),
	show_text(WeekDay),
	show_text(Day),
	show_text(MonthName),
	show_text(Year).

% Moment

show_moment([Date,TimeUnit]):-
	show_date(Date),
	show_text('at'),
	show_time_unit(TimeUnit),
	show_text('').

% Time Span

show_time_span([BeginMoment,EndMoment]):-
	show_text('from'),
	show_moment(BeginMoment),
	show_text('till'),
	show_moment(EndMoment).

% Persons

show_persons([FirstPerson, LastPerson]):-
	show_text(FirstPerson),
	show_text('and'),
	show_text(LastPerson),
	!.

show_persons([FirstPerson | OtherPersons]):-
	show(FirstPerson),
	show_text(','),
	show_persons(OtherPersons),
	!.

% Appointment

show_appointment([Persons,Constraints,_,TimeSpan]):-
	show_text('Appointment between'),
	show_persons(Persons),
	show_time_span(TimeSpan),
	length(Constraints,NumberOfConstraints),
	show_text('with'),
	show_text(NumberOfConstraints),
	show_text('constraints'),
	newline.

% Multiple Appointments

show_appointments :-
	forall(appointment(Appointment),show_appointment(Appointment)).

show_intern_persons :-
	forall(person(intern,Person),print_nl(Person)).

% Current time

show_current_time :-
	current_moment(Moment),
	show_moment(Moment),
	newline.

% Answers (yes/no)

show_yes :- show('yes'),newline.
show_no :- show('no'),newline.

% Busy Persons

show_busy(Person,TimeSpan):-
        busy(Person,TimeSpan),
	show_yes,!.

show_busy(_,_):-
        show_no.

% Members of a group

show_group(Group) :-
	forall(group_member(Person,Group),print_nl(Person)).

