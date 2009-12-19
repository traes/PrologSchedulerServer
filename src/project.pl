% Thomas Raes
% traes@vub.ac.be
% 15/01/2006

%%%%%%%%%%%%%%%%%%%%
%%    Project     %%
%%%%%%%%%%%%%%%%%%%%

%%%%% Configuration %%%%%

port(5000).

%%%%% Source Files %%%%%

:-use_module(library(socket)).

files([
	'persons.pl',
	'time.pl',
	'holidays.pl',
	'constraints.pl',
	'appointments.pl',
	'scheduling.pl',
	'output.pl',
	'input.pl',
	'server.pl'
	]).

load_code :-
	files(AllFiles),
	forall(member(File,AllFiles),ensure_loaded(File)).

%%%%% Start Program %%%%%

% server
start :-
	format("loading code ~n"),
	load_code,
	format("starting server ~n"),
	start_server.

% single-user
single_user :-
	format("loading code ~n"),
	load_code,
	format("starting driver loop ~n"),
	driver_loop.

