# app/models/concerns/blacklight/configurable_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Blacklight::ConfigurableExt
#
# @see Blacklight::Configurable
#
module Blacklight::ConfigurableExt

  extend ActiveSupport::Concern

  include Blacklight::Configurable
  include LensHelper

  # Code to be added to the controller class including this module.
  included do |base|
    __included(base, 'Blacklight::ConfigurableExt')
=begin # NOTE: using base version
    helper_method :blacklight_config if respond_to? :helper_method
=end
  end

  # ===========================================================================
  # :section: Blacklight::Configurable overrides
  # ===========================================================================

  public

  # Instance methods for blacklight_config, so get a deep copy of the
  # class-level config.
  #
  # @return [Blacklight::Configuration]
  #
  # This method overrides:
  # @see Blacklight::Configurable#blacklight_config
  #
  def blacklight_config(name = nil)
    if name
      blacklight_config_for(name)
    else
      unless @blacklight_config
        $stderr.puts "!!! [Configurable] setting blacklight_config for " \
          "instance #{self} from #{lens_key_for(nil)}" # TODO: debugging - delete
          #raise LoadError unless @blacklight_config # TODO: restore?
      end
      @blacklight_config ||= current_blacklight_config
    end
  rescue => e
    logger.warn [
      "[Configurable] #{e}",
      "class #{self.class}",
      "ancestors #{self.class.ancestors}"
    ].join("\n  ")
    raise e
  end

=begin # NOTE: using base version
  # @return [Blacklight::Configuration]
  attr_writer :blacklight_config
=end

  # ===========================================================================
  # :section: Blacklight::Configurable::ClassMethods overrides
  # ===========================================================================

  public

  module ClassMethods

    include Blacklight::Configurable
    include LensHelper

=begin # NOTE: using base version
=end
    # copy_blacklight_config_from
    #
    # @param [#blacklight_config] other_class
    #
    # @return [Blacklight::Configuration]
    #
    # This method overrides:
    # @see Blacklight::Configurable::ClassMethods#copy_blacklight_config_from
    #
    def copy_blacklight_config_from(other_class)
      $stderr.puts("!!! [Configurable] copy blacklight_config to #{self} class from #{other_class}") # TODO: debugging - remove
      self.blacklight_config = other_class.blacklight_config.inheritable_copy
    end

    # Lazy-load a deep_copy of superclass configuration if present (or a
    # default_configuration if not), which will be legacy load or new empty
    # config.
    #
    # Note that the @blacklight_config variable is a Ruby
    # "instance method on class object" that won't be automatically available
    # to subclasses, that's why we lazy load to "inherit" how we want.
    #
    # @param [String, Symbol, ..., nil] name
    #
    # @return [Blacklight::Configuration]
    #
    # This method overrides:
    # @see Blacklight::Configurable::ClassMethods#blacklight_config
    #
    def blacklight_config(name = nil)
      if name # NOTE: 0% coverage for this case
        blacklight_config_for(name)
      else
        $stderr.puts("!!! [Configurable] setting blacklight_config for #{self} from #{lens_key_for(nil)}") unless @blacklight_config # TODO: debugging - remove
        @blacklight_config ||= current_blacklight_config
      end
    end

=begin # NOTE: using base version
    # @return [Blacklight::Configuration]
    attr_writer :blacklight_config
=end

=begin # NOTE: using base version
    # Simply a convenience method for blacklight_config.configure
    #
    # @param [Array] args
    #
    # @return [Blacklight::Configuration]
    #
    # This method overrides:
    # @see Blacklight::Configurable::ClassMethods#configure_blacklight
    #
    def configure_blacklight(*args, &block)
      blacklight_config.configure(*args, &block)
    end
=end

=begin # NOTE: using base version
    # The default configuration object.
    #
    # @return [Blacklight::Configuration]
    #
    # This method overrides:
    # @see Blacklight::Configurable::ClassMethods#default_configuration
    #
    def default_configuration
      Blacklight::Configurable.default_configuration.inheritable_copy
    end
=end

  end

  # ===========================================================================
  # :section: Blacklight::Configurable class method overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  # Get default configuration.
  #
  # @return [Blacklight::Configuration]
  #
  # This method overrides:
  # @see Blacklight::Configurable#default_configuration
  #
  def self.default_configuration
    @default_configuration ||= Blacklight::Configuration.new
  end
=end

=begin # NOTE: using base version
  # Set default configuration.
  #
  # @return [Blacklight::Configuration]
  #
  # This method overrides:
  # @see Blacklight::Configurable#default_configuration=
  #
  def self.default_configuration=(config)
    @default_configuration = config
  end
=end

end

__loading_end(__FILE__)
