module Hammock
  module PathFor
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        helper_method :method_for, :path_for, :nested_path_for, :verb_for
      }
    end

    module ClassMethods
    end

    module InstanceMethods
      private

      # TODO Get this from the routing table, like a real man, not some god damn nancy :get-defaulting Hash. JESUS.
      HTTPMethods = Hash.new(
        :get
      ).update(
        :create => :post,
        :update => :put,
        :destroy => :delete,
        :undestroy => :post
      )

      def verb_for requested_verb, record
        requested_verb = :show if requested_verb.blank?
        
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
        args.delete_if &:nil?
        opts = args.last.is_a?(Hash) ? args.pop.symbolize_keys! : {}

        [ :controller, :action, :id ].each {|key|
          raise ArgumentError, "path_for() infers :#{key} from the resources you provided, so you don't need to specify it manually." if opts.delete key
        }

        requested_verb = args.shift if args.first.is_a?(Symbol)
        verb = verb_for requested_verb, args.last
        resource = args.pop.resource if recordless_verb?(verb) || !args.last.is_a?(ActiveRecord::Base)

        path = []
        path << verb unless implied_verb?(verb)
        path.concat args.map(&:base_model)
        path << resource.base_model.send_if(plural_verb?(verb), :pluralize) unless resource.nil?
        path << 'path'

        args.push({(resource || args.last).base_model => opts[:params]}) unless opts[:params].blank?

        # log "sending #{path.compact.join('_')}(#{args.map(&:inspect).join(', ')})"
        send path.compact.join('_'), *args
      end

      def nested_path_for *resources
        resources.delete_if &:nil?
        requested_verb = resources.shift if resources.first.is_a?(Symbol)
        args = @current_nested_records.dup.concat(resources)

        args.unshift(requested_verb) unless requested_verb.nil?
        path_for *args
      end


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
