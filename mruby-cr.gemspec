require_relative './lib/mruby-cr/version'

Gem::Specification.new do |s|
  s.name = 'mruby-cr'
  s.version = MrubyCr::VERSION
  s.summary = 'mruby for crystal'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'https://github.com/spox/mruby-cr'
  s.description = 'crystal mruby library binding generator'
  s.require_path = 'lib'
  s.license = 'MIT'
  s.add_runtime_dependency 'ffi_gen', '1.1.0'
  s.executables << 'mruby-cr'
  s.files = Dir['{lib,bin}/**/*'] + %w(mruby-cr.gemspec README.md CHANGELOG.md)
end
