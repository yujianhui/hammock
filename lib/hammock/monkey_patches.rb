# TODO Oh dear lord these probably shouldn't be here. But that's OK for now. Because it's a spike!
# Yes, a spike. Nothing to see here.

class Object

  def symbolize
    self.to_s.underscore.to_sym
  end

end

# No, no, I swear, it was like this when I got here.

module ActiveRecord
  class Base

    def self.read_scope_for account
      raise "#{name}.read_scope_for isn't defined."
    end
    def self.index_scope_for account
      raise "#{name}.index_scope_for isn't defined."
    end
    def self.write_scope_for account
      raise "#{name}.write_scope_for isn't defined."
    end

    def self.visible_to account
      select &read_scope_for(account)
    end
    def visible_to? account
      self.class.read_scope_for(account).call(self)
    end

    def self.editable_by account
      select &write_scope_for(account)
    end
    def editable_by? account
      self.class.write_scope_for(account).call(self)
    end
    
    def self.indexable_by account
      select &index_scope_for(account)
    end
    def indexable_by? account
      self.class.index_scope_for(account).call(self)
    end
    
    def concise_inspect
      "#{self.class}<#{self.id || 'new'}>"
    end

    def self.base_model
      base_class.to_s.underscore
    end

    def base_model
      self.class.base_model
    end
    
    # TODO acts_as_paranoid or similar.
    def deleted?
      false
    end
  end
end
