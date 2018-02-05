# app/controllers/concerns/config/_base.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Config

  # Config::Base
  #
  module Base

    extend ActiveSupport::Concern

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a self instance.
    #
    # @param [Symbol]                    key
    # @param [Blacklight::Configuration] config
    #
    def initialize(key, config)
      @key    = key
      self.key ||= key
      Blacklight::Lens[@key] ||= Blacklight::Lens.new(@key, config)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Methods associated with the configuration class.
    #
    module ClassMethods

      # =======================================================================
      # :section: Class methods
      # =======================================================================

      public

      # The lens key for the configuration class.
      #
      # @return [Symbol]
      #
      attr_reader :key

      # The Blacklight configuration associated with the configuration class.
      #
      # @return [Blacklight::Configuration]
      #
      def blacklight_config
        Blacklight::Lens[@key].blacklight_config
      end

      # Make a deep copy of the Blacklight configuration.
      #
      # @return [Blacklight::Configuration]
      #
      def deep_copy
        blacklight_config.deep_copy
      end

      # =======================================================================
      # :section: Class methods
      # =======================================================================

      protected

      # Internally, allow assignment to the lens key for the configuration
      # class.
      #
      # @return [Symbol]
      #
      attr_writer :key

    end

    # Define these as instance methods as well as class methods.
    #
    include ClassMethods

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  autoload :Articles, 'config/articles'
  autoload :Catalog,  'config/catalog'

end

__loading_end(__FILE__)
