defmodule OrderHandler do
    @moduledoc """
    OrderHandler module yayeet
    """
    use GenServer
    def start_link do
      GenServer.start_link(OrderHandler, [], [{:name, OrderHandler}])
    end
    
    def init all_orders do
      {:ok, all_orders}
    end

    defp register_order(order_message) do
    end

    def handle_cast {:register_order, floor, button_type}, all_orders do
      all_orders = all_orders++{floor,button_type}
      IO.puts "I am running"
      {:noreply, all_orders}
    end

    def test do
      {:ok, elev_pid} = DriverInterface.start
      poller_pid = spawn(Poller, :button_poller, [elev_pid])
      start_link
      test(0, [])
      #spawn(OrderHandler, :test, [1, []])
    end
    def test n, all_orders do
      IO.puts Enum.join(all_orders)
      all_orders = all_orders
      :timer.sleep(1000)
      test n+1, all_orders
    end
  end
  