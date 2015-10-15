defmodule Friends.FollowersChangefeed do
  use RethinkDB.Changefeed

  require Logger
  
  import RethinkDB.Lambda
  import RethinkDB.Query

  def start_link(opts, gen_server_opts \\ []) do
    RethinkDB.Changefeed.start_link(__MODULE__, opts, gen_server_opts)
  end

  def init({db, pid, id}) do
    ref = Process.monitor(pid)
    q = table("people")
      |> filter(lambda fn (x) -> x["friends"] |> contains(id) end)
      |> changes()
    {:subscribe, q, db, %{pid: pid, ref: ref}}
  end

  def handle_update(data, state = %{pid: pid}) do
    Enum.each(data, fn
      %{"new_val" => nil, "old_val" => update} ->
        send pid, {:lost_follower, update}
      %{"new_val" => update , "old_val" => nil} ->
        send pid, {:new_follower, update}
      _ -> :ok
    end)
    {:next, state}
  end

  def handle_info({:DOWN, ref, :process, pid, _}, state = %{pid: pid, ref: ref}) do
    {:stop, :shutdown, state}
  end
end
