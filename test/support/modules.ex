defmodule Registered.SupervisorUnderTest.WithoutUnique do
  use Registered.Process, as: {Supervisor, []}

  def init(test_pid: pid) do
    send(pid, {__MODULE__, :hello, self()})

    Supervisor.init([], strategy: :one_for_one)
  end
end

defmodule Registered.SupervisorUnderTest.WithUnique do
  use Registered.Process, as: {Supervisor, []}, unique: [:number]

  def init(opts) do
    opts
    |> Keyword.fetch!(:test_pid)
    |> send({__MODULE__, :hello, {self(), opts}})

    Supervisor.init([], strategy: :one_for_one)
  end
end
