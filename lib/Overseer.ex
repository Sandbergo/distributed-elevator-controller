
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
        {DriverInterface, [{127,0,0,1}, 15657]},
        OrderHandler,
        Poller,
        WatchDog,
        StateMachine
      ]
      Supervisor.init(children, strategy: :one_for_all)
    end
  
    @doc """
    Entry point for running entire program, starts Overseer which subsequently starts all other modules
    """
    def main do
      Overseer.start_link()
      loop()
    end
  
    @doc """
    loop to keep executable running
    """
    def loop do
      :timer.sleep(10000)
      loop
    end
  
  end