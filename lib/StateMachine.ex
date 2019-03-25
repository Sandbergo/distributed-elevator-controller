defmodule StateMachine do
  @moduledoc """
  Module for the state of an individual elevator, for controlling the execution of orders,
  ensures own backup and makes sure lights are correct
  
  ### State: 
  * A struct consisting of a floor (the last floor), a direction (:up, :down, :stop) 
  and a list of active orders it has accepted
  
  ### Tasks:
  * Controlling the elevator
  * Executing orders

  ### Communication:
  * Sends to: DriverInterface, WatchDog, NetworkHandler
  * Receives from: OrderHandler, Poller
  """
  use GenServer

  @motorstop_timeout WatchDog.get_motorstop_timeout
  @door_open_timer 1000

  #--------------------------------INITIALIZATION---------------------------------#
  def start_link _mock do
    GenServer.start_link(__MODULE__, :down, [{:name, __MODULE__}])
  end

  @doc """
  Drive downwards to closest floor and initialize the state
  """
  def init(direction) do
    IO.puts "Statemachine init"
    start_motor_timer()
    Process.spawn(StateMachine, :initialize_to_floor, [self()], [])
    DriverInterface.set_motor_direction(DriverInterface, direction)
    state = receive do
      {:initialized, floor} ->
        DriverInterface.set_motor_direction(DriverInterface, :stop)
        stop_motor_timer()
        backup_state(State.state_machine(:stop, floor, []))
        State.state_machine(:stop, floor, [])
      after
        @motorstop_timeout+1000 ->
          IO.puts "Not able to initialize"
          :not_valid
    end
    {:ok, state}
  end

  def initialize_to_floor pid do
    cond do
      is_atom(DriverInterface.get_floor_sensor_state DriverInterface) ->
        initialize_to_floor(pid)
      true ->
        floor = DriverInterface.get_floor_sensor_state DriverInterface
        send(pid, {:initialized, floor})
    end
  end

  #---------------------------------CASTS/CALLS-----------------------------------#

  def delete_active_order(order) do
    GenServer.cast(OrderHandler, {:order_executed, order})
    GenServer.cast(StateMachine, {:order_executed, order})
  end

  def update_state_direction(direction) do
    GenServer.cast(StateMachine, {:update_direction, direction})
  end

  def start_motor_timer do
    GenServer.cast(WatchDog, {:elev_going_active})
  end

  def stop_motor_timer do
    GenServer.cast(WatchDog, {:elev_going_inactive})
  end

  def reset_motor_timer do
    GenServer.cast(WatchDog, {:floor_changed})
  end

  def backup_state(state) do
    GenServer.cast(WatchDog, {:backup, state})
  end

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
    IO.puts "length of active orders:"
    IO.inspect length(state.active_orders)
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
  update the direction state
  """
  def handle_cast({:update_direction, direction}, state) do
    state = %{state | direction: direction}
    backup_state(state)
    {:noreply, state}
  end

  def handle_call({:request_backup},_from, state) do
    {:reply, state, state}
  end


  #-------------------------------HELPER FUNCTIONS--------------------------------#

  @doc """
  function for controlling elevator direction based on orders 
  """
  def execute_order(state) do
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
  def execute_order_on_floor(state) do
    if should_stop?(state) do
      Process.send_after(self(), :doors_closed, @door_open_timer)
      DriverInterface.set_motor_direction(DriverInterface, :stop)
      DriverInterface.set_door_open_light(DriverInterface, :on)
      update_state_direction(:stop)
      receive do
        :doors_closed ->
          IO.puts "Doors closed"
          DriverInterface.set_door_open_light(DriverInterface, :off)
        after
          @door_open_timer*3 ->
            IO.puts "ERROR"
            GenServer.cast(NetworkHandler, {:error})
      end
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
  def should_stop?(state) do ## CLEANUP REQUIRED
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
  Opens and closes doors and sleeps for the duration
  """
  def open_doors(pid) do
    IO.puts "Opening doors"
    DriverInterface.set_door_open_light DriverInterface, :on
    DriverInterface.set_door_open_light DriverInterface, :off
    send(pid, :doors_closed)
  end

  @doc """
  Function courtesy of @Jostlowe
  """
  def order_type_to_int(elevator_order) do
    %{hall_up: 1, cab: 0, hall_down: -1}[elevator_order.type]
  end

  @doc """
  Function courtesy of @Jostlowe
  """
  def direction_to_int(elevator_state) do
    %{up: 1, stop: 0, down: -1}[elevator_state.direction]
  end

end

defmodule State do
  @moduledoc """
  A struct for the State of the elevator, direction and (last registered) floor
  Basis courtesy of @jostlowe, modified by us.
  """
  @valid_dirns [:up, :stop, :down]
  defstruct floor: 0, direction: :stop, active_orders: []
  
  def state_machine(direction, floor, active_orders) when direction in @valid_dirns do
      %State{floor: floor, direction: direction, active_orders: active_orders}
  end
  
  def get_valid_dirns do
      @valid_dirns
  end
end