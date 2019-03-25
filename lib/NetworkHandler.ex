defmodule NetworkHandler do
  @moduledoc """
  Module for handling and setting up the Node Network, and communication between nodes

  ### State: 
  * A map with the connected nodes as keys and a backup of the node's elevator state as the respective value,
  as well as a boolean indicating whether the node is ready to receive orders
   The entire state for three connected nodes will look like this:
  %{
    "elev@10.100.23.197": [
      %State{active_orders: [], direction: :stop, floor: 0},
      true
    ],
    "elev@10.100.23.233": [
      %State{active_orders: [], direction: :stop, floor: 1},
      true
    ],
    "elev@10.100.23.253": [
      %State{active_orders: [], direction: :stop, floor: 1},
      true
    ]
  }

  ### Tasks: 
  * Initializes all modules for one computer, broadcasts own IP and listnes, making a Peer-to-peer network 
  of NetworkModules
  * Decides the recipient of Hall orders based on a cost function, considering number of orders and 
  distance to order.
  * Is responsible for restarting nodes and redistributing orders that are not executed by assigned elevator

  ### Communication: 
  * Receives from: OrderHandler, WatchDog, StateMachine, (other nodes') NetworkModule(s)
  * Sends to: OrderHandler,  (other nodes') NetworkModule(s)
  """
  use GenServer
  @receive_port 20086
  @broadcast_port 20087
  @broadcast_freq 5000
  @node_dead_time 6000
  @broadcast {192,168,1,255}#{10, 100, 23, 255}#{10,42,0,255} #{10, 100, 23, 255} # {10,24,31,255}
  @cookie :cookie

  def start_link([send_port, recv_port] \\ [@broadcast_port,@receive_port]) do
    GenServer.start_link(__MODULE__, [send_port, recv_port], [{:name, __MODULE__}])
  end

  @doc """
  Boot Node with name "elev@ip" and spawn listen and receive processes based on UDP broadcasting
  """
  def init([send_port, recv_port]) do
    IO.puts "Booting distributed node"
    name = "#{"elev@"}#{get_my_ip() |> ip_to_string()}"
    case Node.start(String.to_atom(name), :longnames, @node_dead_time) do
      {:error, reason} -> 
        IO.puts("Unable to start node")
      _ -> 
        IO.puts("Node boot successful")
    end
    Node.set_cookie(String.to_atom(name), @cookie)
    IO.puts "Opening sockets"
    case :gen_udp.open(send_port, [:list, {:active, false}, {:broadcast, true}]) do
      {:error, :eaddrinuse} ->
        IO.puts("Broadcast port already open: stopping node")
      {:ok, broadcast_socket} -> 
        IO.puts("Broadcast port successfully opened")
        Process.spawn(__MODULE__, :broadcast_self, [broadcast_socket, recv_port, name], [:link])
    end
    listen_socket = case :gen_udp.open(recv_port, [:list, {:active, false}]) do
      {:error, :eaddrinuse} ->
        IO.puts("Listen port already open: stopping node")
        Node.stop()
      {:ok, listen_socket} -> 
        IO.puts("Listen port successfully opened")
        Process.spawn(__MODULE__, :listen, [listen_socket, self()], [:link])
      end
    net_state = %{Node.self() => [%State{}, true]}
    IO.inspect net_state
    {:ok, net_state}
  end

  # -------------------------For driving 3 local elevator simulators ---------------#
  def start_link([send_port, recv_port, name]) do
    GenServer.start_link(__MODULE__, [send_port, recv_port, name], [{:name, __MODULE__}])
  end

  @doc """
  Alternative init for running on a single computer
  """
  def init [send_port, recv_port, name] do
    boot_node(name, @node_dead_time)
    Node.set_cookie(Node.self(), @cookie)

    {:ok, broadcast_socket} = :gen_udp.open(send_port, [:list, {:active, false}, {:broadcast, true}])
    
    Process.spawn(__MODULE__, :broadcast_local, [broadcast_socket, to_string(Node.self())], [:link])
    
    {:ok, listen_socket} = :gen_udp.open(recv_port, [:list, {:active, false}])
    
    Process.spawn(__MODULE__, :listen, [listen_socket, self()], [:link])
    net_state = %{Node.self() => [%State{}, true]}
    IO.inspect net_state
    {:ok, net_state}
  end
  
  def broadcast_local(socket, name) do
    :gen_udp.send(socket, @broadcast, 20087, name)
    :gen_udp.send(socket, @broadcast, 20089, name)
    :gen_udp.send(socket, @broadcast, 20091, name)
    :timer.sleep(@broadcast_freq)
    broadcast_local(socket, name)
  end
 
  #--------------------------Network functions and node connections----------------------------#
  @doc """
  Continously broadcasting own name with UDP
  """
  def broadcast_self(socket, recv_port, name) do
    :gen_udp.send(socket, @broadcast, recv_port, name)
    :timer.sleep(@broadcast_freq)
    broadcast_self(socket, recv_port, name)
  end

  #---------------------------------CASTS/CALLS-----------------------------------#

  def sync(ext_order_list) do
    GenServer.cast(OrderHandler, {:sync_order_list, ext_order_list})
  end

  #def single_elevator_mode() do
  #  GenServer.cast(NetworkHandler, {:lost_network})
  #end

  def monitor_me_back(node_name) do
    GenServer.multi_call([node_name], NetworkHandler, {:monitor_me_back, Node.self()}, 1000)
  end

  def export_order({:internal_order, order, _chosen_node}) do
    GenServer.cast NetworkHandler, {:internal_order, order}
  end

  def export_order({:external_order, order, chosen_node }) do
    GenServer.multi_call([chosen_node], NetworkHandler, {:external_order, order}, 1000)
  end

  def synchronize_order_lists(order_list) do
    GenServer.multi_call(Node.list(), NetworkHandler, {:sync_orders, order_list}, 1000)
  end

  def multi_call_update_backup(backup) do
    GenServer.multi_call(Node.list(), NetworkHandler, {:update_backup, backup, Node.self()}, 1000)
  end

  @doc """
  Get info about a node in  another node's state map
  """
  def multi_call_request_backup(from_node_name, about_node) do
    GenServer.multi_call([from_node_name], NetworkHandler, {:request_backup, about_node}, 1000)
  end

  #------------------------------HANDLE CASTS/CALLS-------------------------------#

  def handle_cast({:sync_order_lists, order_list}, net_state) do
    synchronize_order_lists(order_list)
    {:noreply, net_state}
  end

  def handle_cast({:send_state_backup, backup}, net_state)  do
    net_state = Map.put(net_state, Node.self(), [backup, true])
    multi_call_update_backup([backup, true])
    {:noreply, net_state}
  end

  def handle_call({:sync_orders, ext_order_list}, _from, net_state) do
    sync(ext_order_list)
    {:reply, net_state, net_state}

  end

  def handle_call({:request_order_rank, order}, _from, net_state) do
    my_order_rank = cost_function(net_state[Node.self()], order)
    {:reply, my_order_rank, net_state}
  end

  def handle_call({:request_backup, about_node}, _from, net_state) do
    IO.puts "Backup requested"
    about_node = to_string(about_node) |> String.to_atom()
    requested_state = case net_state[about_node] do 
      nil ->
        [%State{}, true]
      _ -> 
        net_state[about_node]
    end
    {:reply, requested_state, net_state}
  end

  
  def handle_cast({:sync_lights, order, light_state}, net_state) do ## CHANGE NAME
    GenServer.multi_call(Node.list(), NetworkHandler, {:sync_elev_lights, order, light_state}, 1000)
    {:noreply, net_state}
  end

  def handle_call({:sync_elev_lights, order, light_state}, _from, net_state) do
    DriverInterface.set_order_button_light(DriverInterface, order.type, order.floor, light_state)
    {:reply, net_state, net_state}
  end

  def handle_call({:monitor_me_back, node}, _from, net_state) do
    node_name = node
    |> to_string() 
    |> String.to_atom()
    Node.monitor(node_name, true)
    {:reply, net_state, net_state}
  end
  

  @doc """
  An elevator is chosen for the specific order, using the cost function
  """
  def handle_cast({:choose_elevator, order}, net_state) do
    IO.puts("find the right elevator for this order")
    
    #Retrieve best cost function
    IO.puts "Calculate best cost"
    best_cost = Enum.min_by(Map.values(net_state),
     fn(node_state) -> cost_function(node_state, order) end)

    #Find the node with this cost
    {chosen_node, _node_state} = List.keyfind(Map.to_list(net_state), best_cost, 1)

    if chosen_node == Node.self() do
        export_order({:internal_order, order, chosen_node})
    else
        export_order({:external_order, order, chosen_node})
    end
    {:noreply, net_state}
  end

  def handle_cast({:motorstop}, net_state) do
    IO.puts "RESTART REQUIRED"
    Node.stop()
    Process.exit(self(), :kill)
    {:noreply, net_state}
  end

  def handle_call({:update_backup, backup, from_node}, _from, net_state) do
    net_state = Map.put(net_state, from_node, backup)
    {:reply, net_state, net_state}
  end

  def handle_cast({:internal_order, order}, net_state) do
    OrderHandler.distribute_order(order, true)
    {:noreply, net_state}
  end

  def handle_call({:external_order, order}, _from, net_state) do
    OrderHandler.distribute_order(order, true)
    {:reply, net_state, net_state}
  end

  #-------------------------------HELPER FUNCTIONS--------------------------------#
   
  defp redistribute_orders(order_list) do
    Enum.each(order_list, fn(order) ->
      if order.type != :cab do
        export_order({:internal_order, order, Node.self()})
      end
    end)
  end

  defp cost_function(state, order) do
    IO.inspect state
    cost = if List.last(state) do
      length(List.first(state).active_orders) + abs(distance_to_order(order, List.first(state)))
    else
      100000
    end
  end

  defp distance_to_order(elevator_order, elevator_state) do
    elevator_order.floor - elevator_state.floor
  end

  def handle_info({:request_connection, node_name}, net_state) do
    if node_name not in ([Node.self | [:nonode@nohost | Node.list]]|> Enum.map(&(to_string(&1)))) do
      node_name = node_name |> String.to_atom()#IO.puts "connecting to node #{node_name}"
      
      Node.monitor(node_name, true) # monitor this newly connected node
      Node.ping(node_name)
      monitor_me_back(node_name)
      # request backup from newly connected node
      IO.puts "Checking information about #{node_name}"
      net_state = case net_state[node_name] do
        nil -> 
          IO.puts "No information available about #{node_name}"
          {requested_state, _ignored} = multi_call_request_backup(node_name, node_name)
          IO.puts "Requested state:"
          IO.inspect requested_state
          IO.puts "My current mapezo"
          IO.inspect Map.put(net_state, node_name, requested_state[node_name])
          Map.put(net_state, node_name, requested_state[node_name])
          # request info about node_name to own net_state
        _ ->
          IO.puts "Here you go"
          node_state = List.first(net_state[node_name])
          IO.inspect net_state[node_name]
          backup = Map.replace(net_state, node_name, [node_state, true])
          pid = Process.spawn(NetworkHandler, :recover_from_error_mode, [node_name, backup], [])
          Process.send_after(pid, :send_cab_orders, 3000)
          backup
      end
      multi_call_update_backup(net_state[Node.self()])
    end
    {:noreply, net_state}
  end
      
  def handle_info({:nodedown, node_name}, net_state) do
    net_state = case length(Node.list()) do
      0 -> 
        %{Node.self() => net_state[Node.self()]}
      _->
        IO.puts "Node down"
        node_state = List.first(net_state[node_name])
        
        net_state = Map.replace(net_state, node_name, [node_state, false])
    
        IO.puts "My current map: "
        IO.inspect net_state
    
        active_orders_of_node = node_state.active_orders
        redistribute_orders(active_orders_of_node)
        net_state
    end
    {:noreply, net_state}
  end

  def recover_from_error_mode(node_name, net_state) do
    receive do
      :send_cab_orders -> 
        active_orders_of_node = List.first(net_state[node_name]).active_orders
        IO.inspect active_orders_of_node
        Enum.each(active_orders_of_node, fn(order) -> 
          if order.type == :cab do
            export_order({:external_order, order, node_name})
          end
        end)
      :motorstop ->
        #Process.spawn(Overseer, :start_link, [20088,20089,20001,"elev2"], [])
      after
        10_000 ->
          IO.puts "Resend timeout"
    end
  end

  def listen(socket, network_handler_pid) do
    case :gen_udp.recv(socket, 0, 3*@broadcast_freq) do
      {:ok, {_ip,_port,node_name}} ->
        node_name = to_string(node_name)
        Process.send(network_handler_pid, {:request_connection, node_name}, [])
        listen(socket, network_handler_pid)
      {:error, reason} ->
        IO.inspect reason
        IO.puts "I am so lonely"
        listen(socket,network_handler_pid)
    end
  end

      @doc """
  Courtesy of @jostlowe
  Returns (hopefully) the ip address of your network interface.
  ## Examples
      iex> NetworkStuff.get_my_ip
      {10, 100, 23, 253}
  """
  defp get_my_ip do
    {:ok, socket} = :gen_udp.open(5678, [active: false, broadcast: true])
    :ok = :gen_udp.send(socket, @broadcast, 5678, "test packet")
    ip = case :gen_udp.recv(socket, 100, 1000) do
      {:ok, {ip, _port, _data}} -> ip
      {:error, _} -> {:error, :could_not_get_ip}
    end
    :gen_udp.close(socket)
    ip
  end

  @doc """
  Courtesy of @jostlowe
  formats an ip address on tuple format to a bytestring
  ## Examples
      iex> NetworkStuff.ip_to_string {10, 100, 23, 253}
      '10.100.23.253'
  """
  defp ip_to_string ip do
    :inet.ntoa(ip) |> to_string()
  end

end
