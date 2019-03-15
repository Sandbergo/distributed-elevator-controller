defmodule OrderHandler do
    @moduledoc """
    OrderHandler module yayeet
    """
    #@order_matrix %{}
    use GenServer
    def start_link do
      GenServer.start_link(__MODULE__, [], [{:name, __MODULE__}])
    end
    
    def init _mock do
      _top_floor = length(Order.get_all_floors)-1
      _valid_orders = Order.get_valid_order
      order_matrix = {}
      {:ok, order_matrix}
    end

    def handle_cast {:register_order, floor, button_type}, _order_matrix do
      order_matrix = %Order{type: button_type, floor: floor}
      distribute_order(order_matrix)
      {:noreply, order_matrix}
    end


    def handle_cast {:order_executed, floor, button_type}, _order_matrix do
      
      #{:noreply}
    end

    def test do
      DriverInterface.start()
      start_link()
      Poller.start_link()
      StateMachine.start_link()
    end

    def distribute_order(order) do
      GenServer.cast StateMachine, {:neworder, order}
    end
  end
  