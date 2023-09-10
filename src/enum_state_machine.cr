#
# Define type-safe finite state machine for Crystal where the states are defined using enum's.
#
# ```
# enum Health
#   Alive
#   Dead
#   Zombie
# end
#
# class Player
#   include EnumStateMachine
#
#   getter hp = 100
#
#   state_machine(Health, initial: Health::Alive) do
#     event :die, to: Health::Dead
#     event :resurrect, from: Health::Dead, to: Health::Alive, guard: ->{ hp <= 0 }
#     event :succumb, except_from: Health::Alive, to: Health::Zombie
#   end
# end
# ```
#
module EnumStateMachine
  # :nodoc:
  # Internal state machine used to set up the scaffolding
  # for the generated FSM
  class EFSM(E)
    @state : E

    protected def initialize(@state); end

    @[AlwaysInline]
    protected def state : E
      @state
    end

    @[AlwaysInline]
    protected def is?(s : E) : Bool
      state == s
    end

    @[AlwaysInline]
    protected def is?(s : Tuple | Array) : Bool
      s.any? { |a| state == a }
    end

    @[AlwaysInline]
    protected def not?(s : E) : Bool
      state != s
    end

    @[AlwaysInline]
    protected def not?(s : Tuple | Array) : Bool
      s.all? { |a| state != a }
    end

    @[AlwaysInline]
    protected def transitions(*, to : E) : E
      @state = to
    end

    @[AlwaysInline]
    protected def transitions(*, from, to : E) : E?
      @state = to if is?(from)
    end

    @[AlwaysInline]
    protected def transitions(*, except_from, to : E) : E?
      @state = to if not?(except_from)
    end

    @[AlwaysInline]
    protected def allowed?(&)
      return true if yield
      false
    end

    # :nodoc:
    macro event(state_enum, field, name, *, from = nil, except_from = nil, to, guard)
      {%
        if from && except_from
          raise "State machine event requires either `from` or `except` or neither, but not both."
        end
      %}

      macro guard_{{name.id}}(*, on_fail)
        {% if guard.is_a?(ProcLiteral) %}
          {%
            raise "Event's guard handler (proc) cannot expect arguments." if guard.args.size > 0
          %}
          return \{{on_fail}} unless (@{{field}}.allowed? do
            {{guard.body}}
          end)
        {% end %}
      end

      # Check if `{{state_enum}}` state can transition to `#{{to}}`
      def {{ "may_#{name.id}?".id }} : Bool
        guard_{{name.id}}(on_fail: false)
        {% if from %}
        @{{field}}.is?({{from}})
        {% elsif except_from %}
        @{{field}}.not?({{except_from}})
        {% else %}
        true
        {% end %}
      end

      # Transition `{{state_enum}}` state to `#{{to}}` if possible; return nil if unable.
      def {{ name.id }} : {{state_enum}}?
        guard_{{name.id}}(on_fail: nil)
        {% if from %}
        @{{field}}.transitions(from: {{from}}, to: {{to}})
        {% elsif except_from %}
        @{{field}}.transitions(except_from: {{except_from}}, to: {{to}})
        {% else %}
        @{{field}}.transitions(to: {{to}})
        {% end %}
      end

      # Transition `{{state_enum}}` state to `#{{to}}` and yield to block if possible; return nil if unable.
      def {{ name.id }}(&) : {{state_enum}}?
        if (outcome = {{ name.id }})
          yield
        end
        outcome
      end
    end
  end

  # Setup a state machine based on *state_enum* enumeration, with *initial* value, and *block* containing the
  # `event` declarations.
  #
  # > **Example:**, given `enum Health` with values `Alive` and `Dead`, a `state_machine`
  # declared with an event `:die` that transitions to `Dead` makes the following methods available:
  # >
  # > - `heath` to get the current state
  # > - `dead?` to check if state is `Dead`
  # > - `alive?` to check if state is `Alive`
  # > - `die` to make the transition if possible
  # > - `may_die?` to check if player can `die`
  #
  # Using different `enum` types, multiple state machines can be setup in the same object.
  macro state_machine(state_enum, *, initial, &block)
    # Make sure state is an Enum
    {%
      state_type = state_enum.resolve
      unless state_type.ancestors.includes?(Enum)
        raise "State machine requires an Enum; `{{state_enum}}` isn't one."
      end
    %}

    {% machine = "EFSM(#{state_enum})".id %}
    {% field = "#{state_enum.id.underscore}_sm".id %}

    # The internal `{{state_enum}}` state machine
    @{{ field }} = {{machine}}.new({{ initial }})

    # The current value of the `{{state_enum}}` state.
    def {{state_enum.id.underscore}} : {{state_enum}}
      @{{field}}.state
    end

    # Internal delegating macro
    macro event(name, *, to, guard=nil)
      EFSM.event({{state_enum}}, {{field}}, \{{name}}, to: \{{to}}, guard: \{{guard}})
    end

    # Internal delegating macro
    macro event(name, *, from, to, guard=nil)
      EFSM.event({{state_enum}}, {{field}}, \{{name}}, from: \{{from}}, to: \{{to}}, guard: \{{guard}})
    end

    # Internal delegating macro
    macro event(name, *, except_from, to, guard=nil)
      EFSM.event({{state_enum}}, {{field}}, \{{name}}, except_from: \{{except_from}}, to: \{{to}}, guard: \{{guard}})
    end

    {{ block.body }}

    {% for e in state_type.constants %}
      {% e_name = e.id.underscore %}
      # Check if current `{{state_enum}}` state is `{{e.id}}`
      def {{e_name}}? : Bool
        @{{ field }}.state.{{e_name}}?
      end
    {% end %}
  end
end
