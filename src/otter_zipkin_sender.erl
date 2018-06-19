%%%-------------------------------------------------------------------
%%% Licensed to the Apache Software Foundation (ASF) under one
%%% or more contributor license agreements.  See the NOTICE file
%%% distributed with this work for additional information
%%% regarding copyright ownership.  The ASF licenses this file
%%% to you under the Apache License, Version 2.0 (the
%%% "License"); you may not use this file except in compliance
%%% with the License.  You may obtain a copy of the License at
%%%
%%%   http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing,
%%% software distributed under the License is distributed on an
%%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%%% KIND, either express or implied.  See the License for the
%%% specific language governing permissions and limitations
%%% under the License.
%%%
%%%-------------------------------------------------------------------
-module(otter_zipkin_sender).

-behaviour(gen_server).

-export([
         start_link/0,

         init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,

         code_change/3,
         terminate/2
        ]).

-define(SERVER, ?MODULE).

-record(state, {}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    {ok, #state{}, get_time()}.

handle_call(Call, _From, State) ->
    {stop, {bad_call, Call}, State}.

handle_cast(Cast, State) ->
    {stop, {bad_cast, Cast}, State}.

handle_info(timeout, State) ->
    erlang:send_after(get_time(), self(), timeout),
    case catch otter_conn_zipkin:send_buffer() of
        Error={'EXIT', _} ->
            error_logger:error_msg("otter_zipkin_sender: Error: ~p~n", [Error]);
        _ ->
            ok
    end,
    {noreply, State}.

code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_Reason, _State) -> ok.

get_time() ->
    {ok, Time} = application:get_env(zipkin_batch_interval_ms),
    Time.
