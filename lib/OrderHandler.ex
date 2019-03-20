defmodule OrderHandler do
  @moduledoc """
  OrderHandler module, gets orders from Poller and saves them, sends/receives with StateMachine
  state is an order list, but no identical orders are saved
  """
  #@order_list %{}
  use GenServer
  #--------------------------INIT----------------------------#
  def start_link do
    GenServer.start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  def init order_list do
    #_top_floor = length(Order.get_all_floors)-1
    #_valid_orders = Order.get_valid_order
    {:ok, order_list}
  end
  #--------------------------Non-communicative functions----------------------------#

  #--------------------------Casts/calls----------------------------#
  def distribute_order(order) do
    cond do
      order.type == :cab ->
        GenServer.cast StateMachine, {:neworder, order}
      GenServer.call NetworkHandler, {:am_i_chosen?, order} ->
        IO.puts "I VOLUNTEER AS TRIBUTE"
        GenServer.cast StateMachine, {:neworder, order}
      true -> "Prim must die >:("
    end
  end

  def sync_order (order_list) do
    no_cab_order_list = Enum.reject(order_list, fn(order) -> order.type == :cab end)
    GenServer.cast NetworkHandler, {:sync_order_lists, no_cab_order_list}
  end
  #--------------------------Handle casts/calls----------------------------#

  def handle_cast {:register_order, floor, button_type}, order_list do
    new_order = %Order{type: button_type, floor: floor}
    order_list = if not Enum.member?(order_list, new_order) do
      sync_order(order_list++[new_order])
      distribute_order(new_order)
      order_list ++ [new_order]
    else
      order_list
    end
    IO.puts "Here is the order list"
    IO.inspect order_list
    {:noreply, order_list}
  end

  def handle_cast {:order_executed, order}, order_list do
    order_list = Enum.reject(order_list, fn(other_order) -> other_order.floor == order.floor end)
    sync_order(order_list)
    {:noreply, order_list}
  end

  def handle_cast {:sync_order_list, ext_order_list}, order_list do
    cab_orders = Enum.reject(order_list, fn(int_order)-> int_order.type != :cab end)
    Enum.each(ext_order_list, fn(ext_order) ->
      if ext_order not in order_list do
        distribute_order(ext_order)
      end
      order_list = ext_order_list ++ cab_orders
    end)
    {:noreply, order_list}
  end


end
