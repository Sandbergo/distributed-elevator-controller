defmodule Poller do
   @moduledoc """
    Poller module periodically checks buttons and floor sensors
    Sends messages to OrderHandler and StateMachine
    """
  use GenServer

  @floors Order.get_all_floors
  @button_types Order.get_valid_order
  
  def start_link do
    GenServer.start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  def init _mock do
    IO.puts "Leggo"
    Process.spawn(Poller, :floor_poller, [], [:link])
    Process.spawn(Poller, :button_poller, [], [:link])
    {:ok, _mock}
  end
  
  def floor_poller do
    case DriverInterface.get_floor_sensor_state DriverInterface do
      :between_floors ->
        :timer.sleep(100)
      floor -> 
        send_floor(floor)
        :timer.sleep(100)
    end
    floor_poller
  end

  def button_poller do
    Enum.each(@floors, fn(floor) ->
      Enum.each(@button_types, fn(button_type)->
        case DriverInterface.get_order_button_state(DriverInterface, floor, button_type) do
          1 ->
            set_order(floor, button_type)
            IO.puts "Noticed press: #{button_type} on floor: #{floor}"#Pass received message to OrderHandler
            :timer.sleep(1000)
          0 ->
            {:no_orders}
        end
      end)
    end)
    button_poller
  end

  def register_button_press state, floor, button_type do
    case state do
      
    :new_press ->
      set_order(floor, button_type)
      register_button_press(:transient, floor, button_type)
    :transient ->
      IO.puts "still pressin eh?"
    _-> 
    end
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