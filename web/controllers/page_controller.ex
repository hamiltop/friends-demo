defmodule Friends.PageController do
  use Friends.Web, :controller

  alias Friends.Person

  def index(conn, params) do
    case Dict.get(params, "id") do
      nil ->
        name = Friends.WordSource.random_name
        person = Person.save(%Person{name: name, friends: MapSet.new})
        redirect conn, to: "/" <> person.id 
      id ->
        board = Friends.LeaderboardChangefeed.get || []
        person = Person.get(id)
        following = Person.get_all_following(person)
        result = Person.get_all_followers_and_strangers(person)
        strangers = Dict.get(result, :strangers, [])
        followers = Dict.get(result, :followers, [])
        people = Person.get_all
        people = Enum.reject(people, fn(p) ->
          Enum.find(person.friends, fn(x) ->
            p.id == x
          end) || person.id == p.id
        end)
        render conn, "index.html",
          board: board,
          person: person,
          following: following,
          followers: followers,
          strangers: strangers,
          people: people
    end      
  end
end
