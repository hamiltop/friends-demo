defmodule Friends.ChangefeedSup do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def init(:ok) do
    children = [
      worker(
        Friends.LeaderboardChangefeed,
        [Friends.Database, [name: Friends.LeaderboardChangefeed]]
      ),
      worker(
        Friends.PeopleChangefeed,
        [Friends.Database, [name: Friends.PeopleChangefeed]]
      ),
      supervisor(Friends.PersonChangefeedSup, []),
      supervisor(Friends.FollowersChangefeedSup, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
