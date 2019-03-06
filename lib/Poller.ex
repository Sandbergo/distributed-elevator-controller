defmodule Poller do
   @moduledoc """
    Poller module periodically checks buttons and floor sensors
    Sends messages to OrderHandler and StateMachine
    """
  

  def floor_poller elevator_pid do
    case DriverInterface.get_floor_sensor_state elevator_pid do
      :between_floors ->
        :timer.sleep(100)
        floor_poller elevator_pid
      floor -> 
        floor_msg = {:at_floor, floor}
        send(state_machine_pid, floor_msg)
        :timer.sleep(100)
        floor_poller elevator_pid
    end
  end

end