defmodule Poller do
   @moduledoc """
    Poller module periodically checks buttons and floor sensors
    Sends messages to OrderHandler and StateMachine
    """
  @floors Order.get_all_floors
  @button_types Order.get_valid_order
  def floor_poller elevator_pid, state_machine_pid do
    case DriverInterface.get_floor_sensor_state elevator_pid do
      :between_floors ->
        :timer.sleep(100)
        floor_poller elevator_pid, state_machine_pid
      floor -> 
        floor_msg = {:at_floor, floor}
        send(state_machine_pid, floor_msg)
        :timer.sleep(100)
        floor_poller elevator_pid, state_machine_pid
    end
  end

  def button_poller elevator_pid do
    Enum.each(@floors, fn(floor) ->
      Enum.each(@button_types, fn(button_type)->
        case DriverInterface.get_order_button_state(elevator_pid, floor, button_type) do
          1 ->
            set_order(floor, button_type)
            IO.puts "Noticed press: #{button_type} on floor: #{floor}"#Pass received message to OrderHandler
            :timer.sleep(100)
          0 ->
            {:no_orders}
        end
      end)
    end)
    button_poller(elevator_pid)
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

  def test do
    {:ok, pid} = DriverInterface.start();
    button_poller(pid)
  end
end