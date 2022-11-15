defmodule Starfish.ServerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  alias Starfish.{Server, State}

  describe "init/1" do
    test "should connect to each others and schedule a ping" do
      state = %State{seniority: @seniority[Node.self()], leader: @default_leader}

      # TODO: I would like to test that the nodes are connected
      # or at least that the function to connect was called

      assert Server.init([]) == {:ok, %Starfish.State{leader: nil, seniority: 0}}
    end
  end

  describe "ping/1" do
    test "should declare itself the new leader" do
      output =
        capture_log(fn ->
          {:ok, pid} = Server.start_link([])
          send(pid, :ping)

          assert :sys.get_state(pid) == %Starfish.State{
                   leader: nil,
                   seniority: 0
                 }
        end)

      # TODO: I would like to test that the logs are sequential
      assert output =~ "[info] Init"
      assert output =~ "[info] Find new leader"
      assert output =~ "[info] Schedule ping"
      assert output =~ "[info] I am the king"
    end

    test "should schedule a ping" do
      output =
        capture_log(fn ->
          {:ok, _pid_leader} = Server.start_link(leader: :nodeX@localhost, name: :leader)
          {:ok, pid} = Server.start_link(leader: :nodeX@localhost, name: :slave)
          send(pid, :ping)

          assert :sys.get_state(pid) == %Starfish.State{
                   leader: :nodeX@localhost,
                   seniority: 0
                 }
        end)

      # TODO: I would like to test that the logs are sequential
      assert output =~ "[info] Init"
      assert output =~ "[info] Schedule ping"
      assert output =~ "[info] I am the king"
    end
  end
end
