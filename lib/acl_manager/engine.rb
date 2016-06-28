Gem.loaded_specs['acl_manager'].dependencies.each{ |d| require d.name }

module AclManager
  class Engine < ::Rails::Engine
    isolate_namespace AclManager
    initializer :append_migrations do |app|
		  unless app.root.to_s.match(root.to_s)
  			config.paths["db/migrate"].expanded.each do |p|
  				app.config.paths["db/migrate"] << p
  			end
  		end
	  end
    initializer :load_config_initializers do |app|
      ActiveRecord::Base.send(:include, AclManager)
    end

    ActiveSupport.on_load(:action_controller) do
      class_eval do
        def method_missing(m, *args, &block)
          if m.match /authorizate_(.*)!/
            send authorizate_resource($1)
          else
            super
          end
        end

        def authorizate_resource(resource_name)
          define_singleton_method "authorizate_#{resource_name}!" do
            resource = request.env["warden"].user
            AclManager::Filter.before(self, resource) if resource
          end
        end
      end
    end
  end
end
