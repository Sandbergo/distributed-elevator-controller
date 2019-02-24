defmodule State do
    @valid_dirns [:up, :stop, :down]
    defstruct floor: 0, direction: :stop
    def state_machine(direction, floor) when direction in @valid_dirns do
        %State{floor: floor, direction: direction}
    end
end

defmodule Order do
    @valid_order [:hall_down, :cab, :hall_up]
    @floors [0, 1, 2, 3]
    defstruct [:type, :floor]
    def order(type, floor) when type in @valid_order and floor in @floors do
        %Order{type: type, floor: floor}
    end
end