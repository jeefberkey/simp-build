# Variables:
#
# SIMP_GEM_SERVERS | a space/comma delimited list of rubygem servers
# PUPPET_VERSION   | specifies the version of the puppet gem to load
gem_sources   = ENV.key?('SIMP_GEM_SERVERS') ? ENV['SIMP_GEM_SERVERS'].split(/[, ]+/) : ['https://rubygems.org']

gem_sources.each { |gem_source| source gem_source }

# mandatory gems
gem 'simp-metadata'
gem 'git'
gem 'fpm'
gem 'parallel'
gem 'ruby-progressbar'
gem 'pry'

#vim: set syntax=ruby:
