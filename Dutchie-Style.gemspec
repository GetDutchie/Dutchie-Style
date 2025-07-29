# frozen_string_literal: true

require_relative "lib/Dutchie/Style/version"

Gem::Specification.new do |spec|
  spec.name          = "Dutchie-Style"
  spec.version       = Dutchie::Style::VERSION
  spec.authors       = ["Christopher Ostrowski"]
  spec.email         = ["chris@dutchie.com"]

  spec.license = "MIT"

  spec.summary       = "Rubocop Settings for all dutchie Ruby Apps"
  spec.description   = "Rubocop Settings for all dutchie Ruby Apps"
  spec.homepage      = "https://github.com/GetDutchie/Dutchie-Style"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.1.4")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/GetDutchie/Dutchie-Style"
  spec.metadata["changelog_uri"] = "https://github.com/GetDutchie/Dutchie-Style/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(File.expand_path(__dir__)) do
      `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(test|spec|features)/}) }
    end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rubocop", "~> 1.72"
  spec.add_dependency "rubocop-rails", "~> 2.21"
  spec.add_dependency "rubocop-rspec", "~> 2.24"
  spec.add_dependency "rubocop-capybara", "~> 2.18"
  spec.metadata["rubygems_mfa_required"] = "true"
end
