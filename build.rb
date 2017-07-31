require 'simp/metadata'
require 'yaml'

require 'pry'

metadata = Simp::Metadata::Engine.new('data')

release = ARGV[0]

