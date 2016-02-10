-module(quintana).

-export([begin_timed/1]).
-export([notify_counter/1]).
-export([notify_counter/2]).
-export([notify_duration/1]).
-export([notify_duration/2]).
-export([notify_gauge/1]).
-export([notify_gauge/2]).
-export([notify_histogram/1]).
-export([notify_histogram/2]).
-export([notify_histogram/4]).
-export([notify_history/1]).
-export([notify_history/2]).
-export([notify_meter/1]).
-export([notify_meter/2]).
-export([notify_meter_reader/1]).
-export([notify_meter_reader/2]).
-export([notify_spiral/1]).
-export([notify_spiral/2]).
-export([notify_timed/1]).
-export([prepare/2]).
-export([with_timer/2]).

notify_counter(Event) ->
    notify(new_counter, Event).
notify_counter(Name, Value) ->
    notify(new_counter, Name, Value).

notify_gauge(Event) ->
    notify(new_gauge, Event).
notify_gauge(Name, Value) ->
    notify(new_gauge, Name, Value).

notify_histogram(Event) ->
    notify(new_histogram, Event).
notify_histogram(Name, Value) ->
    notify(new_histogram, Name, Value).

notify_histogram(Name, Value, Type, Attrs) ->
    notify(new_histogram, {Name, Value, Type, Attrs}).

notify_history(Event) ->
    notify(new_history, Event).
notify_history(Name, Value) ->
    notify(new_history, Name, Value).

notify_meter(Event) ->
    notify(new_meter, Event).
notify_meter(Name, Value) ->
    notify(new_meter, Name, Value).

notify_meter_reader(Event) ->
    notify(new_meter_reader, Event).
notify_meter_reader(Name, Value) ->
    notify(new_meter_reader, Name, Value).

notify_duration(Event) ->
    notify(new_duration, Event).
notify_duration(Name, Value) ->
    notify(new_duration, Name, Value).

notify_spiral(Event) ->
    notify(new_spiral, Event).
notify_spiral(Name, Value) ->
    notify(new_spiral, Name, Value).

notify_timed(Timer) ->
    case folsom_metrics:safely_histogram_timed_notify(Timer) of
        {error, Name, nonexistent_metric} ->
            folsom_metrics:new_histogram(Name),
            folsom_metrics:safely_histogram_timed_notify(Timer);
        _ ->
            ok
    end.

with_timer(Name, Fun) ->
    Metric = begin_timed(Name),
    Res = Fun(),
    ok = notify_timed(Metric),
    Res.

begin_timed(Name) ->
    folsom_metrics:histogram_timed_begin(Name).

notify(Fun, {Name, Value, Type, Attrs}) ->
    case folsom_metrics:safely_notify(Name, Value) of
        {error, Name, nonexistent_metric} ->
            folsom_metrics:Fun(Name, Type, Attrs),
            folsom_metrics:safely_notify(Name, Value);
        _ ->
            ok
    end;
notify(Fun, {Name, Value}) ->
    notify(Fun, Name, Value).

notify(Fun, Name, Value) ->
    case folsom_metrics:safely_notify(Name, Value) of
        {error, Name, nonexistent_metric} ->
            prepare(Fun, Name),
            folsom_metrics:safely_notify(Name, Value);
        _ ->
            ok
    end.

prepare(Fun, Name) ->
    case Fun of
        new_spiral ->
            folsom_metrics:Fun(Name, no_exceptions);
        _ ->
            folsom_metrics:Fun(Name)
    end.
