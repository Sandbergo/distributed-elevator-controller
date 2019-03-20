defmodule WatchDog do
  @moduledoc """
  WatchDog module yayeet
  """
  use GenServer
  @get_backup_freq 1000

  #-------------------INIT----------------#
  def start_link do
    GenServer.start_link(__MODULE__, [%State{}], [{:name, __MODULE__}])
  end

  def init overwatch do
    watchdog(overwatch)

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

  def watchdog_loop (time \\ 0) do
    receive do
      {:elev_going_inactive} ->
        IO.puts "stop watchin"
        Process.exit(self(), :kill)
      {:floors_changed} ->
        "changin floor in WatchDog"
      after
        5_000 -> {:motorstop}
    end
  end

  #--------------------------Handle casts/calls----------------------------#
  def handle_cast {:elev_going_active} do
    IO.puts "watch it boy"
    Process.spawn(WatchDog, :watchdog_loop, [0], [])
    {:noreply}
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
  