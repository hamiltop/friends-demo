defmodule Friends.PeopleChangefeed do
  use RethinkDB.Changefeed

  import RethinkDB.Query

  def start_link(db, gen_server_opts \\ []) do
    RethinkDB.Changefeed.start_link(__MODULE__, db, gen_server_opts)
  end

  def init(db) do
    query = table("people") |> changes()
    {:subscribe, query, db, {db, nil}}
  end

  def handle_update(_data, {db, nil}) do
    %{data: people} = table("people") |> RethinkDB.run(db)
    people = Enum.map(people, fn (person) ->
      {person["id"], person}
    end) |> Enum.into(%{})
    {:next, {db, people}}
  end

  def handle_update(data, {db, people}) do
    people = Enum.reduce(data, people, fn
      %{"new_val" => v = %{"id" => id}}, p ->
        Dict.put(p, id, v)
    end)
    Friends.Endpoint.broadcast! "friends:person", "new_world", %{data: Dict.values(people)}
    {:next, {db, people}}
  end

  def handle_call(:get, _from, {db, nil}) do
    {:reply, nil, {db, nil}}
  end

  def handle_call(:get, _from, {db, people}) do
    {:reply, Dict.values(people), {db, people}}
  end
end
