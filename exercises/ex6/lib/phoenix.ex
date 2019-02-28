defmodule Phoenix do
  @message_time 1000 #ms
  def counter i, state, pid do
    case state do
      :primary ->
        msg = {:number, i}
        send(pid, msg)
        IO.puts i
        IO.inspect self
        Process.sleep(@message_time)
        counter i+1, state, pid
      :backup ->
        receive do
          {:number, n} ->
            counter(n, state, pid)
          after
            4*@message_time ->
              pid = spawn(Phoenix, :counter, [i+1, :backup, self()])
              counter(i+1, :primary, pid)
        end
        _ -> {:noooo}
      end
  end
  def main do
    backup_pid = spawn(Phoenix, :counter, [0, :backup, self()])
    _primary_pid = spawn(Phoenix, :counter, [0, :primary, backup_pid])
  end
end
