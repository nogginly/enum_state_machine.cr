require "./spec_helper"

module OneStateSpec
  enum Activity
    Sleeping
    Running
    Cleaning
  end

  class OneStateMachine
    include EnumStateMachine

    state_machine Activity, initial: Activity::Sleeping do
      event :run, from: Activity::Sleeping, to: Activity::Running
      event :clean, from: Activity::Running, to: Activity::Cleaning
      event :sleep, from: [Activity::Running, Activity::Cleaning], to: Activity::Sleeping
    end
  end
end

include OneStateSpec

Spectator.describe OneStateMachine do
  describe "#sleep" do
    it "fails if already sleeping" do
      expect(subject.may_sleep?).to be false
      expect(subject.sleep).to be nil
      expect(subject.sleeping?).to be true
    end
    it "succeeds if running" do
      subject.run
      expect(subject.sleeping?).to be false
      expect(subject.may_sleep?).to be true
      expect(subject.sleep).to be Activity::Sleeping
      expect(subject.sleeping?).to be true
    end
    it "succeeds if cleaning" do
      subject.run
      subject.clean
      expect(subject.sleeping?).to be false
      expect(subject.may_sleep?).to be true
      expect(subject.sleep).to be Activity::Sleeping
      expect(subject.sleeping?).to be true
    end
  end

  describe "#run" do
    it "succeeds if sleeping" do
      expect(subject.running?).to be false
      expect(subject.may_run?).to be true
      expect(subject.run).to be Activity::Running
      expect(subject.running?).to be true
    end

    it "fails if already running" do
      subject.run
      expect(subject.may_run?).to be false
      expect(subject.run).to be nil
      expect(subject.running?).to be true
    end

    it "fails if cleaning" do
      subject.run
      subject.clean
      expect(subject.may_run?).to be false
      expect(subject.run).to be nil
      expect(subject.running?).to be false
    end
  end

  describe "#clean" do
    it "succeeds if running" do
      subject.run
      expect(subject.cleaning?).to be false
      expect(subject.may_clean?).to be true
      expect(subject.clean).to be Activity::Cleaning
      expect(subject.cleaning?).to be true
    end

    it "fails if sleeping" do
      expect(subject.may_clean?).to be false
      expect(subject.clean).to be nil
      expect(subject.cleaning?).to be false
    end

    it "fails if already cleaning" do
      subject.run
      subject.clean
      expect(subject.may_clean?).to be false
      expect(subject.clean).to be nil
      expect(subject.cleaning?).to be true
    end
  end
end
