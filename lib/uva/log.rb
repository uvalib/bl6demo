# lib/uva/log.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'uva'

module UVA

  # UVA::Log
  #
  module Log

    include UVA

    LOG_LEVEL = {
      debug:   Logger::DEBUG,
      info:    Logger::INFO,
      warn:    Logger::WARN,
      error:   Logger::ERROR,
      fatal:   Logger::FATAL,
      unknown: Logger::UNKNOWN,
    }.freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # self.debug(*args)
    # self.info(*args)
    # self.warn(*args)
    # self.error(*args)
    # self.fatal(*args)
    # self.unknown(*args)
    #
    # @return [nil]
    #
    LOG_LEVEL.each_pair do |method, severity|
      module_eval <<-EOS
        def self.#{method}(*args)
          add(#{severity}, *args)
        end
      EOS
    end

    # Add a log message.
    #
    # @param [Integer, Symbol, String]  severity
    # @param [Array<Symbol, Exception, String>] args
    #
    # @return [nil]
    #
    # === Usage Notes
    # This method always returns *nil* so that it can be used by itself as the
    # final statement of a rescue block.
    #
    def self.add(severity, *args)
      unless severity.is_a?(Integer)
        severity = severity.to_s.downcase.to_sym
        severity = LOG_LEVEL[severity] || LOG_LEVEL[:unknown]
      end
      if Rails.logger.level <= severity
        message = []
        e = nil
        args.compact!
        args += Array.wrap(yield) if block_given?
        case args.first
          when Symbol # Calling method
            message << args.shift
            e = args.shift if args.first.is_a?(Exception)
          when Exception
            e = args.shift
            message << args.shift if args.first.is_a?(Symbol)
        end
        if e
          if [YAML::SyntaxError].include?(e)
            message << e.class
            message << "#{e.message}#{' - ' + args.shift if args.present?}"
          else
            message += args if args.present?
            message << "#{e.message} [#{e.class}]"
            args = nil
          end
        end
        message += args if args.present?
        Rails.logger.add(severity, message.join(': '))
      end
      nil
    end

  end

end

__loading_end(__FILE__)
