require 'rufus-scheduler'

s = Rufus::Scheduler.singleton

s.every '10m' do
  Backup.backup
end
