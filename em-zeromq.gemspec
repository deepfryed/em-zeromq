# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{em-zeromq}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bharanee Rathna"]
  s.date = %q{2012-02-20}
  s.description = %q{ØMQ - sockets on steroids running on eventmachine.}
  s.email = ["deepfryed@gmail.com"]
  s.files = ["test/test_pub_sub.rb", "test/test_push_pull.rb", "test/helper.rb", "test/test_rep_req.rb", "lib/em-zeromq.rb", "README.md", "CHANGELOG"]
  s.homepage = %q{http://github.com/deepfryed/em-zeromq}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{ZeroMQ on Eventmachine}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0"])
      s.add_runtime_dependency(%q<zmq>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0"])
      s.add_dependency(%q<zmq>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0"])
    s.add_dependency(%q<zmq>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
