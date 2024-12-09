require_relative "lib/activestorage_encryption_service/version"

Gem::Specification.new do |spec|
  spec.name = "activestorage-encryption-service"
  spec.version = ActiveStorageEncryptionService::VERSION
  spec.authors = ["Alexander Gitter"]
  spec.email = ["contact@agitter.de"]

  spec.summary = "An ActiveStorage service that wraps other services and encrypts files before they are uploaded/stored."
  spec.homepage = "https://github.com/alexandergitter/activestorage-encryption-service"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activestorage", ">= 7.0"
  spec.add_dependency "ruby-chacha20", ">= 0.1.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.16"
end
