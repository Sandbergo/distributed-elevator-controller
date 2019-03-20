#clear 
epmd -daemon # fix erlang issue

# start server
pkill SimElevatorServer # kill last instance of server
cd simulator
gnome-terminal -x ./SimElevatorServer  & disown 
cd ..
# compile
mix compile

# run boy
iex -S mix run -e NetworkHandler.test