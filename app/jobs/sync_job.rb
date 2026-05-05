class SyncJob < ApplicationJob
  queue_as :high_priority
  retry_on SQLite3::BusyException, wait: 1.minute, attempts: 3

  def perform(sync)
    sync.perform
  end
end
