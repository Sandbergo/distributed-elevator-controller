defmodule StateMachine do
  @moduledoc """
  StateMachine module yayeet
  """
  use GenServer
  #------------------INIT-------------------#
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
  #-------------------Non-communicative functions-------------#
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
      IO.puts direction
      :timer.sleep 10
      executed?(state)
    else
      {:no_active_orders}
    end
  end

  def executed?(state) do
    if should_stop?(state) do
      DriverInterface.set_motor_direction DriverInterface, :stop
      open_doors()
      Enum.each(state.active_orders, fn(order)->
        if order.floor == state.floor do 
          IO.puts "Delete this bitch"
          delete_active_order(order)
        end
      end)
    end
  end

  def should_stop?(state) do 
    List.first(state.active_orders).floor == state.floor or 
    Enum.any?(state.active_orders, fn(other_order) ->
       other_order.floor == state.floor and
     (order_type_to_int(other_order) == direction_to_int(state) or 
     other_order.type == :cab) end)
  end

  def open_doors do
    # SET A STATE?
    #IO.puts "opnin doors"
    DriverInterface.set_door_open_light DriverInterface, :on
    :timer.sleep(1000)
    DriverInterface.set_door_open_light DriverInterface, :off
    true
    #IO.puts "closin doors"
  end

  #-------------------Cast and call functions-------------#

  def delete_active_order(order) do
    GenServer.cast(OrderHandler, {:order_executed, order})
    GenServer.cast(StateMachine, {:executed_order, order})
  end

  def update_state_direction(direction) do
    GenServer.cast(StateMachine, {:update_direction, direction})
  end

  #-------------------Handle cast and call functions-------------#
  
  def handle_cast {:neworder, order}, state do 
    state = %{state | active_orders: state.active_orders ++ [order]}
    DriverInterface.set_order_button_light(DriverInterface, order.type, order.floor, :on)
      if length(state.active_orders)==1 do
        execute_order(state)
      end
    {:noreply, state}
  end

  def handle_cast {:at_floor, floor}, state do
    state = %{state | floor: floor}
    execute_order(state)
    {:noreply, state}
  end

  def handle_cast {:executed_order, order}, state do
    IO.puts "Order deleted for StateMachine"
    state = %{state | active_orders: state.active_orders -- [order]}
    DriverInterface.set_order_button_light(DriverInterface, order.type, order.floor, :off)
    IO.inspect state
    execute_order(state) 
    {:noreply, state}
  end
  
  def handle_cast {:update_direction, direction}, state do
    state = %{state | direction: direction}
    {:noreply, state}
  end

  def handle_call {:request_backup},_from, state do
    {:reply, state, state}
  end


  #################BOILERPLATE#########################
  def order_type_to_int(elevator_order) do
    %{hall_up: 1, cab: 0, hall_down: -1}[elevator_order.type]
  end

  def direction_to_int(elevator_state) do
    %{up: 1, stop: 0, down: -1}[elevator_state.direction]
  end

end
