# Starfish

This test assumes that you already have Elixir installed.
I think that [asdf](https://asdf-vm.com/) is the best option. Although, the easiest one is just with Homebrew
`brew install elixir`

## Test it!

First, sorry since I had not the time to find a way to write a simple command to execute the tests.
Also, because I have no experience with distributed applications.

In order to simulate multiple nodes. Run this commands in a separate terminal inside the project folder.

From our first terminal, run:

```
iex --sname node1@localhost --cookie my_cookie -S mix
```

It will show the next logs

```
[info] --------
[info] Init
[info] --------
[info] Ping
[info] Schedule ping
[info] Find new leader
[info] I am the king
...
```

It will print some ack responses on terminal 1, until we create a new node.

For the second terminal, run:

```
iex --sname node2@localhost --cookie my_cookie -S mix
```

For the third terminal, run:

```
iex --sname node3@localhost --cookie my_cookie -S mix
```

The logs could vary a little depending on the timing.
Although, the second and third node will always recognize the first node as the leader.

```
[info] --------
[info] Init
[info] Long live the king :node1@localhost
[info] --------
[info] Ping
[info] Leader is alive
[info] Schedule ping
...
```

To test the election of a new leader, the leader must be killed, and a new one will be elected by the remained nodes. The node1@localhost, node2@localhost and node3@localhost can be created at any time. All nodes must be declared in `lib/starfish/server.ex:48`.

## Questions that could be important before starting

- Should I use some library, like: [libcluster](https://github.com/bitwalker/libcluster)?
- How will you test my code?

## Finally

I always try to prioritize unit tests but in this case the challenge takes a lot of my time.
One resource that would be interesting to try is: [LocalCluster](https://github.com/whitfin/local-cluster)
