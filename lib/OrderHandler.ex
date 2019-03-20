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
  def distance_to_order(elevator_order, elevator_state) do
    elevator_order.floor - elevator_state.floor
  end
  #--------------------------Casts/calls----------------------------#
  def distribute_order(order) do
    if GenServer.call NetworkHandler, {:am_i_chosen?, order} do
      GenServer.cast StateMachine, {:neworder, order}
    end
  end

  def sync_order (order_list) do
    no_cab_order_list = Enum.reject(order_list, fn(order) -> order.type == :cab end)
    IO.puts "Synced orders"
    IO.inspect no_cab_order_list
    GenServer.cast NetworkHandler, {:sync_order_lists, no_cab_order_list}
  end
  #--------------------------Handle casts/calls----------------------------#

  def handle_cast {:register_order, floor, button_type}, order_list do
    new_order = %Order{type: button_type, floor: floor}
    order_list = if not Enum.member?(order_list, new_order) do
      IO.puts "order added in OrderHandler, order list is now "
      IO.inspect order_list++[new_order]
      sync_order (order_list++[new_order])
      distribute_order(new_order)
      order_list ++ [new_order]
    else
      order_list
    end
    {:noreply, order_list}
  end

  def handle_cast {:order_executed, order}, order_list do
    order_list = Enum.reject(order_list, fn(other_order) -> other_order.floor == order.floor end)
    IO.puts "order deleted in OrderHandler, order list is now:"
    IO.inspect order_list
    {:noreply, order_list}
  end

  def handle_cast {:sync_order_list, ext_order_list}, order_list do
    Enum.each(ext_order_list, fn(ext_order) ->
      if ext_order not in order_list do
        distribute_order(ext_order)
      end
    end)
    order_list = Enum.uniq(order_list ++ ext_order_list)
    {:noreply, order_list}
  end


end
