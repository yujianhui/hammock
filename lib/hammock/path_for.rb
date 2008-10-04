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
        resources.flatten!
        record_or_resource = resources.pop

        model_name = record_or_resource.base_model
        verb = verb_for requested_verb, record_or_resource
        path_tip = "record#{'s' if plural_verb?(verb)}_path".sub('records', model_name.pluralize).sub('record', model_name)

        path = [
          (verb unless implied_verb?(verb)),
          resources.map(&:base_model),
          path_tip
        ].flatten.compact.join('_')

        if respond_to? path
          args_for_send = []
          args_for_send << record_or_resource unless recordless_verb? verb
          args_for_send.concat resources
          args_for_send << opts unless opts.empty?

          # dlog "Generated path #{path}(#{args_for_send.map(&:concise_inspect).join(', ')})."
          send path, *args_for_send
        else
          raise "'#{path}' is not a valid route."
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

      def plural_verb? verb
        [ :index, :create ].include? verb.to_sym
      end

      def implied_verb? verb
        [ :index, :create, :show, :update, :destroy ].include? verb.to_sym
      end

    end
  end
end
