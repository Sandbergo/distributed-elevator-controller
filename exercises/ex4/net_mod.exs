defmodule NetworkModule do
    @modeludoc """
    Peer-to-peer communication using elixir Node
    
        (1). ssh into remote 
            ssh student@IP
        2. iex --name nodename@10.100.23.000 local and remote
        2. Node.set_cookie :yeet local and remote
        3. Node.ping :"nodename@10.100.23.000"
            import_file "Documents/gr25/TTK4145/ex4/net_mod.exs"

        4. pid = Node.spawn(Node.self(), fn -> NetworkModule.main() end)
        5. send pid, "string"
    """

    def init(queue) do
        {:ok, queue}
    end

    def start_link() do
        GenServer.start_link(__MODULE__, :queue.new())
    end

    
    def receive_fun() do
        IO.puts "receive initiated"
        receive do
            string ->        # something sent matches this datatype 
                IO.puts "gotcha: #{string}"
                #receive_fun()
            end
        IO.puts "receive ended"
    end
    
    def main() do
        pid = self()
        IO.puts "online " #, Node.alive?(), "; List: ", Node.list() 

        receive_fun()
        IO.puts "exiting"
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
