# Enum State Machine for Crystal

`enum_state_machine` is a type-safe finite state machine for Crystal where the states are defined using enum's. I created it because I wanted the minimal FSM data type that was function and easy to use.

[![.github/workflows/ci_linux.yml](https://github.com/nogginly/enum_state_machine.cr/actions/workflows/ci_linux.yml/badge.svg)](https://github.com/nogginly/enum_state_machine.cr/actions/workflows/ci_linux.yml)

[![.github/workflows/ci_macos.yml](https://github.com/nogginly/enum_state_machine.cr/actions/workflows/ci_macos.yml/badge.svg)](https://github.com/nogginly/enum_state_machine.cr/actions/workflows/ci_macos.yml)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     enum_state_machine:
       github: nogginly/enum_state_machine.cr
   ```

2. Run `shards install`

## Usage

Here's a single example that illustrates how to use `enum_state_machine` to setup a toy `Player` class with two statuses, `Action` and `Health`, and their respective state machines.

```cr
require "enum_state_machine"

module MyGame
  enum Action
    Idle
    Walk
    Run
    Jump
    Attack
  end

  enum Health
    Alive
    Dead
  end

  class Player
    include EnumStateMachine

    state_machine(Action, initial: Action::Idle) do
      event :idle,        # from any state except these
        except_from: {Action::Idle, Action::Jump}, to: Action::Idle
      event :jump,        # from one of many states
        from: {Action::Walk, Action::Run, Action::Idle}, to: Action::Jump
      event :attack,      # from one state
        from: Action::Idle, to: Action::Attack
      event :run, to: Action::Run
    end

    state_machine(Health, initial: Health::Alive) do
      event :die,         # from one state
        from: Health::Alive, to: Health::Dead
      event :resurrect,   # from a state, with a guard
        from: Health::Dead, to: Health::Alive,
        guard: ->{ idle? }
    end
  end
```

Each event `do_this` adds the following capability methods:

- `do_this` attempts to perform the transition
- `do_this(&)` which yields after successfully performing transition
- `may_do_this?` returns true of the transition may be performed

Each state machine for an `enum Feeling` adds the following methods:

- `feeling` which returns the current value of the `Feeling` state
- for each enumeration of `Feeling`, say `Feeling::Kind` and `Feeling::Sad`
  - `kind?` which returns true of the current value of `feeling` is `Feeling::Kind`
  - `sad?`
  - and so on.

## To do

_In no particular order_:

- More examples for the various ways to define and use `enum_state_machine`
- Document possible compile errors
- Event transition failure handler (like `guard`)
- Multiple transitions for a single event
- ~~Test suite~~
- ~~Enable CI using GH actions~~

## Contributing

Bug reports and sugestions are welcome. Otherwise, at this time, this project is closed for code changes and pull requests. I appreciate your understanding.

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://www.contributor-covenant.org/version/1/4/code-of-conduct/).

## License

This shard is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Contributors

- [nogginly](https://github.com/nogginly) - creator and maintainer
