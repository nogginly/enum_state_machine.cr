require "./spec_helper"

module GuardEventStateSpec
  enum Motion
    Idling
    Walking
    Running
  end

  enum Action
    Ready
    Jumping
    Leaping
  end

  class GuardEventStateMachine
    include EnumStateMachine

    state_machine Motion, initial: Motion::Idling do
      event :idle, to: Motion::Idling
      event :walk, to: Motion::Walking
      event :run, to: Motion::Running
    end

    state_machine Action, initial: Action::Ready do
      event :hold, to: Action::Ready
      event :jump, guard: ->{ !running? },
        from: Action::Ready, to: Action::Jumping
      event :leap, guard: ->{ running? },
        from: Action::Ready, to: Action::Leaping
    end
  end
end

Spectator.describe GuardEventStateSpec::GuardEventStateMachine do
  include GuardEventStateSpec

  state_machine_core Action, initial: Action::Ready

  state_machine_core Motion, initial: Motion::Idling

  describe "#jump" do
    it "guard fails if motion is running" do
      subject.run
      expect(subject.may_jump?).to be false
      expect(subject.jump).to be nil
    end

    it "guard succeeds if motion is not running" do
      subject.walk
      expect(subject.may_jump?).to be true
      expect(subject.jump).to be Action::Jumping
    end
  end

  describe "#leap" do
    it "guard fails if motion is not running" do
      subject.walk
      expect(subject.may_leap?).to be false
      expect(subject.leap).to be nil
    end

    it "guard succeeds if motion is running" do
      subject.run
      expect(subject.may_leap?).to be true
      expect(subject.leap).to be Action::Leaping
    end
  end
end
