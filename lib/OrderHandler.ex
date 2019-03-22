defmodule OrderHandler do
  @moduledoc """
  Module for receiving and handling orders form Poller and NetworkHandler and synchronizing orders
  
  ### State: 
  * A list of order structs, where the hall orders are shared between OrderHandlers and cab orders are module specific
  
  ### Tasks:
  * Keeps track of orders relevant for the specific node
  * Processes orders received from Poller and Network Handler

  ### Communication:
  * Sends to: StateMachine, NetworkHandler
  * Receives from: StateMachine, NetworkHandler, Poller
  """
  use GenServer
  
  #--------------------------------INITIALIZATION---------------------------------#
  def start_link do
    GenServer.start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  def init(order_list \\ []) do
    {:ok, order_list}
  end

  #---------------------------------CASTS/CALLS-----------------------------------#


  @doc """
  distribute order from Poller or NetworkHandler, sending hall orders to NetworkHandler if it has not been chosen
  and passing the other orders to own elevator

  """
  def distribute_order(order, chosen \\ false) do
    cond do
      order.type == :cab ->
        GenServer.cast(StateMachine, {:neworder, order})
      chosen ->
        IO.puts "I VOLUNTEER AS TRIBUTE"
        GenServer.cast(StateMachine, {:neworder, order})
      true -> 
        GenServer.cast(NetworkHandler, {:choose_elevator, order})
    end
  end

  def sync_order (order_list) do
    no_cab_order_list = Enum.reject(order_list, fn(order) -> order.type == :cab end)
    GenServer.cast(NetworkHandler, {:sync_order_lists, no_cab_order_list})
  end

  #------------------------------HANDLE CASTS/CALLS-------------------------------#

  def handle_cast({:register_order, floor, button_type}, order_list) do
    new_order = %Order{type: button_type, floor: floor}
    order_list = if not Enum.member?(order_list, new_order) do
      sync_order(order_list++[new_order])
      distribute_order(new_order)
      order_list ++ [new_order]
    else                 ## FJERN?
      order_list         ## FJERN?
    end
    IO.puts "Here is the order list"
    IO.inspect order_list
    {:noreply, order_list}
  end

  def handle_cast({:order_executed, order}, order_list) do
    order_list = Enum.reject(order_list, fn(other_order) -> other_order.floor == order.floor end)
    sync_order(order_list)  ## PEPELINE?
    {:noreply, order_list}
  end

  def handle_cast({:sync_order_list, ext_order_list}, order_list) do
    cab_orders = Enum.reject(order_list, fn(int_order)-> int_order.type != :cab end)
    order_list = ext_order_list ++ cab_orders ## PIPELINE?
    IO.inspect order_list
    {:noreply, order_list}
  end

end
