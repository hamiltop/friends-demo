defmodule Friends.FollowerChannel do
  use Phoenix.Channel

  alias Friends.Person
  require Logger

  def join("friends:follower", %{"id" => id}, socket) do
    {:ok, _} = Friends.FollowersChangefeedSup.start_child(Friends.Database, self, id)
    {:ok, _} = Friends.PersonChangefeedSup.start_child(Friends.Database, self, id)
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
