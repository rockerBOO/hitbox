defmodule Hitbox.Client do
  use HTTPoison.Base

  def process_url(url) do
    "http://api.hitbox.tv/" <> url
  end

  def process_response_body(body) do
    body |> Poison.decode!()
  end
end