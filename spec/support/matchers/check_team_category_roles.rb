require 'rspec/expectations'

RSpec::Matchers.define :match_tcr_attrs do |expected_category, *expected_methods|
  match do |actual_tcr|
    permissions = set_up_permissions(expected_methods)
    category = Category.__send__(expected_category)
    expect(actual_tcr.category_id).to eq category.id
    permissions.each do |method, bool_val|
      expect(actual_tcr.__send__(method)).to eq bool_val
    end

    failure_message do
      "expected that the team category role record would be for #{expected_category} with #{expected_methods}\n"
    end

  end

  def set_up_permissions(true_methods)
    permissions = {
        view: false,
        manage: false,
        edit: false,
        respond: false,
        approve: false
    }
    true_methods.each do |meth|
      permissions[meth] = true
    end
    permissions
  end
end



