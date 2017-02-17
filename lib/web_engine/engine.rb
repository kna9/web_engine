module WebEngine
  class Engine < ::Rails::Engine
    isolate_namespace WebEngine
  end
end
