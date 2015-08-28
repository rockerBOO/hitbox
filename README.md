Hitbox
======

Hitbox REST API and Chat Client on Elixir

** Still in development, not ready for production use **

Most of the development so far is in the chat client.

### Chat
* Read Only debug mode so far

#### Usage

iex> {:ok, _} = Hitbox.Chat.start_link
iex> Hitbox.Chat.join("channel_name_here")

### REST API
* Very basic layer for the REST API

#### Usage

iex> Hitbox.Client.get!("/chat/servers")