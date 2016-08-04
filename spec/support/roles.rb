require 'rails_helper'

shared_examples_for 'roles' do |klass, roles|

  let(:factory_name) { klass.name.demodulize.to_s.underscore.to_sym }

  describe 'validation' do
    let(:assigned_roles) { [] }
    subject { build(factory_name, roles: assigned_roles) }

    it 'is valid when a valid role is present' do
      assigned_roles << roles.first
      expect(subject).to be_valid
    end

    it 'is not valid with an invalid role' do
      assigned_roles << [roles.first, 'foobar123xyz']
      expect(subject).not_to be_valid
      expect(subject.errors[:roles]).to include("must be one or more of: #{roles.map { |r| r.humanize.downcase }.join(', ')}")
    end

    it 'is not valid without a role' do
      expect(subject).not_to be_valid
      expect(subject.errors[:roles]).to include('at least one role must be present')
    end
  end

  describe 'scopes' do
    roles.each do |role|
      describe ".#{role.pluralize}" do
        before { create(factory_name, roles: [role]) }

        it "only returns #{klass.to_s.underscore} with role '#{role}'" do
          expect(klass.send(role.pluralize).count).to eq(1)
        end
      end
    end
  end

  describe '#is?' do
    roles.each do |role|
      context "for #{role}" do
        subject { create(factory_name, roles: [role]) }

        it "returns true for #{role}" do
          expect(subject.is?(role)).to eq(true)
        end

        it 'returns false for any other role' do
          expect(subject.is?('foobar123xyz')).to eq(false)
        end
      end
    end
  end

  describe '#roles_include?' do
    subject { create(factory_name, roles: roles) }

    it "returns true if subject has exact specified roles" do
      expect(subject.roles_include?(roles)).to eq(true)
      expect(subject.roles_include?(*roles)).to eq(true)
      expect(subject.roles_include?(roles.flatten)).to eq(true)
    end

    it 'returns true if the subject has a subset of the roles' do
      expect(subject.roles_include?(roles.last)).to be true
      expect(subject.roles_include?(roles.first)).to be true
    end

    it 'returns false if the subject doesnt have all the specified roles' do
      these_roles = roles + ['extra']
      expect(subject.roles_include?(these_roles)).to be false
    end

    it 'returns false if the subject has none of the specified roles' do
      different_roles = %w[this that other]
      expect(subject.roles_include?(different_roles)).to be false
    end

    it 'returns true if the role is specified as a symbol' do
      expect(subject.roles_include?(roles.first.to_sym)).to be true
    end

    it 'returns true if the roles are specifeied as an array of symbols' do
      expect(subject.roles_include?(roles.map(&:to_sym))).to be true
    end

    it 'returns true if the role is specified as a string' do
      expect(subject.roles_include?(roles.first.to_s)).to be true
    end

    it 'returns true if the roles are specifeied as an array of strings' do
      expect(subject.roles_include?(roles.map(&:to_s))).to be true
    end
  end

  describe 'role based dynamic boolean methods' do
    roles.each do |role|
      describe "##{role}?" do
        subject { create(factory_name, roles: [role]) }

        it 'returns true when role present' do
          expect(subject.send("#{role}?")).to eq(true)
        end
      end
    end
  end
end
