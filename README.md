# stardust

Sharing code in stardust project
https://epsrc-stardust.github.io/

We assume you have Erlang and rebar3 installed

## Examples

The transient directory contains an example of Erlang code with a
transient failure.

You can run this code by
```
cd transient
rebar3 eunit
```

This will run the tests in test/transient_test.erl.
Most likely both tests pass.
However, if you bump the number `Rooms` from 10 to 100 or 1000, you
will see the test case fail. This error is transient and only shows up
in so many runs.
