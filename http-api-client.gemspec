# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'http/api/client/version'

Gem::Specification.new do |spec|
  spec.name          = "http-api-client"
  spec.version       = Http::Api::Client::VERSION
  spec.authors       = ["Nikos Mouchtaris"]
  spec.email         = ["mouchtaris@gmail.com"]

  spec.summary       = %q{An HTTP API Client}
  spec.description   = %q{A convenience wrapper for a kind of HTTP API clients,
                          based on Ruby's HTTP library}
  spec.homepage      = "https://github.com/mouchtaris/http-api-client"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'hashie', '~> 3.5.4'
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.10.4"
  spec.add_development_dependency "rubocop", "~> 0.47.1"
end
