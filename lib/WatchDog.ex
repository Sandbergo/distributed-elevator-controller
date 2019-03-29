defmodule WatchDog do
  @moduledoc """
  Module for backing up the state of an individual elevator and updating the NetworkHandler when this state changes, 
  and sending a request to the NetworkHandler.
  If the elevator has become inactive for more than 5 seconds, e.g. because of a motor stop.
  
  ### State: 
  * No state
  
  ### Tasks:
  * Send elevator state info to NetworkHandler
  * Detect failiure to complete active orders for elevator

  ### Communication:
  * Sends to: NetworkHandler
  * Receives from: StateMachine
  """
  use GenServer
  @motorstop_timeout 5000

  #--------------------------------INITIALIZATION---------------------------------#
  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, [nil, %State{}], [{:name, __MODULE__}])
  end

  @doc """
  Initialize by sending backup
  """
  def init([overwatch, backup]) do
    backup = %{backup | floor: DriverInterface.get_floor_sensor_state(DriverInterface)}
    send_backup(backup)
    {:ok, [overwatch, backup]}
  end

  #-------------------------------HELPER FUNCTIONS--------------------------------#

  @doc """
  Will send an error message to NetworkHandler if it is initialized and receives no sign of life
  within a set time
  """
  defp watchdog_loop do
    receive do
      {:elev_going_inactive} ->
        Process.exit(self(), :normal)
      {:floor_changed} ->
        watchdog_loop()
      after
        @motorstop_timeout ->
        IO.puts("MOTORSTOP")
        send_motorstop()
    end
  end

  #------------------------------HANDLE CASTS/CALLS-------------------------------#
  @doc """
  Spawns a Watchdog process upon request
  """
  def handle_cast({:elev_going_active}, [overwatch, backup]) do
    overwatch = Process.spawn(WatchDog, :watchdog_loop, [], [])
    {:noreply, [overwatch, backup]}
  end
  
  @doc """
  Kills watchdog process upon request
  """
  def handle_cast({:elev_going_inactive}, [overwatch, backup]) do
    send(overwatch, {:elev_going_inactive})
    {:noreply, [overwatch, backup]}
  end
  
  @doc """
  Handles floorchange, meaning the elevator is not inactive
  """
  def handle_cast({:floor_changed}, [overwatch, backup]) do
    case overwatch do
      nil -> 
        IO.puts "you are dragging me, you sneaky bastard"
      _ -> 
        send(overwatch, {:floor_changed})
    end
    {:noreply, [overwatch, backup]}
  end

  @doc """
  Handles changes in elevator state, sending an updated backup
  """
  def handle_cast({:backup, state}, [overwatch, backup]) do
    backup = state
    send_backup(backup)
    {:noreply, [overwatch, backup]}
  end

  @doc """
  Handles a external override of backup state
  """
  def handle_cast({:backup_updated, ext_backup}, [overwatch, backup]) do
    backup = ext_backup;
    {:noreply, [overwatch, backup]}
  end
  
  #---------------------------------CASTS/CALLS-----------------------------------#

  @doc """
  Sends backup of coupled elevator to NetworkHandler 
  """
  def send_backup(backup) do
    GenServer.cast NetworkHandler, {:send_state_backup, backup}
  end

  @doc """
  Sends message about motor stop to NetworkHandler
  """
  def send_motorstop do
    GenServer.cast NetworkHandler, {:error}
  end
end
