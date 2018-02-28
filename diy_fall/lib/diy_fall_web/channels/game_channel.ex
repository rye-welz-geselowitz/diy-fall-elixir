defmodule DiyFallWeb.GameChannel do
  use DiyFallWeb, :channel

  def join("games:"<>_code, _payload, socket) do
    {:ok, socket}
  end

  def handle_in("show", nil, socket) do
    {:reply, {:ok, %{"test" => []}}, socket}
  end

end
