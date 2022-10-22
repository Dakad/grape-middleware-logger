require 'rack/head'

class Grape::Middleware::Logger
  module RackHeadOverride
    def call(env)
      response = super
      status, _, rack = *response
      response_object = JSON.parse(rack.body.try(:first) || '{}').with_indifferent_access

      if env && env['grape.middleware.log'].present?
        logger = env['grape.middleware.logger']
        log = env['grape.middleware.log']
        log[:status] = response[0]
        log[:runtime] = ((log[:end_time] - log[:start_time]) * 1000).round(2)

        log[:exception] = response_object[:code] if response_object[:code].present?
        log[:message] = response_object[:error] if response_object[:error].present?

        unless log[:render_json]
          logger.info ''
          logger.info %Q(Started %s "%s" at %s) % [
            log[:request_method],
            log[:path],
            log[:start_time].to_s
          ]
          logger.info %Q(Processing by #{log[:processed]})
          logger.info %Q(  Parameters: #{log[:parameters]})
          logger.info %Q(  Headers: #{log[:headers]}) if log[:headers].present?
          logger.info %Q(  Remote IP: #{log[:remote_ip]})
          logger.info "Completed #{status} in #{runtime}ms"
          logger.info ''
          # log_info(log)
        else
          logger.info log.to_json
        end
      end

      response
    end

    # private

    # def log_info(log_statements=[])
    #   if @options[:condensed]
    #     logger.info log_statements.compact.delete_if(&:empty?).each(&:strip!).join(" - ")
    #   else
    #     log_statements.each { |log_statement| logger.info log_statement }
    #   end
    # end
  end
end

Rack::Head.prepend Grape::Middleware::Logger::RackHeadOverride




