require 'simplecov'
SimpleCov.start do
  # Make sure repositories behind symbolic links or Windows junctions are resolved properly
  root Pathname.new(SimpleCov.root).realpath.to_s
  minimum_coverage 95
end
require 'simplecov-cobertura'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ]
)

require 'fileutils'

require 'cleanroom'

RSpec.configure do |config|
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true

  # Force the expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Create and clear tmp_path on each run
  config.before do
    FileUtils.rm_rf(tmp_path)
    FileUtils.mkdir_p(tmp_path)
  end

  # Run specs in a random order
  config.order = 'random'
end

#
# The path on disk to the temporary directory.
#
# @param [String, Array<String>] paths
#   the extra path parameters to join
#
# @return [String]
#
def tmp_path(*paths)
  File.join('tmp', *paths)
end
