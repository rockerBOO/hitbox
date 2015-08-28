defmodule Hitbox.ChatServer do
  def get_servers() do
    Hitbox.Client.get!("/chat/servers").body
  end

  def get_connection_id(nil) do
    throw "Error"
  end

  def get_connection_id(server) do
    HTTPoison.get!(server <> "/socket.io/1/").body
    |> String.split(":", parts: 2)
    |> List.first
  end

  def get_connection() do
    get_servers()
    |> Enum.find_value(fn server ->
      case get_connection_id(server["server_ip"]) do
        nil -> false
        id -> {server["server_ip"], id}
      end
    end)
  end
end