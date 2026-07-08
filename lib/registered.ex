defmodule Registered do
  use Supervisor

  @moduledoc """
  Documentation for `Registered`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Registered.hello()
      :world

  """
  def start_link(opts) do
    opts = Keyword.merge([name: Registered.Registry], opts)

    name = opts |> Keyword.fetch!(:name) |> Module.concat(Supervisor)

    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl Supervisor
  def init(opts) do
    Supervisor.init(
      [{Registered.Registry, opts}],
      strategy: :one_for_one
    )
  end
end
