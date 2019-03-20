defmodule WatchDog do
  @moduledoc """
  WatchDog module yayeet
  """
  use GenServer
  @motorstop_timeout 5000

  #-------------------INIT----------------#
  def start_link do
    GenServer.start_link(__MODULE__, [nil, %State{}], [{:name, __MODULE__}])
  end

  def init [overwatch, backup] do
    backup = %{backup | floor: DriverInterface.get_floor_sensor_state(DriverInterface)}
    send_backup(backup)
    {:ok, [overwatch, backup]}
  end

  #-------------------Non-communicative functions----------------#

  def watchdog_loop() do
    receive do
      {:elev_going_inactive} ->
        IO.puts "stop watchin"
        Process.exit(self(), :kill)
      {:floor_changed} ->
        IO.puts "changin floor in WatchDog"
        watchdog_loop()
      after
        @motorstop_timeout ->
        IO.puts("MOTORSTOP")
        send_motorstop()
    end
  end

  #--------------------------Handle casts/calls----------------------------#
  def handle_cast {:elev_going_active}, [overwatch, backup] do
    IO.puts "watch it boy"
    overwatch = Process.spawn(WatchDog, :watchdog_loop, [], [])
    {:noreply, [overwatch, backup]}
  end
  
  def handle_cast {:elev_going_inactive}, [overwatch, backup] do
    send(overwatch, {:elev_going_inactive})
    overwatch = nil
    {:noreply, [overwatch, backup]}
  end
  
  def handle_cast {:floor_changed}, [overwatch, backup] do
    send(overwatch, {:floor_changed})
    {:noreply, [overwatch, backup]}
  end

  def handle_cast {:backup, state}, [overwatch, backup] do
    backup = state
    send_backup(backup)
    {:noreply, [overwatch, backup]}
  end
  
  
  #-------------------Cast and call functions----------------#
  def check_conditions do
    false
  end

  def send_backup(backup) do
    GenServer.cast NetworkHandler, {:send_state_backup, backup}
  end

  def send_motorstop() do
    GenServer.cast NetworkHandler, {:motorstop}
  end
end

  