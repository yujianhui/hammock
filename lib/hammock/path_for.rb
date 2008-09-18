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
      RouteTemplates = Hash.new {|hsh, k|
        "#{k}_record_path"
      }.update(
        :index => 'records_path',
        :create => 'records_path',
        :show => 'record_path',
        :update => 'record_path',
        :destroy => 'record_path'
      )

      HTTPMethods = Hash.new(
        :get
      ).update(
        :create => :post,
        :update => :put,
        :destroy => :delete,
        :undestroy => :post
      )

      def verb_for requested_verb, record
        requested_verb ||= :show
        
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

      def path_for *resources
        opts = resources.last.is_a?(Hash) ? resources.pop.symbolize_keys! : {}

        [ :controller, :action, :id ].each {|key|
          raise ArgumentError, "path_for() infers :#{key} from the resources you provided, so you don't need to specify it manually." if opts.delete key
        }

        requested_verb = resources.shift if resources.first.is_a?(Symbol)
        record, parent_records = resources.shift, [ ]

        model_name = record.base_model
        verb = verb_for requested_verb, record
        path = RouteTemplates[verb].sub('records', model_name.pluralize).sub('record', model_name)

        if respond_to? path
          # Already succeeded
        elsif resources.empty?
          log "Failed to generate path: '#{path}'"
        else
          # Base path didn't exist; let's try traversing the route heirachy.
          path_builder = path

          path = resources.each {|resource|
            path_builder = "#{resources.first.base_model}_#{path_builder}"
            parent_records.unshift resource
            # log "building: #{path_builder}"
            break path_builder if respond_to? path_builder
          }
        end

        if respond_to? path
          args_for_send = []
          args_for_send << record unless recordless_verb? verb
          args_for_send.concat parent_records
          args_for_send << opts unless opts.empty?

          # dlog "Generated path #{path}(#{args_for_send.map(&:concise_inspect).join(', ')})."
          send path, *args_for_send
        else
          raise "Neither '#{path}' nor '#{path_builder}' are valid routes."
        end
      end

      def new_path_for     *args; path_for :new,     *args end
      def edit_path_for    *args; path_for :edit,    *args end
      def create_path_for  *args; path_for :create,  *args end
      def update_path_for  *args; path_for :update,  *args end
      def destroy_path_for *args; path_for :destroy, *args end
      
      private
      
      def recordless_verb? verb
        [ :index, :create, :new ].include? verb.to_sym
      end

    end
  end
end
