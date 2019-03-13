defmodule StateMachine do
  @moduledoc """
  StateMachine module yayeet
  """
  use GenServer
  def start_link do
    GenServer.start_link(__MODULE__, :down, [{:name, __MODULE__}])
  end

  def init direction do
    DriverInterface.set_motor_direction(DriverInterface, direction)
    floor = initialized?()
    DriverInterface.set_motor_direction(DriverInterface, :stop)
    state = %State{floor: floor, direction: :stop}
    active_orders = {}
    {:ok, {state, active_orders}}
  end

  def initialized? do
    cond do
      is_atom(DriverInterface.get_floor_sensor_state DriverInterface) -> 
        initialized?()
      true ->
        DriverInterface.get_floor_sensor_state DriverInterface
    end
  end

  def handle_cast {:gotofloor, order}, state do 
    direction = cond do
      order.floor > state.floor ->
        direction = :up
      order.floor < state.floor -> 
        direction = :down
      order.floor == state.floor ->
        direction = :stop
    end
    state = %{state | direction: direction}
    execute_order(state, order)
    {:noreply, state}
  end

  def handle_cast {:at_floor, floor}, state do
    state = %{state | floor: floor}
    
    {:noreply, state}
  end

  def execute_order(state, order) do
    DriverInterface.set_motor_direction DriverInterface, state.direction
    if order.floor == state.floor do
      DriverInterface.set_motor_direction DriverInterface, :stop
    end
  end

end
