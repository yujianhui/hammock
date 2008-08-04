class Object

  def symbolize
    self.to_s.underscore.to_sym
  end

end
