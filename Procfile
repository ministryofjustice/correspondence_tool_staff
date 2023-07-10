web: bundle exec puma -C config/puma.rb
background_jobs: bundle exec sidekiq -C config/sidekiq-background-jobs.yml
uploads: bundle exec sidekiq -C config/sidekiq-uploads.yml
emails: bundle exec sidekiq -C config/sidekiq-quick-jobs.yml
