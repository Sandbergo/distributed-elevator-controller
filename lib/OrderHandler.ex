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
      #_top_floor = length(Order.get_all_floors)-1
      #_valid_orders = Order.get_valid_order
      order_list = []
      {:ok, order_list}
    end

    def handle_cast {:register_order, floor, button_type}, _order_list do
      new_order = %Order{type: button_type, floor: floor}
      if not Enum.member?(order_list, new_order) do 
        order_list ++ [new_order]
        distribute_order(new_order)
      end
      {:noreply, order_list}
    end

    def handle_cast {:order_executed, floor, button_type}, _order_list do
      {:noreply, order_list -- [%Order{type: button_type, floor:floor }]}
    end

    def distribute_order(order) do
      GenServer.cast StateMachine, {:neworder, order}

    end
  end
  
  def test do
    DriverInterface.start()
    start_link()
    Poller.start_link()
    StateMachine.start_link()
  end
