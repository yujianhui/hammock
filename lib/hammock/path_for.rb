module Hammock
  module PathFor
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        helper_method :method_for, :path_for, :nested_path_for
      }
    end

    module ClassMethods
    end

    module InstanceMethods

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
        resource = resources.pop unless resources.last.is_a?(ActiveRecord::Base)
        verb = verb_for requested_verb, (resource || resources.last)

        path = []
        path << verb unless implied_verb?(verb)
        path.concat resources.map(&:base_model)
        path << resource.base_model.send_if(plural_verb?(verb), :pluralize) unless resource.nil?
        path << 'path'

        # log path.inspect

        send path.compact.join('_'), *resources
      end

      def nested_path_for *resources
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
