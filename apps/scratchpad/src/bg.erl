-module(bg).

-behavior(gen_server).

-export([ start_link/2
        , init/1
        , terminate/2
        , handle_cast/2
        , handle_call/3
        ]).

-export([ draw/0
        , start/0
        , restart/0
        ]).

%%==============================================================================
%% Behavior callbacks
%%==============================================================================

start_link(Args, Opts) ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, Args, Opts).

init(_) ->
  chalk_pipeline:register(fun () -> bg:draw() end),
  {ok, none}.

terminate(_, _) -> ok.

handle_call(draw, _From, State) -> do_draw(State);
handle_call(_Msg, _From, State) -> {noreply, State}.

handle_cast(_Msg, State) -> {noreply, State}.

%%==============================================================================
%% Api
%%==============================================================================

start() ->
  bg:start_link([],[]),
  chalk:set_frame_rate(30.0).

restart() ->
  gen_server:stop(bg),
  chalk_pipeline:clear(),
  start().

draw() -> gen_server:call(?MODULE, draw).

%%==============================================================================
%% Internal
%%==============================================================================

do_draw(State) -> {reply, {ok, {0.0,0.0,0.0}, hex_lib:bg()}, State}.
