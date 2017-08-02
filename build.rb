require 'simp/metadata'
require 'yaml'
require 'json'
require 'git'
require 'fpm'
require 'parallel'
require 'logger'

require 'pry'

@release = ARGV[0]
@iso     = ARGV[1]

@logger = Logger.new('build.log')

# make sure assets are checked out and at are the ref they're supposed to be at
def ensure_git_repo(path, data)
  @logger.debug "Opening git repo at #{path}"
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
  provides  = []
  obsoletes = []
  depends   = []
  conflicts = []
  replaces  = []
  lines.each do |line|
    @logger.debug line
    case line.strip
    when /^#/
      next
    when /^Requires:/
      requires << line
    when /^Provides:/
      provides << line
    when /^Obsoletes:/
      obsoletes << line
    when /^Depends:/
      depends << line
    when /^Conflicts:/
      conflicts << line
    when /^Replaces:/
      replaces << line
    end
  end
end

# build the rpm for the asset
def build_rpm(path, data)
  g = ensure_git_repo(path, data)
  type = detect_type(path)

  case type
  when :pupmod
    pupmod = File.basename(path)
    pup_meta = JSON.load(File.read(File.join(path,'metadata.json')))
    changelog_path = File.join(path,'CHANGELOG')
    cmd =  [ "fpm -s dir -t rpm -n pupmod-#{pup_meta['name']}" ]
    cmd << [ "--description \"#{pup_meta['summary']}\"" ]
    cmd << [ "--maintainer '#{pup_meta['author']}'" ]
    cmd << [ "--architecture noarch" ]
    cmd << [ "--license #{pup_meta['license']}" ]
    cmd << [ "--version #{pup_meta['version']}" ]
    cmd << [ "--package rpms" ]
    cmd << [ "--url #{pup_meta['source']}" ]
    cmd << [ "--rpm-digest sha512" ]
    cmd << [ "--rpm-changelog #{changelog_path}" ] if File.exists? changelog_path
    cmd << [ "#{path.split('').drop(2).join}=/usr/share/simp/modules" ]
    # binding.pry
    @logger.debug "Running command -- #{cmd.join(' ')}"
    output =  `#{cmd.join(' ')}`
    @logger.debug output
    return output
  when :doc
    # dumb python stuff
  when :asset
    # easy existing spec file stuff?
  end
end


def main
  metadata = Simp::Metadata::Engine.new(nil,['https://github.com/jeefberkey/simp-metadata'])
  rpmbuild_targets = metadata.list_components_with_data(@release)

  Dir.mkdir('rpms') unless File.exists? 'rpms'

  basedir = '.'
  rpmbuild_targets.each do |path, projects|
    workingdir = File.join(basedir, path)
    FileUtils.mkdir_p(workingdir) unless File.exists? workingdir

    Parallel.each(projects, progress: 'Building RPMS') do |pupmod, data|
      pupmod_name = pupmod.split('-')[1]
      mod_path = File.join(workingdir, pupmod_name)
      build_rpm(mod_path, data)
    end

  end
end

main()
