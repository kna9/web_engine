$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "web_engine/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "web_engine"
  s.version     = WebEngine::VERSION
  s.authors     = ["Karim Naghmouchi"]
  s.email       = ["karim@ecov.fr"]
  s.homepage    = "http://www.ecov.fr"
  s.summary     = "This engine is used to enable SI synchronises specific web models."
  s.description = "Enable custom web models to enable rails active record simplicity.."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.1"
  s.add_dependency "pg"
  # s.add_dependency "web-console", "~> 2.0"

  # s.add_development_dependency "sqlite3"


  #  s.name        = "kiosk"
  #  s.version     = Kiosk::VERSION
  #  s.authors     = ["François Delfort, Anthony Laibe, Thibaut Frain, Mélanie Lecomte, Ronan Limon Duparcmeur, Joël Cogen"]
  #  s.email       = ["dev@hospimedia.fr"]
  #  s.homepage    = ""
  #  s.summary     = "Ces modèles dépendent de ActiveRecord. Attention à veiller à ce que toutes les applications qui utilisent cette gem partagent la même BDD !"
  #  s.description = "Modèles communs aux applications Hospimedia (contenus)"
  #
  #  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "README.rdoc"]
  #  s.test_files = Dir["test/**/*"]
  #
  #  # Upgrade en 3.2.9 impossible à cause d'une incompatibilité avec sphinx
  #  s.add_dependency 'rails',                     '3.2.8'
  #  s.add_dependency 'rails-i18n',                '~> 0.7.1'
  #  s.add_dependency 'cancan',                    '~> 1.6.8'
  #  s.add_dependency 'state_machine',             '~> 1.1.2'
  #  s.add_dependency 'delayed_job_active_record', '~> 0.3.3'
  #  s.add_dependency 'paperclip',                 '~> 3.4.0'
  #  s.add_dependency 'aws-sdk',                   '~> 1.8.0'
  #  s.add_dependency 'business_time',             '~> 0.6.1'
  #  s.add_dependency 'nokogiri',                  '~> 1.5.6'
  #  s.add_dependency 'thinking-sphinx',           '2.0.13'
  #  s.add_dependency 'truncate_html',             '~> 0.5.5'
  #  s.add_dependency 'ffi-aspell',                '~> 0.0.3'
  #  s.add_dependency 'acts_as_list',              '~> 0.1.9'
  #  s.add_dependency 'geokit'
  #  s.add_dependency 'dalli',                     '~> 2.6.0'
  #  s.add_dependency 'bugsnag'
  #  s.add_dependency 'ts-delayed-delta',          '~> 1.1.3'
  #  s.add_dependency 'devise',                    '~> 2.1.3'
  #  s.add_dependency 'devise-encryptable'
  #  s.add_dependency 'enumerize',                 '~> 0.8.0'
end
