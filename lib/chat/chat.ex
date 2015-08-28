defmodule Hitbox.Chat do
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: Hitbox.Chat)
  end

  def connect(server, path) do
    Logger.debug "#{server}/#{path}"

    Socket.Web.connect!(server, [:active, path: path])
  end

  def connect! do
    {server, connection_id} = Hitbox.ChatServer.get_connection()

    socket = connect(server, "/socket.io/1/websocket/#{connection_id}")

    case socket |> Socket.Web.recv!() do
      {:text, "1::"} -> socket
      _ -> throw "Could not connect to the websocket"
    end
  end

  def test do
    connect!() |> Socket.Web.recv!()
  end

  def init([]) do
    {:ok, [socket: connect!()]}
  end

  def join(channel) do
    Hitbox.Chat |> GenServer.call({:join, channel})
  end



  def parse_text(input) do
    text = String.slice(input, 4, 1500)

    case String.length(text) do
      0 -> %{}
      _ -> Poison.decode!(text) |> render_args |> parse_message
    end
  end

  def render_args(map) do
    args = map["args"] |> Poison.decode!()

    Map.put(map, "args", args)
  end

  def chat_msg(params) do
    channel    = params["channel"]
    name       = params["name"]
    msg        = params["text"]

    Logger.debug "#{channel} #{name} #{msg}"
  end

  def poll_msg(params) do
# %{"args" => %{"method" => "pollMsg",
#     "params" => %{"channel" => "efragtv",
#       "choices" => [%{"text" => "UK", "votes" => "206"},
#        %{"text" => "Moldova", "votes" => "130"}], "clientID" => nil,
#       "followerOnly" => false, "nameColor" => "2EA3C3",
#       "question" => "Who's going to win?",
#       "start_time" => "2015-08-28T14:36:27.647Z", "status" => "started",
#       "subscriberOnly" => false, "votes" => 336}}, "name" => "message"}

    question   = params["question"]
    votes      = params["votes"]
    choices    = params["choices"]
    start_time = params["start_time"]

    Logger.debug "#{question} #{votes} #{start_time}"
  end

  def motd_msg(params) do
# %{"args" => %{"method" => "motdMsg",
#     "params" => %{"channel" => "efragtv",
#       "image" => "/static/img/channel/efragtv_53c05eafc460a_small.jpg",
#       "name" => "efragtv", "nameColor" => "2EA3C3",
#       "text" => "[World Championships 2015 European Qualifier]\n\n• UK vs Moldova (Best of Three)\n- Map 1: Dust2 [UK map choice] - UK won: 16:10\n- Map 2: Mirage [Moldova map choice]\n- Map 3: Inferno [Decider]\n\nBe sure to enter our knife giveaway at: tinyurl.com/q9o7v3z",
#       "time" => 1440775356}}, "name" => "message"}

    channel = params["channel"]
    image = params["image"]
    motd = params["text"]

    Logger.debug "#{channel} #{motd}"
  end

  def parse_message(message) do
    # msg_name   = message["name"]
    args       = message["args"]
    msg_params = args["params"]
    method     = args["method"]

    case method do
      "chatMsg" -> chat_msg(msg_params)
      "pollMsg" -> poll_msg(msg_params)
      "motdMsg" -> motd_msg(msg_params)
      _         -> IO.inspect message
    end
  end

  def pong(socket) do
    Logger.debug "Pong"

    socket |> Socket.Web.send!({:text, "2::"})
  end

def handle_call({:join, channel}, _from, state) do
    loginMessage = %{
      "name" => "message",
      "args" => [
        %{
          "method" => "joinChannel",
          "params" => %{
            "channel" => channel,
            "name" => "UnknownSoldier",
            "token" => nil,
            "isAdmin" => false
          }
        }
      ]
    }

    message = "5:::" <> Poison.encode!(loginMessage)

    socket = Keyword.get(state, :socket)

    socket |> Socket.Web.send!({:text, message})

    resp = case socket |> Socket.Web.recv!() do
      {:text, "2::"} -> :ok
      _ -> {:error, "Could not connect to the channel."}
    end

    Keyword.get(state, :socket)
    |> Socket.Web.recv!()
    |> IO.inspect

    Hitbox.Chat |> GenServer.cast(:listen)

    {:reply, resp, state}
  end

  def handle_cast(:listen, state) do
    socket = Keyword.get(state, :socket)

    case socket |> Socket.Web.recv!() do
      {:text, "2::"} -> socket |> pong()
      {:text, text} -> parse_text(text) |> IO.inspect
      _ -> throw "Not a proper message"
    end

    Hitbox.Chat |> GenServer.cast(:listen)

    {:noreply, state}
  end
end
