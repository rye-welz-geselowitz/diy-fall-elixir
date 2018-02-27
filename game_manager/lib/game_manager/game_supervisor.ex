defmodule GameManager.GameSupervisor do
  use DynamicSupervisor

  alias GameManager.{GameServer}

  #CLIENT
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_child(name) do
    spec = Supervisor.Spec.worker(GameServer, [name], restart: :transient)
    IO.inspect spec
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  #SERVER
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end



end
