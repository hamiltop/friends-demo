defmodule Friends.PersonChannel do
  use Phoenix.Channel

  intercept ["new_world"]

  alias Friends.Person
  require Logger

  def join("friends:person", %{"id" => id}, socket) do
    {:ok, pid} = Friends.FollowersChangefeedSup.start_child(Friends.Database, self, id)
    Process.link(pid)
    {:ok, pid} = Friends.PersonChangefeedSup.start_child(Friends.Database, self, id)
    Process.link(pid)
    person = Person.get(id)
    {:ok, assign(socket, :person, person)}
  end

  def handle_in("unfollow", %{"id" => id}, socket) do
    person = socket.assigns[:person]
    person = Person.remove_follower(person, id)
    {:noreply, assign(socket, :person, person)}
  end

  def handle_in("follow", %{"id" => id}, socket) do
    person = socket.assigns[:person]
    person = Person.add_follower(person, id)
    {:noreply, assign(socket, :person, person)}
  end

  def handle_out("new_world", %{data: people}, socket) do
    person = socket.assigns[:person]
    friends = person.friends
    people = Enum.reject(people, fn (p) ->
      Enum.find(friends, fn (x) ->
        x == p["id"]
      end)
    end) |> Enum.map(fn (p) ->
      Dict.take(p, ["id", "name"])
    end) || person.id == p["id"]
    push socket, "new_world", %{data: people}
    {:noreply, socket}
  end

  def handle_info({:new_follower, p}, socket) do
    push socket, "new_follower", %{data: %{name: p["name"]}}
    {:noreply, socket}
  end
  def handle_info({:lost_follower, p}, socket) do
    push socket, "lost_follower", %{data: %{name: p["name"]}}
    {:noreply, socket}
  end
  def handle_info({:new_person_val, person}, socket) do
    friends = Person.get_all_following(person)
    push socket, "new_following", %{data: friends}
    {:noreply, assign(socket, :person, person)}
  end
end
