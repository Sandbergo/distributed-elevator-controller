defmodule StateMachine do
  @moduledoc """
  StateMachine module yayeet
  """
  use GenServer
  def start_link do
    GenServer.start_link(__MODULE__, :down, [{:name, __MODULE__}])
  end

  def init direction do
    DriverInterface.set_motor_direction DriverInterface, direction
    floor = initialized?()
    DriverInterface.set_motor_direction DriverInterface, :stop
    state = %State{floor: floor, direction: :stop, active_orders: []}
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
    state = %{state | active_orders: state.active_orders ++ [order]}
    GenServer.cast DriverInterface, {:set_order_button_light, order.type, order.floor, :on }
      if length(state.active_orders)==1 do
        execute_order(state)
      end
    {:noreply, state}
  end

  def handle_cast {:at_floor, floor}, state do
    state = %{state | floor: floor}
    #DriverInterface.set_floor_indicator DriverInterface, floor
    {:noreply, state}
  end

  def handle_cast {:executed_order, order}, state do
    IO.puts "Order deleted for StateMachine"
    state = %{state | active_orders: state.active_orders -- [order]}
    GenServer.cast(OrderHandler, {:order_executed, order}) # fix this boy
    GenServer.cast DriverInterface, {:set_order_button_light, order.type, order.floor, :off }
    IO.inspect state
    execute_order(state) 
    {:noreply, state}
  end
  
  def handle_cast {:update_direction, direction}, state do
    state = %{state | direction: direction}
    {:noreply, state}
  end

  def delete_active_order(order) do
    GenServer.cast(StateMachine, {:executed_order, order})
  end

  def update_state_direction(direction) do
    GenServer.cast(StateMachine, {:update_direction, direction})
  end


  def execute_order(state) do
    order = List.first(state.active_orders)
    if order != nil  do
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
      DriverInterface.set_motor_direction DriverInterface, direction
      update_state_direction(direction)
      executed?(state, order)
    else
      {:no_active_orders}
    end
  end

  def executed?(state, order) do
    if order.floor == DriverInterface.get_floor_sensor_state DriverInterface do
      DriverInterface.set_motor_direction DriverInterface, :stop
      #DriverInterface.set_door_open_light DriverInterface, :on
      open_doors()
      delete_active_order(order)
    else 
      executed?(state, order)
    end
  end

  def open_doors do
    # SET A STATE?
    #IO.puts "opnin doors"
    DriverInterface.set_door_open_light DriverInterface, :on
    :timer.sleep(1000)
    DriverInterface.set_door_open_light DriverInterface, :off
    #IO.puts "closin doors"
  end

end
