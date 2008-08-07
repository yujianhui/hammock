module Hammock
  module PathFor
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        helper_method :method_for, :update_path_for,
          :path_for, :new_path_for, :edit_path_for, :create_path_for, :update_path_for, :destroy_path_for
      }
    end

    module ClassMethods
    end

    module InstanceMethods
      RouteTemplates = Hash.new {|hsh, k| "#{k}_record_path" }
      RouteTemplates.update(
        :index => 'records_path',
        :create => 'records_path',
        :show => 'record_path',
        :update => 'record_path',
        :destroy => 'record_path'
      )

      HTTPMethods = Hash.new :get
      HTTPMethods.update(
        :create => :post,
        :update => :put,
        :destroy => :delete,
        :undelete => :post,
        :suggest => :get
      )

      def verb_for requested_verb, record
        if (:show == requested_verb) && record.is_a?(Class)
          :index
        elsif :modify == requested_verb
          record.new_record? ? :new : :edit
        elsif :save == requested_verb
          record.new_record? ? :create : :update
        else
          requested_verb
        end
      end

      def method_for requested_verb, record
        HTTPMethods[verb_for(requested_verb, record)]
      end

      def path_for *args
        opts = args.last.is_a?(Hash) ? args.pop : {}
        requested_verb = args.first.is_a?(Symbol) ? args.shift : :show
        resources = args
        record, record_list = resources.shift, [ ]

        [ :controller, :action, :id ].each {|key|
          raise ArgumentError, "path_for() infers :#{key} from the resources you provided, so you don't need to specify it manually." if opts.delete key
        }

        model_name = record.base_model
        recordless_paths = [ :index, :create, :new ].freeze
        verb = verb_for requested_verb, record
        path = RouteTemplates[verb].sub('records', model_name.pluralize).sub('record', model_name)

        unless respond_to? path
          # Base path didn't exist; let's try traversing the route heirachy.
          path_builder = path

          path = resources.each {|resource|
            path_builder = "#{record_list.first.parent.base_model}_#{path_builder}"
            record_list.unshift resource
            log "building: #{nested_path}"
            break path_builder if respond_to? path_builder
          }
        end

        if respond_to? path
          args_for_send = []
          args_for_send << record unless recordless_paths.include? verb
          args_for_send.concat record_list
          args_for_send << opts unless opts.empty?

          dlog "Generated path #{path}(#{args_for_send.map(&:inspect).join(', ')})."
          send path, *args_for_send
        else
          raise "Neither #{path} nor #{path_builder} are valid routes."
        end
      end

      def new_path_for     *args; path_for :new,     *args end
      def edit_path_for    *args; path_for :edit,    *args end
      def create_path_for  *args; path_for :create,  *args end
      def update_path_for  *args; path_for :update,  *args end
      def destroy_path_for *args; path_for :destroy, *args end

    end
  end
end
