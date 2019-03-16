defmodule OrderHandler do
  @moduledoc """
  OrderHandler module, gets orders from Poller and saves them, sends/receives with StateMachine
  state is an order list, but no identical orders are saved
  """
  #@order_list %{}
  use GenServer
  def start_link do
    GenServer.start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  def init order_list \\ [] do
    {:ok, order_list}
  end

  def handle_cast {:register_order, floor, button_type}, order_list do
    new_order = %Order{type: button_type, floor: floor}
    if not Enum.member?(order_list, new_order) do
      order_list = order_list ++ [new_order]
      IO.puts "order added in OrderHandler, order list is now:"
      IO.inspect order_list
      distribute_order(new_order)
    end
    {:noreply, order_list}
  end

  def handle_cast {:order_executed, order}, order_list do
    IO.puts "order deleted in OrderHandler, order list is now:"
    IO.inspect order_list --[order]
    {:noreply, order_list --[order]}
  end

  def distribute_order(order) do
    GenServer.cast StateMachine, {:neworder, order}

  end

end
