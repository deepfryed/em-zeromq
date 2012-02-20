# encoding: utf-8

$:.unshift File.dirname(__FILE__) 

require 'date'
require 'pathname'
require 'rake'
require 'rake/testtask'
require 'lib/em-zeromq'

$rootdir = Pathname.new(__FILE__).dirname
$gemspec = Gem::Specification.new do |s|
  s.name              = 'em-zeromq'
  s.version           = EM::ZeroMQ::VERSION
  s.date              = Date.today    
  s.authors           = ['Bharanee Rathna']
  s.email             = ['deepfryed@gmail.com']
  s.summary           = 'ZeroMQ on Eventmachine'
  s.description       = 'ØMQ - sockets on steroids running on eventmachine.'
  s.homepage          = 'http://github.com/deepfryed/em-zeromq'
  s.files             = Dir['{ext,test,lib}/**/*.rb'] + %w(README.md CHANGELOG)
  s.require_paths     = %w(lib)

  s.add_dependency('eventmachine')
  s.add_dependency('zmq')
  s.add_development_dependency('rake')
end

desc 'Generate gemspec'
task :gemspec do 
  $gemspec.date    = Date.today
  File.open("#{$gemspec.name}.gemspec", 'w') {|fh| fh.write($gemspec.to_ruby)}
end

Rake::TestTask.new(:test) do |test|
  test.libs   << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task default: :test
