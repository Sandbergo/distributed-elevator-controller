defmodule StateMachine do
  @moduledoc """
  StateMachine module yayeet
  """
  

  def init do
    {:ok, pid} = DriverInterface.start
    DriverInterface.set_motor_direction pid, :up
    fsm_loop pid
  end

  def fsm_loop pid do
    case DriverInterface.get_floor_sensor_state(pid) do
      0->
      DriverInterface.set_motor_direction pid, :up
      3->
      DriverInterface.set_motor_direction pid, :down
      :between_floors -> IO.puts "Im drivin"
      _-> IO.puts "1"
    end
    fsm_loop pid 
  end
end
