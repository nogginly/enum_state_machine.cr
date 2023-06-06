# This macro tests for default/core methods of any state machine
# associated with an `enum`
macro state_machine_core(state_enum, *, initial)
  {%
    state_type = state_enum.resolve
    unless state_type.ancestors.includes?(Enum)
      raise "State machine requires an Enum; `{{state_enum}}` isn't one."
    end
    state_consts = state_type.constants
    state_ids = state_consts.map { |e| e.id.underscore }
    state_name = state_enum.id.underscore
  %}

  # verify that the state getter exists and returns the initial value
  describe "#\\{{state_name}}" do
    it "is initially {{initial}}" do
      expect(subject.{{state_name}}).to eq {{initial}}
    end
  end

  # verify that the per-status value tester method exists and returns
  # `true` when initial and false otherwise
  {% for e in state_consts %}
    {%
      e_name = e.id.underscore
      e_proper = "#{state_enum}::#{e}".id
      e_is_initial = (e_proper == initial.id)
    %}
    describe "#\\{{e_name}}?" do
      it "is initially {{e_is_initial}}" do
        expect(subject.{{e_name}}?).to be {{e_is_initial}}
      end
    end
  {% end %}
end

# RSpec.shared_examples "state machine basics" do |state_machine, initial_state:, states:, events:|
#   describe "state machine for #{state_machine}" do
#     it "initially #{initial_state}" do
#       expect(subject.send(state_machine)).to eq initial_state
#     end

#     context "defines event methods" do
#       events.each do |event|
#         it event.to_s do
#           expect(subject.class.method_defined?(event)).to be true
#         end
#       end
#     end

#     context "defines info methods" do
#       it "#{state_machine}_states" do
#         expect(subject.send("#{state_machine}_states")).to eq states
#       end

#       it "#{state_machine}_events" do
#         expect(subject.send("#{state_machine}_events")).to eq events
#       end
#     end

#     context "defines state methods" do
#       states.each do |state|
#         it "#{state}?" do
#           expect(subject.class.method_defined?("#{state}?")).to be true
#         end
#       end
#     end

#     context "defines event pre-condition methods" do
#       events.each do |event|
#         it "may_#{event}?" do
#           expect(subject.class.method_defined?("may_#{event}?")).to be true
#         end
#       end
#     end
#   end
# end
