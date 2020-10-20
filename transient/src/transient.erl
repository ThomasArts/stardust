%% This is an extreme simplification of a typical transient fault.
%% The underlaying error is a possible race condition that kicks in now and then.
%% The race is observable by a non-functioning API call, resulting in 'error'
%% instead of expected value 'ok'
%%
%% The original bug is a piece of software with many more layers, in which the API
%% is a http request. A lot more happens in a real system, many more layers,
%% but it is interesting to see whether sessions types can contribute in this
%% extreme simplification of the issue.
%%
%% For the purpose of the example, I removed all OTP behaviour.
%% If this error can successfully be detected with session types, then creating
%% a version with appplication, supervisor and gen_servers is a logical next step.
%%
%% Compare results to the use of PULSE
%% http://www.cse.chalmers.se/~nicsma/papers/finding-race-conditions.pdf
%% (https://dl.acm.org/doi/10.1145/1631687.1596574)
%%
-module(transient).

%% The API
-export([start/0, stop/1]).
-export([create_room/2, create_user/3]).


-spec start() -> pid().
start() ->
    spawn(fun() -> server(0) end).

-spec stop(pid()) -> ok.
stop(Pid) ->
    Pid ! {stop, self()},
    receive
        stopped -> ok
    after 200 ->
            exit(Pid, kill),
            ok
    end.

-spec create_room(pid(), string()) -> integer().
create_room(Pid, Name) ->
    Pid ! {room, self(), Name},
    receive
        {room_id, Room} ->
            Room
    end.

%% Interesting other error is when we match in the receive
%% on {user_id, _}, because then client could get in a deadlock state.
-spec create_user(pid(), integer(), string()) -> {user_id, integer()}.
create_user(Pid, RoomId, Name) ->
    Pid ! {user, self(), RoomId, Name},
    receive
        User -> User
    end.


%% This code should be in separate modules
%% but here for case of simplicity in working with it

server(Rooms) ->
    receive
        {room, From, Name} ->
            RoomId = list_to_atom(lists:concat(["room",Rooms])),
            From ! {room_id, RoomId},
            _ = spawn_link(fun() -> room(RoomId, Name, [{From, "created"}]) end),
            server(Rooms + 1);
        {user, From, RoomId, Name} ->
            try RoomId ! {user, From, Name}
            catch _:_ ->
                    From ! error
            end,
            server(Rooms);
        {stop, From} ->
            exit(stopped)
    end.


room(RoomId, Name, Msgs) ->
    register(RoomId, self()),
    room_loop(RoomId, Name, Msgs, []).

room_loop(RoomId, Name, Msgs, Users) ->
    receive
        {user, From, User} ->
            UserId = length(Users),
            From ! {user_id, UserId},
            room_loop(RoomId, Name, [{From, User, "welcome"} | Msgs], [{UserId, User} | Users])
    end.
