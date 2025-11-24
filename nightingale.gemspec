# frozen_string_literal: true

require_relative "lib/nightingale/version"

Gem::Specification.new do |spec|
  spec.name = "nightingale"
  spec.version = Nightingale::VERSION
  spec.authors = ["Allen C."]
  spec.email = ["allengineerx@gmail.com"]

  spec.summary = "A Ruby framework for building interactive data and AI web apps."
  spec.description = <<~DESC
    Nightingale brings the 'script-as-app' experience to Ruby. Write your UI in pure Ruby DSL, backed by Sinatra and React/Vite.
  DESC
  spec.homepage = "https://github.com/allengineerx/nightingale"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/allengineerx/nightingale"
  spec.metadata["changelog_uri"] = "https://github.com/allengineerx/nightingale/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faye-websocket", "~> 0.4", ">= 0.4.4"
  spec.add_dependency "json", "~> 2.16", ">= 2.16.0"
  spec.add_dependency "listen", "~> 3.9", ">= 3.9.0"
  spec.add_dependency "pry", "~> 0.15", ">= 0.15.0"
  spec.add_dependency "puma", "~> 7.1", ">= 7.1.0"
  spec.add_dependency "sinatra", "~> 4.2", ">= 4.2.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
