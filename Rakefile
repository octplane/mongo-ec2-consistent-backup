require 'rake'
require "rake/clean"
require 'rake/gempackagetask'
require 'rake/rdoctask'

desc "Packages up the gem."
task :default => :package

spec = Gem::Specification.new do |s|
  s.name    = 'mongo-ec2-backup'
  s.version = '0.0.6'
  s.summary = 'Snapshot your mongodb in the EC2 cloud via XFS Freeze'

  s.author   = 'Pierre Baillet'
  s.email    = 'oct@fotopedia.com'
  s.homepage = 'https://github.com/octplane/mongo-ec2-consistent-backup'

  # These dependencies are only for people who work on this gem
  s.add_dependency 'fog'
  s.add_dependency 'bson_ext'
  s.add_dependency 'trollop'
  s.add_dependency 'mongo'

  # Include everything in the lib folder
  s.files = FileList['lib/**/*.rb', 'bin/*', '[A-Z]*', 'test/**/*'].to_a

  s.executables << "mongo_lock_and_snapshot"
  s.executables << "ec2_snapshot_restorer"

  # Supress the warning about no rubyforge project
  s.rubyforge_project = 'nowarning'
end

Rake::GemPackageTask.new(spec) do |package| 
  package.gem_spec = spec
  # package.need_tar = true 
  # package.need_zip = true
end
