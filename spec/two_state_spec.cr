require "./spec_helper"

module TwoStateSpec
  enum Motion
    Idling
    Walking
  end

  enum Action
    Ready
    Blocking
  end

  class TwoStateMachine
    include EnumStateMachine

    state_machine Motion, initial: Motion::Idling do
      event :idle, to: Motion::Idling
      event :walk, from: Motion::Idling, to: Motion::Walking
    end

    state_machine Action, initial: Action::Ready do
      event :hold, to: Action::Ready
      event :block, to: Action::Blocking
    end
  end
end

include TwoStateSpec

Spectator.describe TwoStateMachine do
  state_machine_core Action, initial: Action::Ready

  state_machine_core Motion, initial: Motion::Idling

  describe "#idle" do
    it "succeeds if already idling" do
      expect(subject.may_idle?).to be true
      expect(subject.idle).to be Motion::Idling
      expect(subject.idling?).to be true
    end
    it "succeeds if walking" do
      subject.walk
      expect(subject.idling?).to be false
      expect(subject.may_idle?).to be true
      expect(subject.idle).to be Motion::Idling
      expect(subject.idling?).to be true
    end
  end

  describe "#walk" do
    it "succeeds if idling" do
      expect(subject.may_walk?).to be true
      expect(subject.walk).to be Motion::Walking
      expect(subject.walking?).to be true
    end
    it "succeeds if already walking" do
      subject.walk
      expect(subject.walking?).to be true
      expect(subject.may_walk?).to be false
      expect(subject.walk).to be nil
      expect(subject.walking?).to be true
    end
  end

  describe "#hold" do
    it "succeeds if already holding" do
      expect(subject.may_hold?).to be true
      expect(subject.hold).to be Action::Ready
      expect(subject.ready?).to be true
    end
    it "succeeds if blocking" do
      subject.block
      expect(subject.ready?).to be false
      expect(subject.may_hold?).to be true
      expect(subject.hold).to be Action::Ready
      expect(subject.ready?).to be true
    end
  end

  describe "#block" do
    it "succeeds if holding" do
      expect(subject.may_block?).to be true
      expect(subject.block).to be Action::Blocking
      expect(subject.blocking?).to be true
    end
    it "fails if already blocking" do
      subject.block
      expect(subject.blocking?).to be true
      expect(subject.may_block?).to be true
      expect(subject.block).to be Action::Blocking
      expect(subject.blocking?).to be true
    end
  end
end
