defmodule Chat do
  use Agent

  @moduledoc "The store, based on `Agent`."

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  # @doc "Gets a value"
  # @spec get(String.t) :: Map.t
  # def get(key) do
  #   Agent.get(__MODULE__, &Map.get(&1, key))
  # end
  def messages do
    Agent.get(__MODULE__, & &1)
  end

  @doc "Puts a value"
  # @spec put(String.t, {String.t, any}) :: Map.t
  def put(message) do
    Agent.update(__MODULE__, fn list -> [message | list] end)
    # more sophisticated implementation,
    # possibly based on `Agent.get_and_update/3`
  end
end
