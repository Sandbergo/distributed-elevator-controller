defmodule Overseer do
  @moduledoc """
  A Supervisor that keeps track and restarts entire program upon request or crash, using the one_for_all
  strategy, as well as being the entry point for the entire program
    """
  use Supervisor
  @receive_port 20086
  @broadcast_port 20087

  def start_link() do
    Supervisor.start_link(__MODULE__, [@broadcast_port, @receive_port], name: __MODULE__)
  end

  @doc """
  Initialization starting all modules under a Supervisor with one_for_all strategy
  """
  def init([send_port, recv_port]) do
    Process.flag(:trap_exit,true)
    children = [
      {NetworkHandler, [send_port,recv_port]},
      DriverInterface,
      OrderHandler,
      Poller,
      WatchDog,
      StateMachine
    ]
    Supervisor.init(children, strategy: :one_for_all)
  end

  # ---------------------------LOCAL--------------------------------#
  def start_link(send_port, recv_port, elev_port, name) do
    Supervisor.start_link(__MODULE__, [send_port, recv_port, elev_port, name], name: __MODULE__)
  end

  def init [send_port, recv_port, elev_port, name] do
    Process.flag(:trap_exit,true)
    children = [
      {NetworkHandler, [send_port,recv_port, name]},
      {DriverInterface, [{127,0,0,1}, elev_port]},
      OrderHandler,
      Poller,
      WatchDog,
      StateMachine
    ]
    Supervisor.init(children, strategy: :one_for_all, max_restarts: 100)
  end

end