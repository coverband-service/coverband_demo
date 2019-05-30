# Coverband Demo

This is a Rails 5 application to demo how to use [Coverband](https://github.com/danmayer/coverband) and the features it offers.

Visit the live demo site [https://coverband-demo.herokuapp.com/](https://coverband-demo.herokuapp.com/)

# Heroku Deployment

The demo site is hosted on Heroku.

- basic setup was done following the standard [Heroku Rails 5 Guide](https://devcenter.heroku.com/articles/getting-started-with-rails5)

# Theme

The initial design off the demo site was pulled from a demo'ed theme, a Material Design Bootstrap 4 Theme.

- [From Rails 5 to Bootstrap 4 — Responsive Admin Dashboard Template](https://medium.com/@frontted/from-rails-5-to-bootstrap-4-responsive-admin-dashboard-template-1de103c6216c)
- [Hero Rails](https://github.com/frontted/hero-rails)

# TODO

- more realistic Rails usage, perhaps add something to help market coverband like show tweets
- add deploy to Heroku button support
- add background job example / integration
- add cron example / integration
- API to collect perf data across CI runs
  - client would post data on each benchmark run
    - `ruby_version, branch or PR name, benchmark_name, calculations -> {data_point_name, i/s, total iterations, total time}, Comparison -> {data_point_name, i/s, diff calculation, note}`
