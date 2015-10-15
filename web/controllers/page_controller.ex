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
        person = Person.get(id, Friends.Database)
        following = Person.get_all_following(person)
        result = Person.get_all_followers_and_strangers(person)
        strangers = Dict.get(result, :strangers, [])
        followers = Dict.get(result, :followers, [])
        render conn, "index.html",
          board: board,
          person: person,
          following: following,
          followers: followers,
          strangers: strangers
    end      
  end
end
