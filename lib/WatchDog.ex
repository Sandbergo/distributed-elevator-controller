defmodule WatchDog do
  @moduledoc """
  WatchDog module yayeet
  """
  use GenServer
  @get_backup_freq 1000

  #-------------------INIT----------------#
  def start_link do
    GenServer.start_link(__MODULE__, [nil], [{:name, __MODULE__}])
  end

  def init overwatch do
    #watchdog(overwatch)
    {:ok, overwatch}
  end

  #-------------------Non-communicative functions----------------#

  def watchdog overwatch do
    case check_conditions() do
      false -> 
        overwatch = request_state_backup()
        #IO.puts "Backup of state"
        #IO.inspect overwatch
        :timer.sleep(@get_backup_freq)
      true ->
        send_backup(overwatch)
    end
    watchdog(overwatch)
  end

  def watchdog_loop() do
    receive do
      {:elev_going_inactive} ->
        IO.puts "stop watchin"
        Process.exit(self(), :kill)
      {:floor_changed} ->
        IO.puts "changin floor in WatchDog"
        watchdog_loop()
      after
        5_000 ->
        IO.puts("MOTORSTOP")
        send_motorstop()
    end
  end

  #--------------------------Handle casts/calls----------------------------#
  def handle_cast {:elev_going_active}, state do
    IO.puts "watch it boy"
    state = Process.spawn(WatchDog, :watchdog_loop, [], [])
    {:noreply, state}
  end
  
  def handle_cast {:elev_going_inactive}, state do
    send(state, {:elev_going_inactive})
    state = nil
    {:noreply, state}
  end
  
  def handle_cast {:floor_changed}, state do
    send(state, {:floor_changed})
    {:noreply, state}
  end
  
  
  #-------------------Cast and call functions----------------#
  def check_conditions do
    false
  end

  def request_state_backup() do
    overwatch = GenServer.call StateMachine, {:request_backup}
    send_backup(overwatch)
    overwatch
  end

  def send_backup(backup) do
    GenServer.cast NetworkHandler, {:send_state_backup, backup}
  end
end
  