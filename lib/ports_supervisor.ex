defmodule XGPS.Ports_supervisor do
  use Supervisor

  def start_port(port_name) do
    Supervisor.start_child(__MODULE__, [{port_name}])
  end

  def get_running_port_names do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn({_, pid, :supervisor, _}) -> pid end)
    |> Enum.map(fn(pid) -> XGPS.Port.Supervisor.get_port_name(pid) end)
  end

  def start_link do
    result = {:ok, pid} = Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    start_port_if_defined_in_config(pid)
    result
  end

  defp start_port_if_defined_in_config(pid) do
    case Application.get_env(:xgps, :port_to_start, :no_port_to_start) do
      :no_port_to_start ->
        :ok
      portname_with_args ->
        Supervisor.start_child(pid, [portname_with_args])
    end
  end

  def init(:ok) do
    children = [
      supervisor(XGPS.Port.Supervisor, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end
