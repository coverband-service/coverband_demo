web: bundle exec puma -w 2 -t 3:3 -p ${PORT:-3000} -e ${RACK_ENV:-development}
worker: bundle exec sidekiq -t 5
