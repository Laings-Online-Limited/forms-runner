desc "Lint with rubocop"
task lint: :environment do
  sh "bundle exec rubocop"
  sh "npm run lint"
end
