defmodule DiyFallWeb.GameChannel do
  use DiyFallWeb, :channel
  alias GameManager.{GameSupervisor, GameServer}

  def join("games:"<>code, player_name, socket) do
    _ =
      case GameServer.find_existing_game(code) do
        nil ->
          GameSupervisor.start_child(code)
        _ ->
          0
      end
      GameServer.add_player(code, player_name)
      send(self, :after_join)
      {:ok, assign(socket, :player_name, player_name)}
  end

  def terminate(_, socket) do
    "games:"<>code = socket.topic
    GameServer.remove_player(code, socket.assigns.player_name)
    state = GameServer.get_state(code)
    broadcast! socket, "update_game_data", %{}
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    ("games:"<>code) = socket.topic
     case GameServer.get_game_data(code, socket.assigns.player_name) do
       nil ->
         push socket, "game_in_session", %{}
       _ ->
         push socket, "update_game_data", %{}
         broadcast! socket, "update_game_data", %{}
      end
     {:noreply, socket}
   end

  def handle_in("initiate", _, socket) do
    ("games:"<>code) = socket.topic
    GameServer.initiate_game(code)
    data = GameServer.get_game_data(code, socket.assigns.player_name)
    broadcast! socket, "update_game_data", %{}
    {:reply, {:ok, data}, socket}
  end

  def handle_in("request_game_data", _, socket) do
    ("games:"<>code) = socket.topic
    data = GameServer.get_game_data(code, socket.assigns.player_name)
    {:reply, {:ok, data}, socket}
  end
end
