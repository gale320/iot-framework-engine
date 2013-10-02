%% @author Georgios Koutsoumpakis
%%   [www.csproj13.student.it.uu.se]
%% @version 1.0
%% @copyright [Copyright information]

%% @doc Webmachine_resource for /users

-module(users_resource).
-export([init/1, 
	 allowed_methods/2,
	 content_types_accepted/2,
	 content_types_provided/2,
	 process_post/2,
	 delete_resource/2,
	put_resource/2,
	 json_handler/2,
	 get_resource/2,
	 post_is_create/2,
 	 allow_missing_post/2]).

-include_lib("webmachine/include/webmachine.hrl").
-include("include/user.hrl").

%% @doc
%% Function: init/1
%% Purpose: init function used to fetch path information from webmachine dispatcher.
%% Returns: {ok, undefined}
%% @end
-spec init([]) -> {ok, undefined}.
init([]) -> {ok, undefined}.


post_is_create(ReqData, State) -> {false, ReqData, State}.


%% @doc
%% Function: allow_missing_post/2
%% Purpose: If the resource accepts POST requests to nonexistent resources, then this should return true.
%% Returns: {true, ReqData, State}
%% @end

allow_missing_post(ReqData, State) ->
	{true, ReqData, State}.


%% @doc
%% Function: allowed_methods/2
%% Purpose: init function used to fetch path information from webmachine dispatcher.
%% Returns: {ok, undefined}
%% @end

allowed_methods(ReqData, State) ->
	case parse_path(wrq:path(ReqData)) of
		[{"users",_}] ->
			{['GET', 'PUT', 'DELETE'], ReqData, State};
		[{"users"}] ->
			{['POST','GET'], ReqData, State};
		[error] ->
			{['POST','GET'], ReqData, State}
	end.



%% @doc
%% Function: content_types_provided/2
%% Purpose: based on the Accept header on a 'GET' request, we provide different media types to the client. 
%%          A code 406 is returned to the client if we cannot return the media-type that the user has requested. 
%% Returns: {[{Mediatype, Handler}], ReqData, State}
%% @end
content_types_provided(ReqData, State) ->
	{[{"application/json", get_resource}], ReqData, State}.


%% @doc
%% Function: content_types_accepted/2
%% Purpose: based on the content-type on a 'POST' or 'PUT', we know which kind of data that is allowed to be sent to the server.
%%          A code 406 is returned to the client if we don't accept a media type that the client has sent. 
%% Returns: {[{Mediatype, Handler}], ReqData, State}
%% @end
content_types_accepted(ReqData, State) ->
	{[{"application/json", json_handler}], ReqData, State}.


%% @doc
%% Function: process_post/2
%% Purpose: Adds a stream to the database on a 'POST' method.
%% Returns: {true, ReqData, State} | {{error, Reason}, ReqData, State}
%% @end
process_post(ReqData, State) ->
	erlang:display("Posting request"),
	{User, _, _} = json_handler(ReqData, State),
	erlang:display(User),
	case db_api:create_user(User) of
		{aborted, Reason} -> {{error, Reason}, ReqData, State};
		{error, Reason} -> {{error, Reason}, ReqData, State};
		ok -> {true, ReqData, State}
	end.


%% @doc
%% Function: put_resource/2
%% Purpose: Returns the JSON representation of a json-object or multiple json-objects. 
%%  		Fault tolerance is handled by resources_exists/2.
%% Returns: {true, ReqData, State} | {false, ReqData, State}
%% @end
put_resource(ReqData, State) ->
	erlang:display("put request"),
	Id = proplists:get_value('?', wrq:path_info(ReqData)),
	{User, _,_} = json_handler(ReqData, State),
	case db_api:get_user_by_id(list_to_integer(Id)) of
		{aborted, Reason} -> {{error, Reason}, ReqData, State};
		{error, Reason} -> {{error, Reason}, ReqData, State};
		_ -> db_api:update_user(list_to_integer(Id), User),
			 {true, ReqData, State}
	end.


%% DELETE
delete_resource(ReqData, State) ->
	erlang:display("delete request"),
	{true, ReqData, State}.


%% @doc
%% Function: json_handler/2
%% Purpose: decodes a JSON object and returns a record representation of this.
%% Returns: {Stream :: record, ReqData, State}
%% @end
json_handler(ReqData, State) ->
	[{Value,_ }] = mochiweb_util:parse_qs(wrq:req_body(ReqData)), 
	case Value of
		[] -> {{error, "empty body"}, ReqData, State};
		_ ->
			{struct, JsonData} = mochijson2:decode(Value),
			User = json_to_user(JsonData),
			{User, ReqData, State}
	end.


%% @doc
%% Function: get_resource/2
%% Purpose: Returns the JSON representation of a json-object or multiple json-objects. 
%%  		Fault tolerance is handled by resources_exists/2.
%% Returns: {true, ReqData, State} | {false, ReqData, State}
%% @end

get_resource(ReqData, State) ->
	case proplists:get_value('?', wrq:path_info(ReqData)) of
		undefined -> 
			% Get all users
			Users = lists:map(fun(X) -> user_to_json(X) end, db_api:get_all_users()),
			{Users, ReqData, State};
		X -> 
			% Get specific user
			case User = db_api:get_user_by_id(list_to_integer(X)) of
				{error, "unknown_user"} -> {"unknown_user", ReqData, State};
		 		_ -> {user_to_json(User), ReqData, State}
			end
	end.


%% @doc
%% Function: json_to_user/1
%% Purpose: Given a proplist, the return value will be a 'user' record with the values taken from the proplist.
%% Returns: user::record()
%% @end

json_to_user(JsonData) ->
	#user{id = proplists:get_value(<<"id">>, JsonData),
		email = proplists:get_value(<<"email">>, JsonData), 
		user_name = proplists:get_value(<<"user_name">>, JsonData),
		password = proplists:get_value(<<"password">>, JsonData), 
		first_name = proplists:get_value(<<"first_name">>, JsonData), 
		last_name = proplists:get_value(<<"last_name">>, JsonData), 
		description = proplists:get_value(<<"description">>, JsonData),
		latitude = proplists:get_value(<<"latitude">>, JsonData), 
		longitude = proplists:get_value(<<"longitude">>, JsonData), 
		creation_date = proplists:get_value(<<"creation_date">>, JsonData),
		last_login = proplists:get_value(<<"last_login">>, JsonData)
	}.


%% @doc
%% Function: parse_path/1
%% Purpose: Given a string representation of a search path, the path is split by the '/' token
%%			and the return value is a list of tuples [{dir, id}].
%% Returns: [{"directory_name", "id_value"}] | [{Error, Err}] | []
%% @end

parse_path(Path) -> 
	[_|T] = filename:split(Path),
	pair(T).

pair([]) -> [];
pair([A]) -> [{A}];
pair([A,B|T]) ->
	case string:to_integer(B) of
		{V, []} -> [{A,V}|pair(T)];
		{error, no_integer} -> [error]
	end.


%% @doc
%% Function: user_to_json/1
%% Purpose: decodes a record 'user' to a JSON object and returns it.
%% Returns: obj :: JSON()
%% @end

user_to_json(Record) ->
  [_ | Values] = tuple_to_list(Record),
  Keys = [<<"id">>, <<"email">>, <<"user_name">>, <<"password">>, 
		  <<"first_name">>, <<"last_name">>, <<"description">>,
		  <<"latitude">>, <<"longitude">>, <<"creation_date">>,
		  <<"last_login">>],
  P_list = merge_lists(Keys, Values),
  mochijson2:encode({struct, P_list}).

%% @doc
%% Function: merge_lists/2
%% Purpose: helper function to user_to_json/1, given a list of keys and a list of values, this function
%%			will create a list [{Key, Value}], if a value is undefined, it will remove the value and the key 
%% 			that it corresponds, both lists are assumed to be of equal length.
%% Returns: [{Key, Value}] | []
%% @end

%% PRE-COND: Assumes that both lists are of equal size.
merge_lists([], []) -> [];
merge_lists([H|T], [A|B]) ->
	case A of
		undefined -> merge_lists(T,B);
		_ -> [{H,A}]++merge_lists(T,B)
	end.


%% To-do : HTTP Caching support w etags / header expiration.


	
