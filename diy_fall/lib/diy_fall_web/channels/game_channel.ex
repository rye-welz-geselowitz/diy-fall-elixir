defmodule DiyFallWeb.GameChannel do
  use DiyFallWeb, :channel

  def join("games:test", _payload, socket) do
    IO.inspect "IM HERE!!!"
    {:ok, socket}
  end

  def handle_in("show", nil, socket) do
    IO.inspect "HI????"
    {:reply, {:ok, %{"test" => []}}, socket}
  end

end
