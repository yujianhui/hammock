module Hammock
  module Scope
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        helper_method :can_verb_entity?
      }
    end

    module ClassMethods
    end

    module InstanceMethods
      private

      def can_verb_entity? verb, entity
        if entity.is_a? ActiveRecord::Base
          can_verb_record? verb, entity
        else
          can_verb_resource? verb, entity
        end == :ok
      end

      def can_verb_resource? verb, resource
        raise "The verb at #{call_point} must be supplied as a Symbol." unless verb.nil? || verb.is_a?(Symbol)
        route = route_for verb, resource
        if route.safe? && !resource.indexable_by(current_user)
          log "#{requester_name} can't index #{resource.name.pluralize}. #{describe_call_point 4}"
          :not_found
        elsif !route.safe? && !make_createable(resource)
          log "#{requester_name} can't #{verb} #{resource.name.pluralize}. #{describe_call_point 4}"
          :read_only
        else
          # log "#{requester_name} can #{verb} #{resource.name.pluralize}."
          :ok
        end
      end

      def can_verb_record? verb, record
        raise "The verb at #{call_point} must be supplied as a Symbol." unless verb.nil? || verb.is_a?(Symbol)
        route = route_for verb, record
        if route.verb.in?(:save, :create) && record.new_record?
          if !record.createable_by?(current_user)
            log "#{requester_name} can't create a #{record.class} with #{record.attributes.inspect}. #{describe_call_point 4}"
            :unauthed
          else
            :ok
          end
        else
          if !record.readable_by?(current_user)
            log "#{requester_name} can't see #{record.class}<#{record.id}>. #{describe_call_point 4}"
            :not_found
          elsif !route.safe? && !record.writeable_by?(current_user)
            log "#{requester_name} can't #{verb} #{record.class}<#{record.id}>. #{describe_call_point 4}"
            :read_only
          else
            # log "#{requester_name} can #{verb} #{record.class}<#{record.id}>."
            :ok
          end
        end
      end

      def current_verb_scope
        if current_user && (scope_name = account_verb_scope?)
          # log "got an account_verb_scope #{scope_name}."
          mdl.send scope_name, current_user
        elsif !(scope_name = public_verb_scope?)
          log "No #{current_user.nil? ? 'public' : 'account'} #{scope_name_for_action} scope available for #{mdl}.#{' May be available after login.' if account_verb_scope?}"
          nil
        else
          # log "got a #{scope_name} public_verb_scope."
          mdl.send scope_name
        end
      end

      def nesting_scope_list
        @hammock_cached_nesting_scope_list = current_hammock_resource.parent.nesting_scope_list_for params.selekt {|k,v| /_id$/ =~ k }
      end

      def current_nest_scope
        nesting_scope_list.reverse.inject {|acc,scope| acc.within scope }
      end

      def current_scope
        log "#{current_hammock_resource.mdl}, #{current_hammock_resource.ancestry.map(&:mdl).inspect}"
        if (verb_scope = current_verb_scope).nil?
          nil
        elsif (resultant_scope = verb_scope.within(current_nest_scope, current_hammock_resource.routing_parent)).nil?
          nil
        else
          # puts "nest: #{current_nest_scope.clauses.inspect}"
          # puts "verb: #{current_verb_scope.clauses.inspect}"
          puts "chained in (#{resultant_scope.owner}) current_scope: #{resultant_scope.clauses.inspect}"
          resultant_scope = resultant_scope.chain(custom_scope) unless custom_scope.nil?
          resultant_scope.sort_by &mdl.sorter
        end
      end


      private

      def scope_name_for_action
        if 'index' == action_name
          'index'
        elsif safe_verb_and_implication?
          'read'
        else
          'write'
        end
      end

      def requester_name
        current_user.nil? ? 'Anonymous' : "#{current_user.class}<#{current_user.id}>"
      end

      def account_verb_scope?
        mdl.has_account_scope? scope_name_for_action
      end
      def public_verb_scope?
        mdl.has_public_scope? scope_name_for_action
      end

    end
  end
end
