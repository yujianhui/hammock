module Hammock
  module Logging
    MixInto = ActionController::Base

    def self.included base
      base.send :include, Methods
      base.send :extend, Methods

      base.class_eval {
        helper_method :log
      }
    end

    module Methods

      def log_hit
        log_concise [
          request.remote_ip.colorize('green'),
          (@current_site.subdomain unless @current_site.nil?),
          (request.session_options[:id].nil? ? 'nil' : ('...' + request.session_options[:id][-8, 8])),
          (current_user.nil? ? "unauthed" : "Account<#{current_user.id}> #{current_user.name}").colorize('green'),
          headers['Status'],
          log_hit_request_info,
          log_hit_route_info
        ].squash.join(' | ')
      end

      def log_hit_request_info
        (request.xhr? ? 'XHR/' : '') +
        (params[:_method] || request.method).to_s.upcase +
        ' ' +
        request.request_uri.colorize('grey', '?')
      end
      
      def log_hit_route_info
        params[:controller] +
        '#' +
        params[:action] +
        ' ' +
        params.discard(:controller, :action).inspect.gsub("\n", '\n').colorize('grey')
      end

      def log_concise msg, report = false
        buf = "#{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')} | #{msg}\n"
        path = File.join RAILS_ROOT, 'log', rails_env

        File.open("#{path}.concise.log", 'a') {|f| f << buf }
        File.open("#{path}.report.log", 'a') {|f| f << buf } if report

        nil
      end

      def report *args
        opts = args.extract_options!
        log *(args << opts.merge(:report => true, :skip => (opts[:skip] || 0) + 1))
        log caller.remove_framework_backtrace.join("\n")
      end

      def dlog *args
        unless production?
          opts = args.extract_options!
          log *(args << opts.merge(:skip => (opts[:skip] || 0) + 1))
        end
      end

      def log_fail *args
        log *(args << opts.merge(:skip => (opts[:skip] || 0) + 1))
        false
      end

      def log *args
        opts = {
          :skip => 0
        }.merge(args.extract_options!)

        msg = if opts[:error]
          "#{ErrorPrefix}: #{opts[:error]}"
        elsif args.first.is_a? String
          args.first
        elsif args.all? {|i| i.is_a?(ActiveRecord::Base) }
          @errorModels = args unless opts[:errorModels] == false
          args.map {|record| "#{record.inspect}: #{record.errors.full_messages.inspect}" }.join(', ')
        else
          args.map(&:inspect).join(', ')
        end

        msg.colorize!('on red') if opts[:error] || opts[:report]

        callpoint = caller[opts[:skip]].sub(rails_root.end_with('/'), '')
        entry = "#{callpoint}#{msg.blank? ? (opts[:report] ? ' <-- something broke here' : '.') : ' | '}#{msg}"

        logger.send opts[:error].blank? ? :info : :error, entry # Write to the Rails log
        log_concise entry, opts[:report] # Also write to the concise log
      end

    end
  end
end
