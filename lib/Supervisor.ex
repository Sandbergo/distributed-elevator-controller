defmodule Overseer do
    @moduledoc """
    Keeps track and restarts entire program upon request or crash
    """
    use Supervisor

    def start_link() do
        Supervisor.start_link(__MODULE__, [], name: __MODULE__)
    end
    
    def init(_mock) do
        children = [
            {NetworkHandler, [20087,20086]},
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
                Supervisor.restart_children(NetworkHandler)
        end
    end
end