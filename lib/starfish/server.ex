defmodule Starfish.Server do
  @moduledoc """
  This module is responsible for the election of the leader.

  ## Monitoring the current leader

  Once every @t_seconds, each node sends a :ping message to the leader,
  if the leader does not respond within the 4 × @t_seconds,
  he is considered retired and the current node begins the election of a new leader.

  ## Election of a new leader

  All nodes know each other's addresses and ports. There are 3 nodes in the network,
  new nodes can be added in @all_nodes

  Nodes have unique IDs and are sorted by their seniority.

  3 kinds of messages: :alive?, :fine_thanks and :i_am_the_king.

  The node that started the election sends an :alive? message to all nodes more senior than itself.
  And waits for :fine_thanks response.

  If no node responds with :fine_thanks within @t_seconds, the node declares itself the leader
  and sends out an :i_am_the_king message.
  If the node has received a :fine_thanks response, it waits for T seconds for an :i_am_the_king message.
  If it doesn't wait, it starts the election procedure again.
  When receiving ALIVE? the node responds with :fine_thanks and starts a new election itself.

  if received :alive? Since the node is already the most senior,
  it immediately sends an :i_am_the_king message.
  Nodes that receive an :i_am_the_king message begin to assume the leader of the node that sends them.

  Newly started nodes initiate the leader selection procedure immediately after starting.
  """

  use GenServer

  import Logger
  alias Starfish.State

  @timeout_in_ms 3000

  @t_seconds if Mix.env() == :test, do: 10, else: 5 * 1000

  @default_leader :node1@localhost

  # We can include more nodes in the cluster
  @all_nodes [
    :node1@localhost,
    :node2@localhost,
    :node3@localhost
  ]

  @seniority %{
    :node1@localhost => 10,
    :node2@localhost => 5,
    :node3@localhost => 0
  }

  @default_seniority 0

  @type state :: %{current_nodes: [pid()]}

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    Logger.info("--------")
    Logger.info("Init")

    # There isn't a background process that will connect nodes
    # so we need to do it manually when the process starts
    connect_nodes()

    # The ping is called manually on tests
    if Mix.env() != :test do
      Process.send_after(self(), :ping, @t_seconds)
    end

    {:ok, %State{seniority: get_seniority(Node.self()), leader: leader}}
  end

  def handle_info(:ping, state) do
    Logger.info("--------")
    Logger.info("Ping")

    # Most cases needs to be executed in a separate message to unblock the mailbox
    # from other messages in the process
    cond do
      is_nil(state.leader) ->
        send(self(), :find_new_leader)

      state.leader == Node.self() ->
        send(self(), :i_am_the_king)

      # Calling Node.ping is not enough to know if the leader is alive.
      # during the GenServer call the leader could die.
      # The exception raised is:
      # (EXIT) no connection to nodeX@localhost
      Node.ping(state.leader) == :pong &&
          GenServer.call({__MODULE__, state.leader}, :alive?, 4 * @t_seconds) == :fine_thanks ->
        Logger.info("Leader is alive")

      true ->
        send(self(), :find_new_leader)
    end

    Logger.info("Schedule ping")
    Process.send_after(self(), :ping, @t_seconds)

    {:noreply, state}
  end

  def handle_info(:wait_for_the_king, state) do
    Logger.info("Wait for the king")

    if state.leader == nil do
      send(self(), :find_new_leader)
    end

    {:noreply, state}
  end

  def handle_info(:find_new_leader, state) do
    Logger.info("Find new leader")

    this_node = Node.self()
    this_node_seniority = get_seniority(this_node)

    {replies, _} =
      @all_nodes
      |> Enum.filter(fn node ->
        this_node != node and get_seniority(node) > this_node_seniority
      end)
      |> GenServer.multi_call(__MODULE__, :alive?, @t_seconds)

    if Enum.any?(replies, fn {_node, :fine_thanks} -> true end) do
      Logger.info("Someone reply")

      Process.send_after(self(), :wait_for_the_king, @t_seconds)

      {:noreply, %{state | leader: nil}}
    else
      send(self(), :i_am_the_king)

      {:noreply, %{state | leader: Node.self()}}
    end
  end

  def handle_info(:i_am_the_king, state) do
    Logger.info("I am the king")
    GenServer.multi_call(Node.list(), __MODULE__, {:i_am_the_king, Node.self()}, @t_seconds)

    {:noreply, %{state | leader: Node.self()}}
  end

  def handle_call(:alive?, from, state) do
    Logger.info("Alive? Yep, I'm alive")

    {:reply, :fine_thanks, state}
  end

  def handle_call({:i_am_the_king, from}, _, state) do
    Logger.info("Long live the king #{inspect(from)}")

    {:noreply, %{state | leader: from}}
  end

  defp connect_nodes do
    Enum.each(@all_nodes, fn node ->
      Node.connect(node)
    end)
  end

  defp get_seniority(node), do: @seniority[node] || @default_seniority
end
