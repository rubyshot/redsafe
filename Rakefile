require 'rubygems'
require 'rake'
task "default" => ["test"]
begin
require 'jeweler'
  require 'lib/redsafe/version'
  Jeweler::Tasks.new do |gem|
    gem.name = "redsafe"
    gem.version = Redsafe::Version::STRING
    gem.description = "Red Safe is a conveyor belt to get your web-based project on a fast roll."
    gem.summary = "This is a gem tool which simplifies signup functionality using various web services for connection credentials."
    gem.homepage = "http://github.com/rubyshot/redsafe"
    gem.author = "Ruby Shot"
    gem.email = "domochoice(at)yahoo:com"
    gem.add_development_dependency "sinatra"
    gem.add_development_dependency "dm-core"
    gem.add_development_dependency "dm-validations"
    gem.add_development_dependency "dm-timestamps"
    gem.add_development_dependency "date"
    gem.add_development_dependency "time"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end






