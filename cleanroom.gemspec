lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cleanroom'

Gem::Specification.new do |spec|
  spec.name          = 'cleanroom'
  spec.version       = Cleanroom::VERSION
  spec.authors       = ['Seth Vargo', 'Muriel Salvan']
  spec.email         = ['sethvargo@gmail.com', 'muriel@x-aeon.com']
  spec.summary       = '(More) safely evaluate Ruby DSLs with cleanroom'
  spec.description   = <<-DESCRIPTION.gsub(/^ {4}/, '').gsub(/\r?\n/, ' ').strip
    Ruby is an excellent programming language for creating and managing custom
    DSLs, but how can you securely evaluate a DSL while explicitly controlling
    the methods exposed to the user? Our good friends instance_eval and
    instance_exec are great, but they expose all methods - public, protected,
    and private - to the user. Even worse, they expose the ability to
    accidentally or intentionally alter the behavior of the system! The
    cleanroom pattern is a safer, more convenient, Ruby-like approach for
    limiting the information exposed by a DSL while giving users the ability to
    write awesome code!
  DESCRIPTION
  spec.homepage      = 'https://github.com/Muriel-Salvan/cleanroom'
  spec.license       = 'Apache-2.0'

  spec.required_ruby_version = '>= 3.0'

  spec.files = Dir['{bin,lib}/**/*']
  Dir['bin/**/*'].each do |exec_name|
    spec.executables << File.basename(exec_name)
  end
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
end
