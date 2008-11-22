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

      def rails_env
        ENV['RAILS_ENV'] || 'development'
      end
      def development?
        'development' == rails_env
      end
      def production?
        'production' == rails_env
      end

      def log_hit
        buf = "#{colorify request.remote_ip}" +
          (@current_site.nil? ? '' : " | #{@current_site.name}") +
          " | #{session.nil? ? 'nil' : (session.session_id[0, 8] + '...' + session.session_id[-8, 8])}/" +
          colorify(@current_account.nil? ? "unauthed " : "Account<#{@current_account.id}> #{@current_account.name}") +
          " | #{headers['Status']} | #{'XHR/' if request.xhr?}#{(params[:_method] || request.method).to_s.upcase} #{request.request_uri} | #{params[:controller]}\##{params[:action]} #{params.discard(:controller, :action).inspect.gsub("\n", '\n')}"

        log_concise buf
      end

      def log_concise msg, report = false
        buf = "#{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')} | #{msg}\n"
        path = File.join RAILS_ROOT, 'log', rails_env

        File.open("#{path}.concise.log", 'a') {|f| f << buf }
        File.open("#{path}.report.log", 'a') {|f| f << buf } if report

        raise buf if report unless production?
        nil
      end

      def report *args
        opts = args.last.is_a?(Hash) ? args.pop : {}
        log *(args << opts.merge(:report => true, :skip => (opts[:skip] || 0) + 1))
        log caller.join("\n")
      end

      def dlog *args
        unless production?
          opts = args.last.is_a?(Hash) ? args.pop : {}
          log *(args << opts.merge(:skip => (opts[:skip] || 0) + 1))
        end
      end

      def log *args
        opts = {
          :skip => 0
        }.merge(args.last.is_a?(Hash) ? args.pop : {})

        msg = if opts[:error]
          "#{ErrorPrefix}: #{opts[:error]}"
        elsif args.first.is_a? String
          args.first
        elsif args.all? {|i| i.is_a?(ActiveRecord::Base) }
          @errorModels = args unless opts[:errorModels] == false
          args.map {|record| "#{record.inspect}: #{record.errors.full_messages.inspect}" }.join(', ')
        else
          args.map(&:to_s).join(', ')
        end

        file = caller[opts[:skip]].gsub(/^.*\/([^\/\:]*\:[0-9]*)\:.*$/, '\1')
        method = caller[opts[:skip]].gsub(/^.*\`([^\`\']*)\'.*$/, '\1')

        entry = "#{file} / #{method}#{msg.blank? ? (opts[:report] ? ' <-- something broke here' : '.') : ' | '}#{msg}"

        logger.send opts[:error].blank? ? :info : :error, entry # Write to the Rails log
        log_concise entry, opts[:report] # Also write to the concise log
      end


      private

      ColorMap = {
        :black => 30,
        :red => 31,
        :green => 32,
        :yellow => 33,
        :blue => 34,
        :pink => 35,
        :cyan => 36,
      }.freeze

      def colorify str, color = :green
        "\e[0;#{ColorMap[color]};1m#{str}\e[0m"
      end

    end
  end
end
