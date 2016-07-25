defmodule XGPS.Port.Supervisor do
  use Supervisor

  def get_gps_data(supervisor_pid) do
    [{_, reader_pid, _, _}] = Supervisor.which_children(supervisor_pid)
    XGPS.Port.Reader.get_gps_data(reader_pid)
  end

  def get_port_name(supervisor_pid) do
    [{_, reader_pid, _, _}] = Supervisor.which_children(supervisor_pid)
    XGPS.Port.Reader.get_port_name(reader_pid)
  end

  def send_simulated_data(supervisor_pid, sentence) do
    [{_, reader_pid, _, _}] = Supervisor.which_children(supervisor_pid)
    send reader_pid, {:nerves_uart, :simulate, sentence}
    send reader_pid, {:nerves_uart, :simulate, "\r"}
    send reader_pid, {:nerves_uart, :simulate, "\n"}
  end

  def send_simulated_position(supervisor_pid, lat, lon, alt) do
    now = DateTime.utc_now()
    {rmc, gga} = XGPS.Tools.generate_rmc_and_gga_for_simulation(lat, lon, alt, now)
    send_simulated_data(supervisor_pid, rmc)
    send_simulated_data(supervisor_pid, gga)
  end

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    children = [
      worker(XGPS.Port.Reader, [args], restart: :transient)
    ]
    supervise(children, strategy: :one_for_one)
  end
end
