spec = Gem::Specification.new do |s|
  s.name    = 'mongo-ec2-backup'
  s.version = '0.1.0'
  s.summary = 'Snapshot your mongodb in the EC2 cloud via XFS Freeze'

  s.author   = 'Pierre Baillet'
  s.email    = 'oct@fotopedia.com'
  s.homepage = 'https://github.com/octplane/mongo-ec2-consistent-backup'

  # These dependencies are only for people who work on this gem
  s.add_dependency 'fog'
  s.add_dependency 'bson_ext'
  s.add_dependency 'trollop'
  s.add_dependency 'mongo'
  s.add_dependency 'json'

  # Include everything in the lib folder
  s.files = Dir.glob('lib/**/*.rb') + Dir.glob('bin/*') + Dir.glob('[A-Z]*') + Dir.glob('test/**/*')

  s.executables << "mongo_lock_and_snapshot"
  s.executables << "ec2_snapshot_restorer"

  # Supress the warning about no rubyforge project
  s.rubyforge_project = 'nowarning'
end
