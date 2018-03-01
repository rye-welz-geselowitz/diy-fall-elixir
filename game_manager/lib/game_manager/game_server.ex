defmodule GameManager.GameServer do
  use GenServer

  #CLIENT
  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def initiate_game(pid) do
    GenServer.call(pid, :initiate)
  end

  #SERVER
  def init(_) do
    {:ok, %{is_active: false}}
  end

  def handle_call(:initiate, _from, state) do
    new_state = %{state | is_active: true}
    {:reply, new_state, new_state}
  end

  defp via_tuple(name), do: {:via, Registry, {Registry.GameServer, name}}
end
