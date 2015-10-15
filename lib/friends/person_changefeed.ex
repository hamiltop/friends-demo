defmodule Friends.PersonChangefeed do
  use RethinkDB.Changefeed

  require Logger

  import RethinkDB.Query
  alias Friends.Person

  def start_link(opts, gen_server_opts \\ []) do
    RethinkDB.Changefeed.start_link(__MODULE__, opts, gen_server_opts)
  end

  def init({db, pid, id}) do
    ref = Process.monitor(pid)
    q = table("people")
      |> get(id)
      |> changes()
    {:subscribe, q, db, %{pid: pid, ref: ref}}
  end

  def handle_update(data, state = %{pid: pid}) when is_list(data) do
    Enum.each(data, fn
      %{"new_val" => update} ->
        send pid, {:new_person_val, Person.parse(update)}
    end)
    {:next, state}
  end
  def handle_update(%{"new_val" => update}, state = %{pid: pid}) do
    send pid, {:new_person_val, Person.parse(update)}
    {:next, state}
  end

  def handle_info({:DOWN, ref, :process, pid, _}, state = %{pid: pid, ref: ref}) do
    {:stop, :shutdown, state}
  end
end
