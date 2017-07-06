class ApplicationPolicy
  class << self
    def failed_checks
      @@failed_checks
    end

    def check(name, &block)
      define_method "check_#{name}" do
        if instance_eval(&block)
          true
        else
          @@failed_checks << name
          false
        end
      end

      private "check_#{name}"
    end
  end

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user   = user
    @record = record
  end

  def clear_failed_checks
    @@failed_checks = []
    @options = {}
  end
end
