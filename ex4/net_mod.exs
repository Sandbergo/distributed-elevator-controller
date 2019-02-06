defmodule NetworkModule do
    @modeludoc """
    Peer-to-peer communication using elixir Node
    
        1. ssh into remote 
        2. ies --name nodename@10.100.23.000 local and remote
        2. Node.set_cookie :yeet local and remote
        3. Node.ping :"nodename@10.100.23.000"
        4. PID = Node.spawn_link :"nodename@10.100.23.000", fn -> NetworkModule ?????
        5. send pid, {string} ???
    
    """

    def init(queue) do
        {:ok, queue}
    end

    def start_link() do
        GenServer.start_link(__MODULE__, :queue.new())
    end


    def send() do

    end

    
    def receive() do
        receive do
            {string} ->        # something sent matches this datatype 
                IO.puts string
            end
        IO.puts "received something else"

    end
    
    def main() do
        IO.puts "Alive: ", Node.alive?(), "; List: ", Node.list() 

        receive()
    end
    


















    """
    get_IP() do
        {ok, Network_interfaces} = inet:getifaddrs(),
        case proplists:get_value("eno1", Network_interfaces, undefined) do
            undefined ->  # Non-Linux (personal computers)
                {ok, Addresses} = inet:getif() 			    # Undocumented function returning all local IPs
                inet_parse:ntoa(element(1, hd(Addresses)))  # Chooses the first IP and parses it to a string

            Interface do  % Linux (at realtime lab computers)
                IP_address = proplists:get_value(addr, Interface)
                inet_parse:ntoa(IP_address)
	end
    """


end
