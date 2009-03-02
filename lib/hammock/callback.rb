module Hammock

  class Callback < ActiveSupport::Callbacks::Callback
    private

    def evaluate_method method, *args, &block
      if method.is_a? Proc
        # puts "was a Hammock::Callback proc within #{args.first.class}."
        method.bind(args.shift).call(*args, &block)
      else
        super
      end
    end
  end

end
