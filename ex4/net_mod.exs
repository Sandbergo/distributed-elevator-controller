# UDP, elixir Node, JSON, peer-to-peer


defmodule NetworkModule do

    def init(queue) do
        {:ok, queue}
    end


    def start_link() do
        GenServer.start_link(__MODULE__, :queue.new())
    end


    def send() do

    end

    
    def receive() do
        IO.puts "received"
    end
    
    def main() do
        IO.puts "Alive: ", Node.alive?(), "; List: ", Node.list() 
    end
    
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
    


end
