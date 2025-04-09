lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "influxdb/rails/version"

Gem::Specification.new do |spec|
  spec.name        = "influxdb-rails"
  spec.summary     = "InfluxDB bindings for Ruby on Rails."
  spec.description = "This gem instruments your Ruby on Rails application using InfluxDB."
  spec.version     = InfluxDB::Rails::VERSION
  spec.authors     = ["Christian Bruckmayer", "Henne Vogelsang"]
  spec.email       = ["christian@bruckmayer.net", "hvogel@hennevogel.de"]
  spec.licenses    = ["MIT"]
  spec.homepage    = "https://influxdata.com"
  spec.metadata = {
    "bug_tracker_uri"       => "https://github.com/influxdata/influxdb-rails/issues",
    "changelog_uri"         => "https://github.com/influxdata/influxdb-rails/blob/master/CHANGELOG.md",
    "documentation_uri"     => "https://github.com/influxdata/influxdb-rails/blob/master/README.md",
    "source_code_uri"       => "https://github.com/influxdata/influxdb-rails",
    "rubygems_mfa_required" => "true",
  }

  spec.files         = `git ls-files`.split($/) # rubocop:disable Style/SpecialGlobalVars
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"

  spec.add_runtime_dependency "influxdb-client"
  spec.add_runtime_dependency "railties", ">= 5.0"

  spec.add_development_dependency "actionmailer"
  spec.add_development_dependency "activejob"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "bundler", ">= 1.0.0"
  spec.add_development_dependency "launchy"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rdoc"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "rubocop", "~> 1.75.2"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "tzinfo"
  spec.add_development_dependency "webmock"
end
