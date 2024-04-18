require Rails.root.join("lib/db/database_anonymizer_tasks")

class AnonymiserDbJob < ApplicationJob
  queue_as :anonymiser

  def perform(task_name, task_arguments)
    SentryContextProvider.set_context
    ::DatabaseAnonymizerTasks.new.execute_task(task_name, task_arguments)
  end
end
