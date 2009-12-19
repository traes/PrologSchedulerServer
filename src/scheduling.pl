%%%%%%%%%%%%%%%%%%%%%%
%%    Scheduling    %%
%%%%%%%%%%%%%%%%%%%%%%

% The scheduler is responsible for finding an adequate time slot.
% It is not authorized to change already made appointments 
% without the explicit permission of a user.
% There is no upper limit on the date of an appointment.
% Take this into account when adapting the ruls below,
% since the scheduler will loop forever if the constraints
% can not be satisfied.

%%%%% Next Time Span %%%%%

% Determine the next time span.
% The constraints can propose a better timespan to optimise
% the performance of the search algorithm
% A time span proposal from a constraint is no guarantee
% that the given timespan will not violate the constraint
% in question.

search_next_time_span(Appointment,TimeSpan,ResultTimeSpan):-
	app_constraints(Appointment,Constraints),
	member(Constraint,Constraints),
	violates_constraint(Constraint,Appointment),
	next_time_span_proposal(TimeSpan,Constraint,ResultTimeSpan),
	!.

search_next_time_span(_,TimeSpan,ResultTimeSpan):-
	next_time_span(TimeSpan,ResultTimeSpan).

%%%%% Latest begin moment %%%%%

% Some constraints dictate an upper limit for the begin moment
% of a timespan
% Since it is no use to look further, we have to detect this
% so the scheduler can take appropriate action (eg. reschedule).
% Not taking this type of constraints into account can cause
% the scheduler to loop forever

latest_begin_moment(Constraints,Moment):-
	member([begin_before_moment,Moment],Constraints).

%%%%% Needs rescheduling %%%%%%

% When there are no other possibilities, the scheduler should reschedule
% an earlier appointment.
% Since this is inconvenient for the user, this should be done as 
% seldom as possible.

needs_rescheduling(Constraints,[ProposedBeginMoment,_]):-
	latest_begin_moment(Constraints,LatestBeginMoment),
	earlier(LatestBeginMoment,ProposedBeginMoment).

%%%%% Reschedule Candidate %%%%%

% Find an appointment that can be rescheduled so that another appointment can take its place.

reschedule_candidate(LatestBeginMoment,[Persons,Constraints,RequestedTimeSpan,ActualTimeSpan]):-
        appointment([Persons,Constraints,RequestedTimeSpan,ActualTimeSpan]),
	[ProposedBeginMoment,_] = ActualTimeSpan,
	earlier(ProposedBeginMoment,LatestBeginMoment),
	not(member([begin_before_moment,_],Constraints)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%    Making Appointments    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The scheduler can make appointments in a number of ways.
% The approach that is the most convenient for the user,
% will be taken.
% If no such solution is obvious, the user his preference is asked.

% The scheduling algorithm takes the following steps:
% 1. If the appointment has conflicting constraints, it is rejected
% 2. If the appointment can be made at the proposed timespan,
%    it is saved in the database and the scheduler is done
% 3. The next time span is tried
% 4. If it can be determined that advancing the timespan won't
%    lead to a solution, another appointment will be rescheduled.
%    This will only happen if the user gives his permission.
% 5. If none of the above worked, the appointment is abandonned.
%    This should only happen if the user rejects to reschedule
%    any other appointment.

%%%%% Check for conflicts %%%%%

make_appointment(Appointment) :-
	conflicting_constraints(Appointment),
	print_nl('Conflicting appointments'),
	!.

%%%%% Make appointment if possible %%%%%

make_appointment(Appointment) :-
	possible_appointment(Appointment),
	assert(appointment(Appointment)),
	!.

%%%%% Try the next timespan %%%%%

make_appointment(Appointment) :-
	app_constraints(Appointment,Constraints),
	app_act_time_span(Appointment,ActualTimeSpan),
	% don't reschedule anything
	not(needs_rescheduling(Constraints,ActualTimeSpan)),
	% search next time span
	search_next_time_span(Appointment,ActualTimeSpan,NextTimeSpan), 
	app_set_act_time_span(Appointment,NextTimeSpan,NewAppointment),
	% make appointment
	make_appointment(NewAppointment),
	!.

%%%%% Try rescheduling %%%%%
make_appointment(Appointment) :-
	app_constraints(Appointment,Constraints),
	app_act_time_span(Appointment,ActualTimeSpan),
	app_req_time_span(Appointment,RequestedTimeSpan),
	% check need for rescheduling	
	needs_rescheduling(Constraints,ActualTimeSpan),
	% reschedule other appointment
	latest_begin_moment(Constraints,LatestBeginMoment),
	reschedule_candidate(LatestBeginMoment,RescheduledAppointment),
	show('can I reschedule:'),newline,show_appointment(RescheduledAppointment),permitted,
	% make current and rescheduled appointment
	app_set_act_time_span(Appointment,RequestedTimeSpan,AdaptedAppointment),
	retract(appointment(RescheduledAppointment)),
	make_appointment(AdaptedAppointment),
	make_appointment(RescheduledAppointment),
	!.

%%%%%% Abandon Appointment %%%%%

make_appointment(_) :-
	print_nl('impossible to schedule appointment').
	
%%%%%% Create Appointment %%%%%

% When the user wants to make an appointment, he can not specify an actual timespan.
% The requested timespan is used as the initial value of the actual timespan.
% The requested timespan is also stored, in case the appointment has to be rescheduled

create_appointment([Persons,Constraints,TimeSpan]):-
	make_appointment([Persons,Constraints,TimeSpan,TimeSpan]).
