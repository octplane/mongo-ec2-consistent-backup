 require 'rake'
Gem::Specification.new do |s|
  s.name    = 'mongo-ec2-backup'
  s.version = '0.0.1'
  s.summary = 'Snapshot your mongodb in the EC2 cloud via RAID EBS'

  s.author   = 'Pierre Baillet'
  s.email    = 'oct@fotopedia.com'
  s.homepage = 'https://github.com/octplane/mongo-ec2-consistent-backup'

  # These dependencies are only for people who work on this gem
  s.add_development_dependency 'aws'
  s.add_development_dependency 'trollop'
  s.add_development_dependency 'mongo'

  # Include everything in the lib folder
  s.files = FileList['lib/**/*.rb', 'bin/*', '[A-Z]*', 'test/**/*'].to_a

  s.executables << "lock_and_snapshot"

  # Supress the warning about no rubyforge project
  s.rubyforge_project = 'nowarning'
end
