#clear 

# start server
pkill ElevatorServer
cd ~/Documents/gr25/TTK4145/ex5
ElevatorServer & disown

# compile
cd elevator 
mix compile

# run boy
#gnome-terminal -x 
mix run -e StateMachine.init
