defmodule StateMachine do
  @moduledoc """
  StateMachine module yayeet
  """
  

  def init do
    {:ok, pid} = DriverInterface.start
    DriverInterface.set_motor_direction pid, :up
    IO.puts("Initialized")
    pid
    #receive_loop pid
  end


  def receive_loop pid do
    IO.puts("Waiting for message")
    receive do
      {:at_floor, 1}->
        DriverInterface.set_motor_direction pid, :up
      {:at_floor, 3}->
        DriverInterface.set_motor_direction pid, :down
    end
    receive_loop pid 
  end

  def temp_main do
    elevator_pid = init
    receive_pid = spawn(StateMachine, :receive_loop, [elevator_pid])
    _poller_pid = spawn(Poller, :floor_poller, [elevator_pid, receive_pid])
  end
"""
  def drivin_loop pid do
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
"""
end
