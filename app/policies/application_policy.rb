class ApplicationPolicy
  @@failed_checks = []

  class << self
    def failed_checks
      @@failed_checks
    end

    def check(name, &block)
      define_method "check_#{name}" do |*args|
        if instance_exec(*args, &block)
          true
        else
          @@failed_checks << [name, @user, @record]
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

  def check(name)
    __send__("check_#{name}")
  end

  check :user_is_a_manager do
    user.manager?
  end
end
