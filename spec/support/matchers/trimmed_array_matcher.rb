require 'rspec/expectations'

RSpec::Matchers.define :match_trimmed_array do |array|
  match do |actual|
    trimmed_array = actual.map{ |x| x.tr("\n", '') }
    expect(trimmed_array).to match_array(array)
  end
end

