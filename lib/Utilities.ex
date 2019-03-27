defmodule State do
  @moduledoc """
  A struct for the State of the elevator, direction and (last registered) floor
  Basis co urtesy of @jostlowe, modified by us.
  """
  @valid_dirns [:up, :stop, :down]
  defstruct floor: 0, direction: :stop, active_orders: []
    
  def state_machine(direction, floor, active_orders) when direction in @valid_dirns do
    %State{floor: floor, direction: direction, active_orders: active_orders}
  end
    
  def get_valid_dirns do
    @valid_dirns
  end

end

defmodule Order do
  @moduledoc """
  A struct for the orders handled, with a direction and a floor number.
  Basis courtesy of @jostlowe, modified by us
  """
  @valid_order [:hall_up, :hall_down, :cab]
  @floors [0, 1, 2, 3]
  defstruct [:type, :floor]

  def order(type, floor) when type in @valid_order and floor in @floors do
    %Order{type: type, floor: floor}
  end

  def get_valid_order do
    @valid_order
  end

  def get_all_floors do
    @floors
  end
end

