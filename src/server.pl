%%%%%%%%%%%%%%%%%%%%
%%     Server     %%
%%%%%%%%%%%%%%%%%%%%

% The port is specified in the configuration part of the
% file "project.pl".

%%%%% Start Server %%%%%%

% When the server starts it creates mutex "lock".
% This lock is used to control the access to the database.
% After the server is started, it transfers control to
% "accept_connections" which will handle the connections.

start_server :-
	mutex_create(lock),
	port(Port),
	tcp_socket(ServerSocket),
	tcp_bind(ServerSocket, Port),
	tcp_listen(ServerSocket, 5),
	format("server listening on port ~a~n",[Port]),
	accept_connections(ServerSocket).

%%%%% Accept Connections %%%%%

% When the server accepts a connection, a new session is started.
% This session is executed in a different thread.
% The standard of the output shows the number of the newly created thread.
% Note that thread #1 is the server itself, the first connection will thus
% be handled by thread #2.

accept_connections(ServerSocket):-
	tcp_accept(ServerSocket, ClientSocket, _),
	thread_create(session(ClientSocket),Id,[]),
	format("starting thread ~a~n",[Id]),
	accept_connections(ServerSocket).

%%%%%% Session %%%%%%

% Session is responsible for creating an input- and output-stream to the user
% After printing a welcome banner, it handles control the handle_requests which
% will communicate with the user.
% Note that at this moment the session thread has no lock and the system outside
% the thread does not have acces to the In and Out streams.
% Therefore the communication must explecitly be handled by giving this streams
% as arguments to the output rules.

session(ClientSocket):-
	tcp_open_socket(ClientSocket, In, Out),
	write(Out,'=== Multi Organizer Server ==='),nl(Out),flush_output(Out),
	handle_requests(In, Out).

%%%%%% Check stop %%%%%

% When the user stops, the system can not just execute "halt",
% like in single-user mode.
% Since the server handles network connections in multiple threads
% the following things should be taken care of:
%	* Proper socket termination
%	* Release of all locks (DEADLOCKS !).
% The server also shows a log message on its standard output,
% and the user is said goodbye.

% Note that closing both the In and Out stream also closes
% the Client Socket that they represent.

% When a thread executes "halt", only the thread in question
% is halted, this does not affect the other threads.

check_stop(stop,In,Out) :-
	thread_self(Id), % determine thread id
	format("stopping thread ~a ~n",[Id]),
	show('Goodbye!'),newline,
	close(In),
	close(Out), 
	mutex_unlock_all, % release all locks of session
	halt. % stop session thread

check_stop(_,_,_).

%%%%%% Handle Requests %%%%%

% The "handle_requests" rule is responsible for the actual communication
% with the users.
% It can be compared with the "driver_loop" rule of the single-user version.

% handle_requests has the following tasks:
% 	1. get the user command
% 	2. get lock for database
%	3. connect input and output streams to session
%	4. parse the command
%	5. execute the parsed command
%	6. clean up for other sessions

handle_requests(In, Out) :-

	%%% Get User Command %%%
	
	% Note that the in- and output streams are not known to the rest
	% of the system yet.
	% It is necessary to flush the output in order for the user to 
	% see the prompt directly.

	write(Out,'#:'),flush_output(Out), 
	
	% the input is read as a list of numbers and transfered into a list of atoms
	% see "input.pl" for more details
	
	read_line_to_codes(In, HumanCommandCodes),
	words(HumanCommandCodes,HumanCommand), 
	
	%%% Lock / Input / Output %%%
	
	mutex_lock(lock),
	asserta(outputstream(Out)),
	asserta(inputstream(In)), 

	%%% Parsing %%%
	
	command_translation(HumanCommand,PrologCommand), 
	debug_info(HumanCommandCodes),
	debug_info(HumanCommand),
	debug_info(PrologCommand),
	
	%%% Execution %%%
	
	check_stop(PrologCommand,In,Out), %close connection if user stops
	PrologCommand, %execute command
	
	%%% Cleen up afterwards %%%%
	
	retract(outputstream(Out)), 
	retract(inputstream(In)),
	mutex_unlock(lock),
	sleep(0.1), % avoid livelock
	
	%%% Wait for next command %%%
	
	handle_requests(In,Out). 


