defmodule Starfish.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # For testing purposes
    # The GenServer is started in the test
    children =
      if Mix.env() == :test do
        []
      else
        [
          {Starfish.Server, []}
        ]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Starfish.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
