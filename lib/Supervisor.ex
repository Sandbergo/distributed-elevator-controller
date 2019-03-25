defmodule Overseer do
    @moduledoc """
    Keeps track and restarts entire program upon request or crash
    """
    use Supervisor
    @receive_port 20086
    @broadcast_port 20087

    def start_link() do
        Supervisor.start_link(__MODULE__, [@broadcast_port, @receive_port], name: __MODULE__)
    end
    
    def init([send_port, recv_port]) do
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
    def test do
        {:ok, pid} = start_link()
        receive do
            :restart ->
                Supervisor.restart_child(Overseer, NetworkHandler)
        end
    end
    # -------------------LOCAL --------------------------------#
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
        Supervisor.init(children, strategy: :one_for_all)
    end

end