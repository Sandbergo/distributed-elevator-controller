defmodule NetworkHandler do
  @moduledoc """
  NetworkHandler module. Broadcast own IP and set up p2p node cluster
  """
  use GenServer
  @receive_port 20086
  @broadcast_port 20087
  @broadcast_freq 5000
  @offline_sleep 5000
  @listen_timeout 2000
  @node_dead_time 6000
  @cookie :penis

  def start_link [send_port, recv_port] \\ [@broadcast_port,@receive_port] do
    GenServer.start_link(__MODULE__, [send_port, recv_port], [{:name, __MODULE__}])
  end

  def init [send_port, recv_port] do
    IO.puts "NetworkHandler init"
    {:ok, broadcast_socket} = :gen_udp.open(send_port, [:list, {:active, false}, {:broadcast, true}])
    name = "#{"elev@"}#{get_my_ip() |> ip_to_string()}"
    Node.start(String.to_atom(name), :longnames, @node_dead_time)
    Node.set_cookie(String.to_atom(name), @cookie)
    Process.spawn(__MODULE__, :broadcast_self, [broadcast_socket, recv_port, name], [:link])
    {:ok, listen_socket} = :gen_udp.open(recv_port, [:list, {:active, false}])
    Process.spawn(__MODULE__, :listen, [listen_socket, self()], [:link])
    {:ok, name}
  end

  def broadcast_self(socket, recv_port, name) do
    IO.puts "broadcasting to my dudes"
    broadcast_address = {10, 100, 23, 255}
    :gen_udp.send(socket, broadcast_address, recv_port, name)
    :timer.sleep(@broadcast_freq)
    broadcast_self(socket, recv_port, name)
  end

  def handle_info({:request_connection, node_name}, state) do
    if node_name not in ([Node.self|Node.list]|> Enum.map(&(to_string(&1)))) do
      IO.puts "connecting to node {node_name}"
      Node.ping(String.to_atom(node_name))
    end
    IO.inspect Node.list
    {:noreply, state}
  end


  def listen(socket, network_handler_pid) do
    IO.puts "STOP, collaborate and listen"
    case :gen_udp.recv(socket, 0, 3*@broadcast_freq) do
      {:ok, {_ip,_port,node_name}} ->
        IO.puts "Receiving: #{node_name}"
        node_name = to_string(node_name)
        Process.send(network_handler_pid, {:request_connection, node_name}, [])
        listen(socket, network_handler_pid)
      {:error, reason} ->
        IO.inspect reason
        #Reset node?
    end
  end


  def handle_cast {:sync_order_lists, order_list}, node_list do
    GenServer.multi_call(Node.list(), NetworkHandler, {:sync_orders, order_list}, 1000)
    {:noreply, node_list}
    #multicast
  end

  def handle_call {:sync_orders, ext_order_list}, _from, state do
    sync(ext_order_list)
    {:reply, state, state}

  end

  def sync(ext_order_list) do
    GenServer.cast(OrderHandler, {:sync_order_list, ext_order_list})
  end

  def test do
    IO.puts "Leggo my eggo"
    DriverInterface.start()
    OrderHandler.start_link()
    Poller.start_link()
    StateMachine.start_link()
    NetworkHandler.start_link()
  end


    ############################----BOILERPLATE----#######################


      @doc """
  Returns (hopefully) the ip address of your network interface.
  ## Examples
      iex> NetworkStuff.get_my_ip
      {10, 100, 23, 253}
  """

  def get_my_ip do
    IO.puts "get IP"
    {:ok, socket} = :gen_udp.open(5678, [active: false, broadcast: true])
    :ok = :gen_udp.send(socket, {10, 100, 23, 255}, 5678, "test packet")
    ip = case :gen_udp.recv(socket, 100, 1000) do
      {:ok, {ip, _port, _data}} -> ip
      {:error, _} -> {:error, :could_not_get_ip}
    end
    :gen_udp.close(socket)
    IO.inspect ip
    ip
  end


  @doc """
  formats an ip address on tuple format to a bytestring
  ## Examples
      iex> NetworkStuff.ip_to_string {10, 100, 23, 253}
      '10.100.23.253'
  """

  def ip_to_string ip do
    :inet.ntoa(ip) |> to_string()
  end


  @doc """
  Returns all nodes in the current cluster. Returns a list of nodes or an error message
  ## Examples
      iex> NetworkStuff.all_nodes
      [:'heis@10.100.23.253', :'heis@10.100.23.226']
      iex> NetworkStuff.all_nodes
      {:error, :node_not_running}
  """

  def all_nodes do
    case [Node.self | Node.list] do
      [:nonode@nohost] -> {:error, :node_not_running}
      nodes -> nodes
    end
  end


  @doc """
  boots a node with a specified tick time. node_name sets the node name before @. The IP-address is
  automatically imported
      iex> NetworkStuff.boot_node "frank"
      {:ok, #PID<0.12.2>}
      iex(frank@10.100.23.253)> _
  """

  def boot_node(node_name, tick_time \\ 15000) do
    ip = get_my_ip() |> ip_to_string()
    full_name = node_name <> "@" <> ip
    Node.start(String.to_atom(full_name), :longnames, tick_time)
  end

end
