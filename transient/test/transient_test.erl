%%% @author Thomas Arts
%%% @doc
%%%
%%% @end
%%% Created : 20 Oct 2020 by Thomas Arts

-module(transient_test).

-compile([export_all, nowarn_export_all]).

user_test() ->
    Pid = transient:start(),
    RoomId = transient:create_room(Pid, "my room"),
    {user_id, _User} = transient:create_user(Pid, RoomId, "me"),
    transient:stop(Pid).

%% Increase Number of rooms to 100 or 1000 and you find an error
multi_user_test() ->
    Rooms = 10,
    timer:sleep(100),
    Pid = transient:start(),
    [ begin
          RoomId = transient:create_room(Pid, lists:concat(["my room ", N])),
          {user_id, _User} = transient:create_user(Pid, RoomId, "me")
      end || N <- lists:seq(1, Rooms) ],
    transient:stop(Pid).
