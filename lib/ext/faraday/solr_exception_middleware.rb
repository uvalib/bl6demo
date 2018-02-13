# lib/ext/faraday/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'faraday'

module Faraday

  # Error handling for Solr results.
  #
  # === Implementation Notes
  # It's not clear whether this is a useful addition; RSolr may already handle
  # errors well enough on its own.
  #
  class SolrExceptionMiddleware < Faraday::Middleware

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize
    #
    # @param [Faraday::Middleware] app
    #
    # TODO: this override may not be required
    #
    def initialize(app)
      super(app)
    end

    # call
    #
    # @param [Faraday::Env] env
    #
    # @return [Faraday::Response, nil]
    #
    def call(env)
      @app.call(env).on_complete do |response|
        $stderr.puts("!!!!!!!!!!!!! Faraday response status #{response.status.inspect}")
=begin
        case response.status
          when 200
          when 400
            raise EBSCO::EDS::BadRequest.new(error_message(response))
          # when 401
          #   raise EBSCO::EDS::Unauthorized.new
          # when 403
          #   raise EBSCO::EDS::Forbidden.new
          # when 404
          #   raise EBSCO::EDS::NotFound.new
          # when 429
          #   raise EBSCO::EDS::TooManyRequests.new
          when 500
            raise EBSCO::EDS::InternalServerError.new
          when 503
            raise EBSCO::EDS::ServiceUnavailable.new
          else
            raise EBSCO::EDS::BadRequest.new(error_message(response))
        end
=end
      end
    rescue Faraday::ConnectionFailed => e # NOTE: 0% coverage for this case
      $stderr.puts "!!!!!!!!!! Faraday::ConnectionFailed caught #{e}"
      raise RSolr::Error::ConnectionRefused, env.inspect

    rescue Faraday::ResourceNotFound => e # NOTE: 0% coverage for this case
      $stderr.puts "!!!!!!!!!! Faraday::ResourceNotFound caught #{e}"
      #raise RSolr::Error::xxx, env.inspect
      raise

    rescue Faraday::ParsingError => e # NOTE: 0% coverage for this case
      $stderr.puts "!!!!!!!!!! Faraday::ParsingError caught #{e}"
      #raise RSolr::Error::xxx, env.inspect
      raise

    rescue Faraday::TimeoutError => e
      $stderr.puts "!!!!!!!!!! Faraday::TimeoutError caught #{e}"
      #raise RSolr::Error::xxx, env.inspect
      raise

    rescue Faraday::SSLError => e # NOTE: 0% coverage for this case
      $stderr.puts "!!!!!!!!!! Faraday::SSLError caught #{e}"
      #raise RSolr::Error::xxx, env.inspect
      raise

    rescue Faraday::ClientError => e # NOTE: 0% coverage for this case
      $stderr.puts "!!!!!!!!!! Faraday::ClientError caught #{e}"
      #raise RSolr::Error::xxx, env.inspect
      raise

    rescue Faraday::MissingDependency => e # NOTE: 0% coverage for this case
      $stderr.puts "!!!!!!!!!! Faraday::MissingDependency caught #{e}"
      raise

    rescue Faraday::Error => e # NOTE: 0% coverage for this case
      $stderr.puts "!!!!!!!!!! Faraday::Error caught #{e}"
      raise RSolr::Error::Http.new(env, e.response)

    rescue Exception => e # NOTE: 0% coverage for this case
      $stderr.puts "!!!!!!!!!! Faraday caught #{e}"
      raise

    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

=begin
    # error_message
    #
    # @param [Faraday::Response] response
    #
    # @return [Hash]
    #
    def error_message(response)
      #puts response.inspect
      {
          method:     response.method,
          url:        response.url,
          status:     response.status,
          error_body: response.body
      }
    end
=end

  end

end

__loading_end(__FILE__)
