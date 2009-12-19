%%%%%%%%%%%%%%%%%%%%
%%    Holidays    %%
%%%%%%%%%%%%%%%%%%%%

% These rules define the holidays.
% There are regular and irregular holidays
% Regular holidays fall on the same day and month
% evey year, irreguler hollidays don't have such
% a pattern.

%%%%%% Regular %%%%%%

holiday([1,11,_]). 
holiday([11,11,_]). 
holiday([18,11,_]). % St V.
holiday([1,1,_]). % new year
holiday([25,12,_]). % christmas

%%%%% Irregular %%%%%

% The irregular holidays are given till 2010.
% Some of the irregular holidays can be computed
% for any given year.
% However, these computations can cost a lot
% of computation time, especially since they have to be
% checked for every possible timespan that the 
% scheduler proposes.

% easter synday (paaszondag)
holiday([27,3,2005]).
holiday([16,4,2006]).
holiday([8,4,2007]).
holiday([23,3,2008]).
holiday([12,4,2009]).
holiday([4,4,2010]).
holiday([24,4,2010]).

% ascension day (hemelvaart)
holiday([5,5,2005]).
holiday([25,5,2006]).
holiday([17,5,2007]).
holiday([1,5,2008]).
holiday([21,5,2009]).
holiday([13,5,2010]).
holiday([2,6,2010]).

% whit sunday (pinksteren)
holiday([15,5,2005]).
holiday([4,6,2006]).
holiday([27,5,2007]).
holiday([11,5,2008]).
holiday([31,5,2009]).
holiday([23,5,2010]).
holiday([12,6,2010]).
