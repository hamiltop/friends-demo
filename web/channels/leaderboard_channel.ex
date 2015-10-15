defmodule Friends.LeaderboardChannel do
  use Phoenix.Channel

  def join("friends:leaderboard", _message, socket) do
    send self, :after_join
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    board = Friends.LeaderboardChangefeed.get || []
    push socket, "new_board", %{data: board}
    {:noreply, socket}
  end
end
