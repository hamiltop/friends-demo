defmodule Friends.DatabaseSup do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def init(:ok) do
    children = [
      worker(Friends.Database, []),
      supervisor(Friends.ChangefeedSup, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
