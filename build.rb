require 'simp/metadata'
require 'yaml'
require 'git'
require 'fpm'

require 'pry'

@release = ARGV[0]
@iso     = ARGV[1]

# make sure assets are checked out and at are the ref they're supposed to be at
def ensure_git_repo(path, data)
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

# build the rpm for the asset
def build_rpm(path, data)
  g = ensure_git_repo(path, data)
  Dir.chdir(path) do
    pupmod = File.basename(path)
    # f = FPM::Package::RPM.new
    # f.digest_algorithm = 'sha1'
    # f.directories << path
    `fpm -s dir -t rpm -n pupmod-simp-acpid src/puppet/modules/#{pupmod}=/usr/share/simp/modules`
  end
end


def main
  metadata = Simp::Metadata::Engine.new(nil,['https://github.com/jeefberkey/simp-metadata'])
  rpmbuild_targets = metadata.list_components_with_data(@release)

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
