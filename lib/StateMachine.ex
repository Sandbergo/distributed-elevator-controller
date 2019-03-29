defmodule StateMachine do
  @moduledoc """
  Module for the state of an individual elevator, for controlling the execution of orders,
  ensures own backup and makes sure lights are correct
  
  ### State: 
  * A struct consisting of a floor (the last floor), a direction (:up, :down, :stop) 
  and a list of active orders it has accepted:
  `%State{active_orders: [], direction: :stop, floor: 1}`
  
  ### Tasks:
  * Controlling the elevator motor
  * Executing orders

  ### Communication:
  * Sends to: DriverInterface, WatchDog, NetworkHandler
  * Receives from: OrderHandler, Poller
  """
  use GenServer
  @door_open_timer 1000
  #--------------------------------INITIALIZATION---------------------------------#
  
  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, :down, [{:name, __MODULE__}])
  end

  @doc """
  Drive downwards to closest floor and initialize the state
  """
  def init(direction) do
    start_motor_timer()
    DriverInterface.set_motor_direction(DriverInterface, direction)
    floor = initialize_to_floor()
    DriverInterface.set_motor_direction(DriverInterface, :stop)
    state = %State{floor: floor, direction: :stop, active_orders: []}
    stop_motor_timer()
    {:ok, state}
  end

  @doc """
  Loops and drives downwards until it hits a floor
  """
  def initialize_to_floor do
    cond do
      is_atom(DriverInterface.get_floor_sensor_state DriverInterface) ->
        initialize_to_floor()
      true ->
        DriverInterface.get_floor_sensor_state DriverInterface
    end
  end

  #---------------------------------CASTS/CALLS-----------------------------------#

  @doc """
  Delete an executed order in OrderHandler and StateMachine
  """
  def delete_active_order(order) do
    GenServer.cast(OrderHandler, {:order_executed, order})
    GenServer.cast(StateMachine, {:order_executed, order})
  end

  @doc """
  Update the direction state
  """
  def update_state_direction(direction) do
    GenServer.cast(StateMachine, {:update_direction, direction})
  end

  @doc """
  Start a timer for the motor
  """
  def start_motor_timer do
    GenServer.cast(WatchDog, {:elev_going_active})
  end

  @doc """
  Stop the timer
  """
  def stop_motor_timer do
    GenServer.cast(WatchDog, {:elev_going_inactive})
  end

  @doc """
  Reset the timer
  """
  def reset_motor_timer do
    GenServer.cast(WatchDog, {:floor_changed})
  end

  @doc """
  Request the state being backed up 
  """
  def backup_state(state) do
    GenServer.cast(WatchDog, {:backup, state})
  end

  @doc """
  Synchronize non-cab lights with other nodes through NetworkHandler
  """
  def sync_order_lights(order, light_state) do
    if order.type != :cab do
      GenServer.cast(NetworkHandler, {:sync_lights, order, light_state})
    end
  end

  #------------------------------HANDLE CASTS/CALLS-------------------------------#

  @doc """
  A new order is accepted, the light is set and in case this is the first order, is executed directly
  """
  def handle_cast({:neworder, order}, state) do
    IO.puts "new order"
    IO.inspect order
    state = %{state | active_orders: state.active_orders ++ [order]}
    backup_state(state)
    sync_order_lights(order, :on)
    DriverInterface.set_order_button_light(DriverInterface, order.type, order.floor, :on)
    if length(state.active_orders)==1 do
      start_motor_timer()
      execute_order(state)
    end
    {:noreply, state}
  end

  @doc """
  A new floor is reached, change state and reset motorstop timer
  """
  def handle_cast({:at_floor, floor}, state) do
    state = %{state | floor: floor}
    backup_state(state)
    reset_motor_timer()
    execute_order_on_floor(state)
    {:noreply, state}
  end

  @doc """
  A order is executed, turn lights off and communicate this to other modules
  """
  def handle_cast({:order_executed, order}, state) do
    state = %{state | active_orders: Enum.reject(state.active_orders, fn(order) -> order.floor == state.floor end)}
    backup_state(state)
    sync_order_lights(order, :off)
    DriverInterface.set_order_button_light(DriverInterface, order.type, order.floor, :off)
    execute_order(state)
    {:noreply, state}
  end

  @doc """
  Update the direction state
  """
  def handle_cast({:update_direction, direction}, state) do
    state = %{state | direction: direction}
    backup_state(state)
    {:noreply, state}
  end

  @doc """
  Update the direction state
  """
  def handle_call({:request_backup},_from, state) do
    {:reply, state, state}
  end


  #-------------------------------HELPER FUNCTIONS--------------------------------#

  @doc """
  Function for controlling elevator direction, executed when a floor is reached
  """
  defp execute_order(state) do
    order = List.first(state.active_orders)
    if order != nil  do
      direction = cond do
        order.floor == state.floor ->
          execute_order_on_floor(state)
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
    else
      stop_motor_timer()
      {:no_active_orders}
    end
  end

  @doc """
  When on a floor, execute the order if the elevator should stop
  """
  defp execute_order_on_floor(state) do
    if should_stop?(state) do
      DriverInterface.set_motor_direction(DriverInterface, :stop)
      update_state_direction(:stop)
      open_doors
      Enum.each(state.active_orders, fn(order)->
        if order.floor == state.floor do
          delete_active_order(order)
        end
      end)
    end
  end

  @doc """
  Logic for deciding whether the elevator should stop at that specific floor
  """
  defp should_stop?(state) do
    cond do
      state.direction == :stop ->
        true
      Enum.any?(state.active_orders, fn(other_order) ->
      other_order.floor == state.floor and
      (order_type_to_int(other_order) == direction_to_int(state) or
      other_order.type == :cab) end) ->
        true
      Enum.any?(state.active_orders, fn(other_order) ->
      other_order.floor == state.floor + direction_to_int(state) end) ->
        false
      Enum.any?(state.active_orders, fn(other_order) ->
      other_order.floor == state.floor end) ->
        true
      true ->
        false
    end
  end

  @doc """
  Logic for deciding whether the elevator should stop at that specific floor
  """
  defp open_doors() do
    DriverInterface.set_door_open_light DriverInterface, :on
    Process.send_after(self(), :close_doors, @door_open_timer)
    receive do
      :close_doors ->
        :continue
    end
    DriverInterface.set_door_open_light DriverInterface, :off
  end

  @doc """
  Turns an order type to an int
  """
  defp order_type_to_int(elevator_order) do
    %{hall_up: 1, cab: 0, hall_down: -1}[elevator_order.type]
  end

  @doc """
  Turns a direction into an int
  """
  defp direction_to_int(elevator_state) do
    %{up: 1, stop: 0, down: -1}[elevator_state.direction]
  end

end
