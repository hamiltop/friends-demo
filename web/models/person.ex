defmodule Friends.Person do
  defstruct name: nil, friends: MapSet.new, id: nil

  require Logger

  import RethinkDB.Lambda
  import RethinkDB.Query, except: [get: 2, get: 1]
  alias RethinkDB.Record
  alias RethinkDB.Collection

  def save(person = %__MODULE__{}, db \\ Friends.Database) do
    data = %{
      name: person.name,
      friends: Enum.to_list(person.friends),
      friend_count: Enum.count(person.friends),
    }
    case person.id do
      nil ->
        query = table("people") |> insert(data)
        %Record{data: %{"generated_keys" => [id]}} = RethinkDB.run(query, db)
        %{person | id: id}
      x ->
        table("people") |> RethinkDB.Query.get(x) |> update(data) |> RethinkDB.run(db)
        person
    end
  end

  def add_follower(person = %__MODULE__{friends: friends}, id, db \\ Friends.Database) do
    person = %{person | friends: Set.put(friends, id)}
    save(person, db)
  end

  def remove_follower(person = %__MODULE__{friends: friends}, id, db \\ Friends.Database) do
    person = %{person | friends: Set.delete(friends, id)}
    save(person, db)
  end

  def get(id, db \\ Friends.Database) do
    Logger.debug("getting #{inspect id}")
    %Record{data: person} = table("people") |> RethinkDB.Query.get(id) |> RethinkDB.run(db)
    parse(person)
  end

  def get_all(db \\ Friends.Database) do
    %Collection{data: people} = table("people") |> RethinkDB.run(db)
    Enum.map(people, &parse/1)
  end


  def get_all_followers_and_strangers(person, db \\ Friends.Database) do
    %RethinkDB.Record{data: people} = table("people") |> group(lambda fn (p) ->
      p["friends"] |> contains(person.id)
    end) |> RethinkDB.run(db)
    Enum.map(people, fn
      {true, list} ->
        {:followers, Enum.map(list, &parse/1)}
      {false, list} ->
        {:strangers, Enum.map(list, &parse/1)}
    end) |> Enum.into(%{})
  end

  def get_all_following(person, db \\ Friends.Database) do
    empty = MapSet.new
    case person.friends do
      ^empty -> []
      friends ->
        %RethinkDB.Collection{data: data} = table("people")
          |> get_all(friends |> Enum.to_list)
          |> RethinkDB.run(db)
        Enum.map(data, &parse/1)
    end
  end

  def parse(person) do
    %__MODULE__{
      name: person["name"],
      friends: Enum.into(person["friends"], MapSet.new),
      id: person["id"]
    }
  end
end
