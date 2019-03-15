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
    state = %State{floor: floor, direction: :stop, active_orders: {}}
    #active_orders = {}
    {:ok, state}
  end

  def initialized? do
    cond do
      is_atom(DriverInterface.get_floor_sensor_state DriverInterface) -> 
        initialized?()
      true ->
        DriverInterface.get_floor_sensor_state DriverInterface
    end
  end

  def handle_cast {:neworder, order}, state do 
    state = %{state | active_orders: order}

    direction = cond do
      order.floor > state.floor ->
        :up
      order.floor < state.floor -> 
        :down
      order.floor == state.floor ->
        :stop
    end
    state = %{state | direction: direction}
    #state = %{state | active_orders: Tuple.append(active_orders, order)}
    execute_order(state)
    {:noreply, state}
  end

  def handle_cast {:at_floor, floor}, state do
    state = %{state | floor: floor}
    execute_order(state)
    {:noreply, state}
  end

  def execute_order(state) do
    DriverInterface.set_motor_direction DriverInterface, state.direction
    if state.active_orders != {} do
      cond do
        elem(state.active_orders,0).floor == state.floor ->
          DriverInterface.set_motor_direction DriverInterface, :stop
      end
    else
      {:nothing}
    end
  end

end
