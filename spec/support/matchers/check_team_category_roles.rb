require "rspec/expectations"

RSpec::Matchers.define :match_tcr_attrs do |expected_correspondence_type,
                                            *expected_methods|
  match do |actual_tcr|
    permissions = set_up_permissions(expected_methods)
    ct = CorrespondenceType.__send__(expected_correspondence_type)
    expect(actual_tcr.correspondence_type_id).to eq ct.id
    permissions.each do |method, bool_val|
      expect(actual_tcr.__send__(method)).to eq bool_val
    end

    failure_message do
      "expected that the team correspondence type role record would be for " \
        "#{expected_correspondence_type} with #{expected_methods}\n"
    end
  end

  def set_up_permissions(true_methods)
    permissions = {
      view: false,
      manage: false,
      edit: false,
      respond: false,
      approve: false,
    }
    true_methods.each do |meth|
      permissions[meth] = true
    end
    permissions
  end
end
