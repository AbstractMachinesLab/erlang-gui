-module(hex_grid).

-behavior(gen_server).

-export([ start_link/2
        , init/1
        , terminate/2
        , handle_cast/2
        , handle_call/3
        ]).

-export([ dump/0, measure/0 ]).

measure() ->
  hex_grid:start_link([],[]),
  Data = chalk_pipeline:flush_many(),
  file:write_file("medium_cets_ts", io_lib:fwrite("~p", [Data])).

%%==============================================================================
%% Behavior callbacks
%%==============================================================================

start_link(Args, Opts) -> gen_server:start_link({local, ?MODULE}, ?MODULE, Args, Opts).

init(Args) ->
  State = initial_state(Args),
  {ok, do_init(State)}.

terminate(_, _) -> ok.

handle_call(dump, _From, State) -> {reply, State, State};
handle_call(_Msg, _From, State) -> {noreply, State}.

handle_cast(_Msg, State) -> {noreply, State}.

%%==============================================================================
%% Api
%%==============================================================================

dump() -> gen_server:call(?MODULE, dump).

%%==============================================================================
%% Internal
%%==============================================================================

initial_state(_) ->
  #{ size => { 2000, 2000 }
   , cell_size => 100
   , cells => []
   }.

do_init(State=#{ size := {W,H}, cell_size := S }) ->
  {Rows, Cols} = hex_lib:fit_tiles(S, W, H),
  Tiles = hex_lib:build_tiles(S, Rows, Cols),
  chalk_pipeline:register(fun () -> {ok, {0.0,0.0,0.0}, hex_lib:bg()} end),
  Tile = hex_lib:flat_hex_tile(S),
  Cells = lists:map(
            fun (#{ logical := Log
                  , physical := {X,Y}
                  }) ->
                CellArgs = #{ pos => {X,Y,1.0}
                            , logical => Log
                            , tile => Tile
                            , size => S },
                {ok, Pid} = hex_cell:start_link(CellArgs, []),
                Pid
            end, Tiles),
  State#{ tiles => Tiles
        , cells => Cells }.
