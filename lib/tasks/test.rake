namespace :test do
  desc 'Run tests with coverage'
  task :coverage do
    ENV['SIMPLECOV'] = 'true'

    # Run all test types
    Rake::Task['test'].invoke
  end
end
