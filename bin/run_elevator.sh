#clear 

# start server
pkill ElevatorServer # kill last instance of server
cd ~/Documents/gr25/TTK4145
gnome-terminal -x ElevatorServer & disown 

# compile
mix compile

# run boy
iex -S mix 
mix run -e OrderHandler.test