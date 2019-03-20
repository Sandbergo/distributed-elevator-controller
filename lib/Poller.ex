defmodule Poller do
   @moduledoc """
    Poller module periodically checks buttons and floor sensors with two threads
    Sends messages to OrderHandler and StateMachine
    Has no state
    """
  use GenServer

  @floors Order.get_all_floors
  @button_types Order.get_valid_order

  def start_link do
    GenServer.start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  def init _mock do
    Enum.each(@floors, fn(floor) ->
      Enum.each(@button_types, fn(button_type)->
        GenServer.cast DriverInterface, {:set_order_button_light, button_type, floor, :off }
      end)
    end)
    Process.spawn(Poller, :floor_poller, [:between_floors], [:link])
    Process.spawn(Poller, :button_poller, [], [:link])
    {:ok, _mock}
  end

  def floor_poller floor do
    new_floor = DriverInterface.get_floor_sensor_state(DriverInterface)
    if new_floor != floor && new_floor != :between_floors do
      DriverInterface.set_floor_indicator(DriverInterface, new_floor)
      send_floor(new_floor)
    end
    floor_poller(new_floor)
  end

  def button_poller do
    Enum.each(@floors, fn(floor) ->
      Enum.each(@button_types, fn(button_type)->
        case DriverInterface.get_order_button_state(DriverInterface, floor, button_type) do
          1 ->
            set_order(floor, button_type)
            IO.puts "Noticed press: #{button_type} on floor: #{floor}"#Pass received message to OrderHandler
            :timer.sleep(100) # remove?
          0 ->
            {:no_orders}
        end
      end)
    end)
    button_poller()
  end

  def set_order floor, button_type do
    GenServer.cast OrderHandler, {:register_order, floor, button_type}
  end

  def send_floor floor do
    GenServer.cast StateMachine, {:at_floor, floor}
  end

  def test do
    DriverInterface.start()
    init([])
    StateMachine.start_link()
  end
end
