defmodule NetworkHandler do
  @moduledoc """
  Module for handling and setting up the Node Network, and communication between nodes

  ### State: 
  * A map with the connected nodes as keys and a backup of the node's elevator state as the respective value,
  as well as a boolean indicating whether the node is ready to receive orders
   The entire state for three connected nodes will look like this:

   `
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
`
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
  @broadcast {10, 100, 23, 255}
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
        GenServer.cast(NetworkHandler, {:error})
      _ -> 
        IO.puts("Node boot successful")
    end
    Node.set_cookie(String.to_atom(name), @cookie)
    IO.puts "Opening sockets"
    case :gen_udp.open(send_port, [:list, {:active, false}, {:broadcast, true}]) do
      {:error, :eaddrinuse} ->
        IO.puts("Broadcast port already open: stopping node")
        GenServer.cast(NetworkHandler, {:error})
      {:ok, broadcast_socket} -> 
        IO.puts("Broadcast port successfully opened")
        Process.spawn(__MODULE__, :broadcast_self, [broadcast_socket, recv_port, name], [:link])
    end
    listen_socket = case :gen_udp.open(recv_port, [:list, {:active, false}]) do
      {:error, :eaddrinuse} ->
        IO.puts("Listen port already open: stopping node")
        GenServer.cast(NetworkHandler, {:error})
      {:ok, listen_socket} -> 
        IO.puts("Listen port successfully opened")
        Process.spawn(__MODULE__, :listen, [listen_socket, self()], [:link])
    end
    net_state = %{Node.self() => [%State{}, true]}
    {:ok, net_state}
  end

  @doc """
  Continously broadcasting own name with UDP
  """
  def broadcast_self(socket, recv_port, name) do
    :gen_udp.send(socket, @broadcast, recv_port, name)
    :timer.sleep(@broadcast_freq)
    broadcast_self(socket, recv_port, name)
  end

  #---------------------------------CASTS/CALLS-----------------------------------#

  @doc """
  Synchronize local order list with an external order list
  """
  def sync_order_list_internally(ext_order_list) do
    GenServer.cast(OrderHandler, {:sync_order_list, ext_order_list})
  end

  @doc """
  Set up two-way monitoring
  """
  def monitor_me_back(node_name) do
    GenServer.multi_call([node_name], NetworkHandler, {:monitor_me_back, Node.self()}, 1000)
  end

  @doc """
  Send assigned order to own node
  """
  def export_order({:internal_order, order, _chosen_node}) do
    GenServer.cast NetworkHandler, {:internal_order, order}
  end

  @doc """
  Toggle lights in own OrderHandler
  """
  def toggle_lights_internally(order, light_state) do
    GenServer.cast(OrderHandler, {:toggle_light, order, light_state})
  end

  @doc """
  Synchronize lights with other elevators
  """

  def toggle_lights_externally(order, light_state) do
    GenServer.multi_call(Node.list(), NetworkHandler, {:sync_elev_lights_internally, order, light_state})
  end

  @doc """
  Send assigned order to other node
  """
  def export_order({:external_order, order, chosen_node }) do
    GenServer.multi_call([chosen_node], NetworkHandler, {:external_order, order}, 1000)
  end

  @doc """
  Synchronize order lists between nodes
  """
  def synchronize_order_lists_externally(order_list) do
    GenServer.multi_call(Node.list(), NetworkHandler, {:sync_orders, order_list}, 1000)
  end

  
  @doc """
  Send own updated backup to all other nodes
  """
  def multi_call_update_backup(backup) do
    GenServer.multi_call(Node.list(), NetworkHandler, {:update_backup, backup, Node.self()}, 1000)
  end

  @doc """
  Get info about a node in another node's state map
  """
  def multi_call_request_backup(from_node_name, about_node) do
    GenServer.multi_call([from_node_name], NetworkHandler, {:request_backup, about_node}, 1000)
  end

  #------------------------------HANDLE CASTS/CALLS-------------------------------#

  @doc """
  Handle a newly received order list from OrderHandler to be synchronized
  """
  def handle_cast({:sync_order_lists, order_list}, net_state) do
    synchronize_order_lists_externally(order_list)
    {:noreply, net_state}
  end

  @doc """
  Handle a request from WatchDog to send backup by sending backup
  """
  def handle_cast({:send_state_backup, backup}, net_state)  do
    net_state = Map.put(net_state, Node.self(), [backup, true])
    multi_call_update_backup([backup, true])
    {:noreply, net_state}
  end

  @doc """
  Handle a request from other nodes to synchronize orders
  """
  def handle_call({:sync_orders, ext_order_list}, _from, net_state) do
    sync_order_list_internally(ext_order_list)
    {:reply, net_state, net_state}
  end

  @doc """
  Handle a request for the backup of state information about a particular node 
  """
  def handle_call({:request_backup, about_node}, _from, net_state) do
    IO.puts "Backup requested"
    about_node = to_string(about_node) |> String.to_atom()
    IO.puts "this is the requested state:"
    IO.inspect net_state[about_node]
    requested_state = case net_state[about_node] do 
      nil ->
        [State.state_machine(:stop, 0, []), true]
      _ -> 
        net_state[about_node]
    end
    IO.inspect requested_state
    {:reply, requested_state, net_state}
  end
  
  @doc """
  Handle a request to synchronize the lights externally
  """  
  def handle_cast({:sync_elev_lights_externally, order, light_state}, net_state) do
    toggle_lights_externally(order, light_state)
    {:noreply, net_state}
  end

  @doc """
  Handle a request to synchronize the lights from external node
  """  
  def handle_call({:sync_elev_lights_internally, order, light_state}, _from, net_state) do
    toggle_lights_internally(order, light_state)
    {:reply, net_state, net_state}
  end

  @doc """
  Handle a request to monitor a node back
  """  
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

  @doc """
  Handle an error by exiting and thus provoking a restart by the Supervisor
  """  
  def handle_cast({:error}, net_state) do
    IO.puts "RESTART REQUIRED"
    Node.stop()
    Process.exit(self(), :kill)
    {:noreply, net_state}
  end

  @doc """
  Handle a request to update own backup about another node
  Illustration
  My_backup --> external_backup
  """
  def handle_call({:update_backup, backup, from_node}, _from, net_state) do
    net_state = Map.put(net_state, from_node, backup)
    IO.puts "Updating my backup"
    IO.inspect net_state
    {:reply, net_state, net_state}
  end

  @doc """
  Alternative init for running on a single computer
  """
  def handle_cast({:internal_order, order}, net_state) do
    OrderHandler.distribute_order(order, true)
    {:noreply, net_state}
  end

  @doc """
  Handle call for receiving a order from external node to be assigned to own state machine
  """
  def handle_call({:external_order, order}, _from, net_state) do
    OrderHandler.distribute_order(order, true)
    {:reply, net_state, net_state}
  end

  def handle_cast {:transmit_backup, backup, name}, net_state do
    from_node = name |> to_string() |> String.to_atom()
    net_state = Map.put(net_state, from_node, backup)
    {:noreply, net_state}
  end

  #-------------------------------HELPER FUNCTIONS--------------------------------#
   
  @doc """
  Iterate through an order list and send all orders to own state machine
  """
  defp redistribute_orders(order_list) do
    Enum.each(order_list, fn(order) ->
      if order.type != :cab do
        export_order({:internal_order, order, Node.self()})
      end
    end)
  end

  @doc """
  Cost function for assigning a cost for an elevator to execute an order,
  considering both the distance to the order and the number of orders already assigned
  """
  defp cost_function(state, order) when state != :not_valid do
    IO.inspect state
    if List.last(state) do
      3*length(List.first(state).active_orders) + abs(distance_to_order(order, List.first(state)))
    else
      100000
    end
  end

  @doc """
  Calculates the distance to the order
  Example
    iex> distance_to_order(%Order{floor: 1, type: hall_up}, %State{floor: 3, direction: :up, active_orders: []})
    2
  """
  defp distance_to_order(elevator_order, elevator_state) do
    elevator_order.floor - elevator_state.floor
  end

  @doc """
  Handle info for a requested connection message, requesting information about the net_state from other node, or 
  sending this information when the other node has no information
  """
  def handle_info({:request_connection, node_name}, net_state) do
    IO.puts "Node #{node_name} trying to connect to me"
    if node_name not in ([Node.self | [:nonode@nohost | Node.list]]|> Enum.map(&(to_string(&1)))) do
      node_name = node_name |> String.to_atom()#IO.puts "connecting to node #{node_name}"
      
      case Node.ping(node_name) do
        :pong -> 
          IO.puts "Successful connection"
        :pang -> 
          IO.puts "Error in node connection"
      end
      Node.monitor(node_name, true) # monitor this newly connected node
      monitor_me_back(node_name)
      # request backup from newly connected node
      IO.puts "Checking information about #{node_name}"
      net_state = case net_state[node_name] do
        nil -> 
          IO.puts "No information available about #{node_name}, we have not been connected since restart"
          {requested_state, _ignored} = multi_call_request_backup(node_name, node_name)
          IO.puts "Requested state:"
          IO.inspect requested_state
          IO.puts "My current mapezo"
          IO.inspect Map.put(net_state, node_name, requested_state[node_name])
          Map.put(net_state, node_name, requested_state[node_name])
          # request info about node_name to own net_state
        _ ->
          IO.puts "I have info about this node, set availability to true"
          node_state = List.first(net_state[node_name])
          backup = Map.replace(net_state, node_name, [node_state, true])
          pid = Process.spawn(NetworkHandler, :recover_from_error_mode, [node_name, backup], [])
          Process.send_after(pid, :resend_cab_orders, 3000)
          backup
      end
    end
    Enum.each(Node.list, fn(node) -> GenServer.cast({NetworkHandler, node}, {:transmit_backup, net_state[Node.self()], Node.self()})end)
    {:noreply, net_state}
  end

  @doc """
  Handle event of node going down.
  """      
  def handle_info({:nodedown, node_name}, net_state) do
    net_state = case length(Node.list()) do
      0 -> 
        IO.puts "Single elevator mode activated"
        %{Node.self() => net_state[Node.self()]}
      _->
        IO.puts "Node down"
        net_state = case net_state[node_name] do
          nil ->
            Map.put(net_state, node_name, [State.state_machine(0, :stop, []), false])
          _ ->
            net_state
        end
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

  @doc """
  Process to be spawned for delaying error recovery. 
  Example
    iex> pid = Process.spawn(NetworkHandler, :recover_from_error_mode, [node_name, net_state], [])
    iex> Process.send_after(pid, :resend_cab_orders, 3000) 
  """
  def recover_from_error_mode(node_name, net_state) do
    receive do
      :resend_cab_orders -> 
        active_orders_of_node = List.first(net_state[node_name]).active_orders
        IO.inspect active_orders_of_node
        Enum.each(active_orders_of_node, fn(order) -> 
          if order.type == :cab do
            export_order({:external_order, order, node_name})
          end
        end)
      after
        10_000 ->
          IO.puts "Resend timeout"
    end
  end

  @doc """
  Continously listen for messages broadcasted, request connection to the node with the name
  received
  """  
  def listen(socket, network_handler_pid) do
    case :gen_udp.recv(socket, 0, 3*@broadcast_freq) do
      {:ok, {_ip,_port,node_name}} ->
        node_name = to_string(node_name)
        Process.send(network_handler_pid, {:request_connection, node_name}, [])
        listen(socket, network_handler_pid)
      {:error, reason} ->
        IO.inspect reason
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
