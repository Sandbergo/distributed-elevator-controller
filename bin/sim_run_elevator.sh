#clear 
epmd -daemon # fix erlang issue

# start server
pkill ElevatorServer # kill last instance of server
cd ~/Documents/gr25/TTK4145
./../simulator/SimElavatorServer
gnome-terminal -x ~/.cargo/bin/ElevatorServer  & disown 


# compile
mix compile

# run boy
iex -S mix run -e NetworkHandler.test