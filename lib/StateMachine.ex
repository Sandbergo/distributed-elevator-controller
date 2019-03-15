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
    state = %{state | active_orders: Tuple.append(state.active_orders, order)}
    execute_order(state)
    {:noreply, state}
  end

  def handle_cast {:at_floor, floor}, state do
    state = %{state | floor: floor}
    {:noreply, state}
  end

  def handle_cast {:executed_order}, state do
    IO.puts "Order deleted"
    state = %{state | active_orders: Tuple.delete_at(state.active_orders, 0)}
    IO.inspect state
    execute_order(state)
    {:noreply, state}
  end
  
  def handle_cast {:update_direction, direction}, state do
    state = %{state | direction: direction}
    {:noreply, state}
  end

  def delete_active_order do
    GenServer.cast(StateMachine, {:executed_order})
  end

  def update_state_direction(direction) do
    GenServer.cast(StateMachine, {:update_direction, direction})
  end



  def execute_order(state) do
    if state.active_orders != {} do
      order = elem(state.active_orders,0)
      #IO.inspect order
      direction = cond do
        order.floor == state.floor ->
          :stop
        order.floor > state.floor ->
          :up
        order.floor < state.floor ->
          :down
        true ->
          {:errore!}
      end
      DriverInterface.set_motor_direction(DriverInterface, direction)
      update_state_direction(direction)
      executed?(state, order)
    else
      {:no_active_orders}
    end
  end

  def executed?(state, order) do
    if order.floor == DriverInterface.get_floor_sensor_state(DriverInterface) do
      DriverInterface.set_motor_direction(DriverInterface, :stop)
      DriverInterface.set_door_open_light(DriverInterface, :on)
      delete_active_order()
    else 
      executed?(state, order)
    end
  end

end
