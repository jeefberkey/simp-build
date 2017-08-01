require 'simp/metadata'
require 'yaml'
require 'json'
require 'git'
require 'fpm'

require 'pry'

@release = ARGV[0]
@iso     = ARGV[1]

# make sure assets are checked out and at are the ref they're supposed to be at
def ensure_git_repo(path, data)
  puts "Opening git repo at #{path}"
  if File.exists? path
    g = Git.open(path)
  else
    git_url = "#{data['type']}://#{data['source']['primary_source']['host']}/#{data['source']['primary_source']['path']}"
    g = Git.clone(git_url, path)
  end
  g.remote('origin').fetch
  g.checkout(data['ref'])
  g
end

# detect what type of rpm to build
def detect_type(path)
  case path
  when /doc/
    return :doc
  when /puppet\/module/
    return :pupmod
  when /asset/
    return :asset
  end
end

# read the build/rpm_metadata/requires file and turn it into fpm arguments
def parse_requires(path)
  lines = File.readline(File.join(path,'build','rpm_metadata','requires'))
  requires  = []
  depends   = []
  provides  = []
  conflicts = []
  replaces  = []
  lines.each do |line|
    case line.strip
    when /^#/
      next
    when /^Requires:/
      requires << line
    when /^Provides:/
      provides << line
    when /^Obsoletes:/
      obsoletes << line
  end
end

# build the rpm for the asset
def build_rpm(path, data)
  g = ensure_git_repo(path, data)
  type = detect_type(path)
  Dir.chdir(path) do
    case type
    when :pupmod
      pupmod = File.basename(path)
      pup_meta = JSON.load(File.read('metadata.json'))
      cmd =  [ "fpm -s dir -t rpm -n pupmod-#{pup_meta['name']}" ]
      cmd << [ "--description \"#{pup_meta['summary']}\"" ]
      cmd << [ "--maintainer '#{pup_meta['author']}'" ]
      cmd << [ "--architecture noarch" ]
      cmd << [ "--license #{pup_meta['license']}" ]
      cmd << [ "--version #{pup_meta['version']}" ]
      cmd << [ "--package rpms" ]
      cmd << [ "--url #{pup_meta['source']}" ]
      cmd << [ "--rpm-digest sha512" ]
      cmd << [ "--rpm-changelog #{File.join(path,'CHANGELOG')}" ]
      cmd << [ "#{path.split('').drop(2).join}=/usr/share/simp/modules" ]
      binding.pry
    when :doc
      # dumb python stuff
    when :asset
      # easy existing spec file stuff?
    end
    # `fpm -s dir -t rpm -n pupmod-simp-acpid src/puppet/modules/#{pupmod}=/usr/share/simp/modules`
  end
end


def main
  metadata = Simp::Metadata::Engine.new(nil,['https://github.com/jeefberkey/simp-metadata'])
  rpmbuild_targets = metadata.list_components_with_data(@release)

  Dir.mkdir('rpms') unless File.exists? 'rpms'

  basedir = '.'
  rpmbuild_targets.each do |path, projects|
    workingdir = File.join(basedir, path)
    FileUtils.mkdir_p(workingdir) unless (File.exists? workingdir and File.directory? workingdir )
    projects.each do |pupmod, data|
      pupmod_name = pupmod.split('-')[1]
      mod_path = File.join(workingdir, pupmod_name)
      build_rpm(mod_path, data)
    end
  end
  binding.pry
end

main()
