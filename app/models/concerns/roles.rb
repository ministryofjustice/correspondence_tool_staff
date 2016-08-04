module Roles
  extend ActiveSupport::Concern

  included do |klass|
    klass.extend(ClassMethods)
    klass.serialize :roles, Array
    klass.before_validation :strip_empty_role
    klass.validate :roles_valid

    klass::ROLES.each do |role|
      klass.scope role.pluralize.to_sym, -> { matching_role_query([role.to_s]) }

      define_method "#{role}?" do
        is?(role)
      end
    end

  end

  module ClassMethods
    # Chainable roles query
    # e.g.
    #   scope :lgfs_only, -> { matching_role_query(['lgfs']) }
    #   scope :agfs_and_lgfs_only, -> { matching_role_query(['agfs','lgfs'],'AND') }
    def matching_role_query(roles, condition = 'AND')
      clause = roles.map { |role| "(roles ILIKE '%#{role}%')" }.join(" #{condition} ")
      where clause
    end
  end

  def is?(role)
    roles.include?(role.to_s)
  end

  def roles_include?(*arg_roles)
    arg_roles.to_a! unless arg_roles.is_a? Array
    arg_roles.flatten!
    return false if arg_roles.empty?
    arg_roles.map!(&:to_s)
    arg_roles & roles == arg_roles
  end

  private

  def strip_empty_role
    self.roles = roles.reject(&:empty?)
  end

  def roles_valid
    if roles.empty?
      errors[:roles] << 'at least one role must be present'
    elsif (roles - self.class::ROLES).any?
      errors[:roles] << "must be one or more of: #{roles_string}"
    end
  end

  def roles_string(delimiter = ', ')
    self.class::ROLES.map { |r| r.humanize.downcase }.join(delimiter)
  end
end
