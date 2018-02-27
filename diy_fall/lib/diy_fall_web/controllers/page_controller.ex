defmodule DiyFallWeb.PageController do
  use DiyFallWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
