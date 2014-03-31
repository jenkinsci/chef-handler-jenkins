Gem::Specification.new do |g|
  g.name = 'chef-handler-jenkins'
  g.version = '0.1'

  g.summary = 'Chef report handler for tracking with Jenkins'
  g.description = 'Track deployment of files through Jenkins'
  g.authors = ['Kohsuke Kawaguchi']
  g.email = 'kk@kohsuke.org'
  g.homepage = 'http://jenkins-ci.org/'

  g.require_paths = ['lib']
  g.files = `git ls-files`.split($\)

  g.add_dependency 'chef', '>=11.6'
end