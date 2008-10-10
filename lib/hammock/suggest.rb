module Hammock
  module Suggest
    MixInto = ActiveRecord::Base

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def suggest given_fields, queries, limit = 15
        if (fields = given_fields & columns.map(&:name)).length != given_fields.length
          log "Invalid columns #{(given_fields - fields).inspect}."
        else
          find(:all,
            :limit => limit,
            :order => fields.map {|f| "#{f} ASC" }.join(', '),
            :conditions => [
              fields.map {|f|
                ([ "LOWER(#{table_name}.#{f}) LIKE ?" ] * queries.length).join(' AND ')
              }.map {|clause|
                "(#{clause})"
              }.join(' OR ')
            ].concat(queries.map{|q| "%#{q}%" } * fields.length)
          )
        end
      end

    end

    module InstanceMethods

    end
  end
end
