%%%%%%%%%%%%%%%%%%%%%%%
%%    Constraints    %%
%%%%%%%%%%%%%%%%%%%%%%%

% get elements from a constraint
constraint_type([Type,_],Type).
constraint_arg([_,Argument],Argument).

% begin and end of office hours
office_hours_begin(18).
office_hours_end(34).

%%%%% Constraint Violations %%%%
% these rules determine whether an appointment violates a given constraint

% Weekday

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,not_on_weekday),
	constraint_arg(Constraint,ForBiddenWeekDay),
	app_act_time_span(Appointment,TimeSpan),
	% appointment may not begin on a given weekday
	time_span_begins_on_weekday(TimeSpan,ForBiddenWeekDay).

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,on_weekday),
	constraint_arg(Constraint,AllowedWeekDay),
	app_act_time_span(Appointment,TimeSpan),
	% appointment may only begin on a given weekday
	not(time_span_begins_on_weekday(TimeSpan,AllowedWeekDay)).

% Weekend

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,not_on_weekend),
	app_act_time_span(Appointment,TimeSpan),
	time_span_begin_moment(TimeSpan,BeginMoment),
	moment_date(BeginMoment,BeginDate),
	% appointment may not begin on a day during the weekend
	weekday(BeginDate,WeekDay),
	weekend(WeekDay).

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,on_weekend),
	app_act_time_span(Appointment,TimeSpan),
	time_span_begin_moment(TimeSpan,BeginMoment),
	moment_date(BeginMoment,BeginDate),
	% appointment may not begin on a day during the week
	weekday(BeginDate,WeekDay),
	not(weekend(WeekDay)).
	
% Begin before moment

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,begin_before_moment),
	constraint_arg(Constraint,LatestBeginMoment),
	app_act_time_span(Appointment,TimeSpan),
	time_span_begin_moment(TimeSpan,BeginMoment),
	% appointment may not begin after the earliest given moment
	earlier(LatestBeginMoment,BeginMoment).

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,begin_after_moment),
	constraint_arg(Constraint,LatestBeginMoment),
	app_act_time_span(Appointment,TimeSpan),
	time_span_begin_moment(TimeSpan,BeginMoment),
	% appointment may not begin after the earliest given moment
	earlier(BeginMoment,LatestBeginMoment).

% Begin earlier/later than given time

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,later_than),
	constraint_arg(Constraint,EarliestTimeUnit),
	app_act_time_span(Appointment,TimeSpan),
	time_span_begin_moment(TimeSpan,BeginMoment),
	moment_time_unit(BeginMoment,BeginTimeUnit),
	BeginTimeUnit < EarliestTimeUnit.

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,earlier_than),
	constraint_arg(Constraint,EarliestTimeUnit),
	app_act_time_span(Appointment,TimeSpan),
	time_span_begin_moment(TimeSpan,BeginMoment),
	moment_time_unit(BeginMoment,BeginTimeUnit),
	BeginTimeUnit > EarliestTimeUnit.

% Office hours 

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,during_office_hours),
	app_act_time_span(Appointment,TimeSpan),
	office_hours_end(LatestTimeUnit),
	time_span_begin_moment(TimeSpan,BeginMoment),
	moment_time_unit(BeginMoment,BeginTimeUnit),
	BeginTimeUnit > LatestTimeUnit.

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,during_office_hours),
	app_act_time_span(Appointment,TimeSpan),
	office_hours_begin(EarliestTimeUnit),
	time_span_begin_moment(TimeSpan,BeginMoment),
	moment_time_unit(BeginMoment,BeginTimeUnit),
	BeginTimeUnit < EarliestTimeUnit.

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,not_during_office_hours),
	app_act_time_span(Appointment,TimeSpan),
	office_hours_begin(OfficeBeginTimeUnit),
	office_hours_end(OfficeEndTimeUnit),
	time_span_begin_moment(TimeSpan,BeginMoment),
	moment_time_unit(BeginMoment,BeginTimeUnit),
	BeginTimeUnit > OfficeBeginTimeUnit,
	BeginTimeUnit < OfficeEndTimeUnit.

% Holidays

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,on_holiday),
	app_act_time_span(Appointment,TimeSpan),
	time_span_begin_moment(TimeSpan,BeginMoment),
	moment_date(BeginMoment,Date),
	not(holiday(Date)).

violates_constraint(Constraint,Appointment):-
	constraint_type(Constraint,not_on_holiday),
	app_act_time_span(Appointment,TimeSpan),
	time_span_begin_moment(TimeSpan,BeginMoment),
	moment_date(BeginMoment,Date),
	holiday(Date).


%%%%% Constraints Respected %%%%%
% check whether an appointment does not violate any constraints

constraints_respected([],_).

constraints_respected([FirstConstraint | OtherConstraints],Appointment):-
	not(violates_constraint(FirstConstraint,Appointment)),
	constraints_respected(OtherConstraints,Appointment).

app_constraints_ok(Appointment):-
	app_constraints(Appointment,Constraints),
	constraints_respected(Constraints,Appointment).


%%%%% Next Time proposals %%%%%
% These rules are optimisations for the scheduler.
% Normally a scheduler searches in steps of 30 minutes.
% Sometimes there exist more efficient time steps.
% If no proposals for the next time span are defined,
% the scheduler will use the default of 30 minutes.

next_time_span_proposal(TimeSpan,Constraint,NewTimeSpan):-
	constraint_type(Constraint,on_holiday),
	time_span_next_date(TimeSpan,NewTimeSpan),
	!.

next_time_span_proposal(TimeSpan,Constraint,NewTimeSpan):-
	constraint_type(Constraint,not_on_holiday),
	time_span_next_date(TimeSpan,NewTimeSpan),
	!.

next_time_span_proposal(TimeSpan,Constraint,NewTimeSpan):-
	constraint_type(Constraint,on_weekend),
	time_span_next_date(TimeSpan,NewTimeSpan),
	!.

next_time_span_proposal(TimeSpan,Constraint,NewTimeSpan):-
	constraint_type(Constraint,not_on_weekend),
	time_span_next_date(TimeSpan,NewTimeSpan),
	!.

next_time_span_proposal(TimeSpan,Constraint,NewTimeSpan):-
	constraint_type(Constraint,on_weekday),
	time_span_next_date(TimeSpan,NewTimeSpan),
	!.

next_time_span_proposal(TimeSpan,Constraint,NewTimeSpan):-
	constraint_type(Constraint,not_on_weekday),
	time_span_next_date(TimeSpan,NewTimeSpan),
	!.

% default: move 30 minutes
next_time_span_proposal(TimeSpan,_,ResultTimeSpan):-
	next_time_span(TimeSpan,ResultTimeSpan).
	
%%%%% Constraint Conflicts %%%%%
% An appointment can have multiple constraints.
% The appointment may not violate any of its constraints.
% This is impossible in some cases, for example if an appointment
% has both the constraints "on a weekend" and "not on a weekend".
% To prevent the scheduler from entering an infinite loop,
% the set of constraints of an appointment is checked for
% such kinds of conflicts before the scheduler tries to find
% a timespan for the appointment.
% When new constraints are to be added to the program,
% one should also update the conflict rules accordingly.

% mutually exclusive constraint types
conflicting_constraint_types(on_holiday,not_on_holiday).
conflicting_constraint_types(on_weekend,not_on_weekend).
conflicting_constraint_types(during_office_hours,not_during_office_hours).

constraint_conflict(Constraint,Appointment):-
	app_constraints(Appointment,Constraints),
	member(OtherConstraint,Constraints),
	constraint_type(Constraint,ConstraintType),
	constraint_type(OtherConstraint,OtherConstraintType),
	conflicting_constraint_types(ConstraintType,OtherConstraintType),
	!.

conflicting_constraints(Appointment):-
	app_constraints(Appointment,Constraints),
	member(ConflictingConstraint,Constraints),
	constraint_conflict(ConflictingConstraint,Appointment).

