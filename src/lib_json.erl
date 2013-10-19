%% @author Tommy Mattsson, Georgios Koutsoumpakis
%%   [www.csproj13.student.it.uu.se]
%% @version 1.0
%% @copyright [Copyright information]
%%
%% @doc == Library for accessing fields in JSON objects ==
%% 
%%  
%%
%% @end
-module(lib_json).

%% ====================================================================
%% API functions
%% ====================================================================
-export([get_field/2, get_field_value/3]).
-include("misc.hrl").

%% @doc
%% Function: get_field/2
%% Purpose: Return the value of a certain field in the given JSON string.
%% Returns: Return the value of the specified field, if it exists, 
%%          otherwise returns the empty string.
%% To-Check:  what if there is a ',' inside a Value??? It will fail?
%% @end
-spec get_field(String::string(),Field::string()) -> string().
get_field(Json, Query) ->
    Result = get_field_help(Json, Query),
    make_json_pretty(Result).

get_field_help(Json, Query) ->
    erlang:display(Query),
    JsonObj = mochijson2:decode(Json),
    JsonParser = destructure_json:parse("Obj."++Query),
    JsonParser(JsonObj).



get_field_value(Json, Query, Value) ->
    QueryParts = find_wildcard_fields(Query),
    case wildcard_recursion(Json, QueryParts, Value) of
	Value ->
	    Value;
	_ ->
	    not_found
    end.
	

wildcard_recursion(Json, QueryParts, Value) ->
    wildcard_recursion(Json, QueryParts, Value, "").


wildcard_recursion(Json, [], _Value, Query) ->
    make_json_pretty(get_field_help(Json, Query));
wildcard_recursion(Json, [{wildcard, Field} | Rest], Value, Query) ->
    case get_field_max_index(Json, Field) of
	N when is_integer(N) ->
	    case make_json_pretty(field_recursion(Json, [{wildcard, Field, N}| Rest], Value, Query)) of
		Value ->
		    Value;
		_ ->
		    wildcard_recursion(Json, Rest, Value, Query)
	    end;
	R ->
	    R
    end;
wildcard_recursion(Json, [{no_wildcard, Field}], _Value, Query) ->
    erlang:display("1"++Query),
    NewQuery = lists:concat([Query, Field]),
    erlang:display("2"++NewQuery),
    make_json_pretty(get_field_help(Json, Query)).


field_recursion(Json, [{wildcard, Field, 0 = N} | Rest], Value, Query) ->
    NewQuery = string:join([Query, Field], ?IF(Query == "", "", ".")),
    NewIndexQuery = query_index_prep(NewQuery, N),
    case wildcard_recursion(Json, Rest, Value, NewIndexQuery) of
	Value ->
	    Value;
	R ->
	    R
    end;
field_recursion(Json, [{wildcard, Field, N} | Rest], Value, Query) ->
    NewQuery = string:join([Query, Field], ?IF(Query == "", "", ".")),
    NewIndexQuery = query_index_prep(NewQuery, N),
    case wildcard_recursion(Json, Rest, Value, NewIndexQuery) of
	Value ->
	    Value;
	_ ->
	    field_recursion(Json, [{wildcard, Field, N-1} | Rest], Value, Query)
    end.
    

    

    
get_field_max_index(Json, Query) ->
    case get_field_help(Json, Query) of
	R when is_list(R) ->
	    length(R) - 1;
	R ->
	    R
    end.
    
query_index_prep(Query, N) ->
    lists:concat([Query, "[", integer_to_list(N), "]"]).
    



find_wildcard_fields(Query) ->
    WildCards = re:split(Query, "\\[\\*\\]", [{return, list}]),
    case lists:last(WildCards) of
	[] ->
	    NewWildCards = lists:filter(fun(X) -> X =/= [] end, WildCards),
	    lists:map(fun(X) -> {wildcard, X} end, NewWildCards);
	R ->
	    NewWildCards = lists:sublist(WildCards, length(WildCards)-1),
	    NewWildCards2 = lists:map(fun(X) -> {wildcard, X} end, NewWildCards),
	    NewWildCards2 ++ [{no_wildcard, R}]

    end.








make_json_pretty(R) when is_binary(R) ->
    binary_to_list(R);

make_json_pretty(R) when is_integer(R) ->
    integer_to_list(R);

make_json_pretty(R) when is_list(R) ->
    lists:map(fun make_json_pretty/1, R);

make_json_pretty({struct, Values})  ->
    ValuesList = lists:map(fun tuple_to_list/1, Values),
    StringValues = lists:map(fun make_json_pretty/1, ValuesList),
    lists:map(fun list_to_tuple/1, StringValues);

make_json_pretty(R) ->
    R.
    



%% ====================================================================
%% Internal functions
%% ====================================================================

%trims white spaces and quote from beggining and ending of the string
%% trim(String)->
%% 	Temp = re:replace(re:replace(String, "\\s+$", "", [global,{return,list}]), "^\\s+", "", [global,{return,list}]),
%% 	case re:run(Temp, "^{.*$}", [{capture, first, list}]) of
%% 		{match, _} -> 
%% 			A = Temp;
%% 		_->
%% 			case re:run(Temp, "$}", [{capture, first, list}]) of
%% 				{match, _} -> 
%% 					A = string:substr(Temp, 1, length(Temp)-1);
%% 				_->
%% 					A = Temp
%% 			end
%% 	end,
%% 	Temp = re:replace(re:replace(String, "\\s+$", "", [global,{return,list}]), "^\\s+", "", [global,{return,list}]),
%% 	string:strip(Temp, both, $").



%% @doc
%% Function: remove_special_characters/2
%% Purpose: Help function to remove non alphanumerical characters
%% Returns: First string of alphanumerical characters that can be found,
%%          empty string if non exists
%% @end
%% -spec remove_special_characters(String::string(),CharactersFound::boolean()) -> string().

%% remove_special_characters([],_) ->
%% 	[];

%% remove_special_characters([First|Rest],false) ->
%% 	Character = (First < $[) and (First > $@) or (First < ${) and (First > $`) or (First > $/) and (First < $:),
%% 	case Character of
%% 		true ->
%% 			[First|remove_special_characters(Rest,true)];
%% 		false ->
%% 			remove_special_characters(Rest,false)
%% 	end;
%% remove_special_characters([First|Rest],true) ->
%% 	Character = (First < $[) and (First > $@) or (First < ${) and (First > $`) or (First > $/) and (First < $:),
%% 	case Character of
%% 		true ->
%% 			[First|remove_special_characters(Rest,true)];
%% 		false ->
%% 			[]
%% 	end.


