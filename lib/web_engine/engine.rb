module WebEngine
  class Engine < ::Rails::Engine
    isolate_namespace WebEngine
    config.autoload_paths += Dir["#{config.root}/app/services/**"]
  end
end
