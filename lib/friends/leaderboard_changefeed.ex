defmodule Friends.LeaderboardChangefeed do
  use RethinkDB.Changefeed

  require Logger

  import RethinkDB.Query

  def start_link(opts, gen_server_opts \\ []) do
    RethinkDB.Changefeed.start_link(__MODULE__, opts, gen_server_opts) 
  end

  def get(pid \\ __MODULE__) do
    RethinkDB.Changefeed.call(pid, :get)
  end

  def init(db) do
    q = table("people")
      |> order_by(%{index: desc("friend_count")})
      |> limit(10)
      |> changes()
    {:subscribe, q, db, nil}
  end

  def handle_update(data, nil) do
    state = Enum.map(data, fn %{"new_val" => val} -> val end)
      |> Enum.reverse 
    {:next, state}  
  end

  def handle_update(updates, list) do
    new_state = Enum.reduce(updates, list, fn (el, acc) ->
      new = Dict.get(el, "new_val")
      old = Dict.get(el, "old_val")
      state = Enum.reject(acc, fn (el) -> el === old end)
      case new do
        nil -> state
        _ -> [new | state]
      end
    end)
    new_state = Enum.sort_by(new_state, &(&1["friend_count"]), &(&1 >= &2))
    Logger.debug "New leader board"
    Enum.each(new_state, fn (el) ->
      Logger.debug("#{Dict.get(el, "name", "unknown")}\t#{Dict.get(el, "friend_count", 0)}")
    end)
    Friends.Endpoint.broadcast! "friends:leaderboard", "new_board", %{data: new_state} 
    {:next, new_state}
  end

  def handle_call(:get, _from, list) do
    {:reply, list, list}
  end
end
