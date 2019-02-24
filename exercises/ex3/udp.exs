# Group 25


defmodule Receiver do
  require Logger

  def start(port) do
    spawn fn ->
      case :gen_udp.listen(port, [:binary, active: false, reuseaddr: true]) do
        {:ok, socket} ->
          Logger.info("Connected.")
          accept_connection(socket) # <--- We'll handle this next.
        {:error, reason} ->
          Logger.error("Could not listen: #{reason}")
      end
    end
  end


    def accept_connection(socket) do
    {:ok, client} = :gen_udp.accept(socket)
    spawn fn ->
        {:ok, buffer_pid} = Buffer.create() # <--- this is next
        Process.flag(:trap_exit, true)
        serve(client, buffer_pid) # <--- and then we'll cover this
    end
    #loop_accept(socket)
    end


    def serve(socket, buffer_pid) do
        case :gen_udp.recv(socket, 0) do
            {:ok, data} ->
            buffer_pid = maybe_recreate_buffer(buffer_pid) # <-- coming up next
            Buffer.receive(buffer_pid, data)
            serve(socket, buffer_pid)
            {:error, reason} ->
            Logger.info("Socket terminating: #{inspect reason}")
        end
    end


    def maybe_recreate_buffer(original_pid) do
        receive do
            {:EXIT, ^original_pid, _reason} ->
            {:ok, new_buffer_pid} = Buffer.create()
            new_buffer_pid
        after
            10 ->
            original_pid
        end
    end

end



