require 'rails_helper'
require_relative '../support/standard_setup.rb'

describe 'state_machine' do
  before(:all){ @setup = StandardSetup.new }
  after(:all) { DbHousekeeping.clean }

  it 'does' do
    ap @setup.manager
  end
end
