defmodule Poller do
  @moduledoc """
  Module for polling the DriverInterface to the hardware and passing the information
  
  ### State: 
  * No state
  
  ### Tasks:
  * Spawning two threads polling the floor sensor and button sensor, and passing these messages
  to the OrderHandler and StateMachine

  ### Communication:
  * Sends to: OrderHandler, StateMachine
  * Receives from:
  """
  use GenServer

  @floors Order.get_all_floors
  @button_types Order.get_valid_order

  def start_link _mock do
    GenServer.start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  @doc """
  Initialize by turning off all lights and spawning one process for button polling and one for floor polling
  """  
  def init _mock do 
    Enum.each(@floors, fn(floor) ->
      Enum.each(@button_types, fn(button_type)->
        GenServer.cast DriverInterface, {:set_order_button_light, button_type, floor, :off }
      end)
    end)
    DriverInterface.set_door_open_light(DriverInterface, :off)
    Process.spawn(Poller, :floor_poller, [:between_floors], [:link])
    Process.spawn(Poller, :button_poller, [], [:link])
    {:ok, _mock}
  end

  @doc """
  Loop and send when a new floor is reached 20 times per second
  """  
  defp floor_poller floor do
    new_floor = DriverInterface.get_floor_sensor_state(DriverInterface)
    if new_floor != floor && new_floor != :between_floors do
      DriverInterface.set_floor_indicator(DriverInterface, new_floor)
      send_floor(new_floor)
    end
    floor_poller(new_floor)
    :timer.sleep(50) 
  end

  @doc """
  Initialize by turning off all lights
  """  
  defp button_poller do
    Enum.each(@floors, fn(floor) ->
      Enum.each(@button_types, fn(button_type)->
        case DriverInterface.get_order_button_state(DriverInterface, floor, button_type) do
          1 ->
            set_order(floor, button_type)
            IO.puts "Noticed press: #{button_type} on floor: #{floor}"
            :timer.sleep(100)  ## DOUBLE SLEEP
          0 ->
            {:no_orders}
        end
      end)
    end)
    :timer.sleep(50) 
    button_poller()
  end

  @doc """
  Cast the registered order to the order Handler
  """  
  defp set_order floor, button_type do
    GenServer.cast OrderHandler, {:register_order, floor, button_type}
  end

  @doc """
  Cast the changed floor to the state machine
  """  
  defp send_floor floor do
    GenServer.cast StateMachine, {:at_floor, floor}
  end

end
