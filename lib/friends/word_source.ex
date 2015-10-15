defmodule Friends.WordSource do
  def start_link(opts \\ []) do
    opts = Dict.put_new(opts, :name, __MODULE__)
    Agent.start_link(__MODULE__, :build_word_list, [], opts)
  end

  def build_word_list do
    :random.seed(:erlang.phash2([node()]),
                :erlang.monotonic_time(),
                :erlang.unique_integer())
    File.stream!("/usr/share/dict/words") |> Stream.filter(fn (el) ->
      String.length(el) > 6  && String.length(el) < 8
    end) |> Stream.map(&String.strip/1) |> Enum.to_list
  end

  def two_random(agent \\ __MODULE__) do
    Agent.get(agent, Enum, :take_random, [2])
  end

  def random_name do
    two_random |> Stream.map(fn(el) ->
      {first, rest} = String.split_at(el, 1)
      String.upcase(first) <> rest
    end) |> Enum.join(" ")
  end
end
