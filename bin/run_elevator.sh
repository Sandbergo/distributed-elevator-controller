#clear 

# start server
pkill ElevatorServer
cd ~/Documents/gr25/TTK4145
gnome-terminal -x ElevatorServer & disown

# compile
mix compile

# run boy

iex -S mix 