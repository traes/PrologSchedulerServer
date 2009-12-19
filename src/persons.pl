%%%%%%%%%%%%%%%%%%%%
%%     Persons    %%
%%%%%%%%%%%%%%%%%%%%

%%%%% Person %%%%%
% A person consists of a type (intern/extern) and a name.

:- dynamic(person/2).

make_intern_person(Person):-
	assert(person(intern,Person)).

%%%%% Groups %%%%%
% The group_member predicate consists of a user and group
% Groups don't have to be made or removed since they only consist
% out of an atomic name
% When there are no group_member rules with the name of the group,
% the rule is considered inexistant.

:- dynamic(group_member/2).

% List of members

group_members(Members,Group):-
	findall(Member,group_member(Member,Group),Members).

% Add persons to group
% Persons can belong to multiple groups

add_to_group(Persons,Group):-
	forall(	member(Person,Persons),	asserta(group_member(Person,Group))).

% Remove person from group

remove_from_group(Persons,Group):-
	forall(member(Person,Persons),retract(group_member(Person,Group))).

% Delete a group

delete_group(Group):-
	retractall(group_member(_,Group)).

