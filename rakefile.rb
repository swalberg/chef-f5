desc 'runs guard'
task :guard do
  exec('bundle exec guard')
end

desc 'lint the cookbook with rubocop'
task :lint do
  exec('bundle exec rubocop')
end

desc 'run unit tests'
task test: 'test:run:unit'

namespace :test do
  desc 'list unit tests'
  task list: %w(test:list:unit)

  namespace :run do
    task :unit do
      #exec('bundle exec rake lint && bundle exec rspec -f d --color spec')
      exec('bundle exec rspec -f d --color spec')
    end
  end

  namespace :list do
    task :unit do
      exec('bundle exec rspec -f d --color --dry-run spec')
    end
  end
end
