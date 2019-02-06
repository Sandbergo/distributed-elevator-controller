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
    
end