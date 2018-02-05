# app/helpers/lens_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Methods supporting lens-specific display.
#
module LensHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # default_lens_controller
  # Must be overridden for non-lens controllers like BookmarksController.
  # NOTE: Just a trial...
  #
  # @param [Object] _scope Unused # TODO: ?
  #
  # @return [Blacklight::Controller, nil]
  #
  def default_lens_controller(_scope = nil)
    result = self
    result = result.controller if result.respond_to?(:controller)
    if result.respond_to?(:default_catalog_controller)
      result.default_catalog_controller
    elsif result.class.respond_to?(:default_catalog_controller) # NOTE: 0% coverage for this case
      result.class.default_catalog_controller
    elsif result.is_a?(Blacklight::Catalog) # NOTE: 0% coverage for this case
      result
    end
  end

  # The current lens or the lens indicated by *obj* if it is given.
  #
  # The method will return *nil* only when *obj* does not map to a valid lens.
  #
  # @param [Object, nil] obj
  #
  # @raise [RuntimeError]             If the default lens is missing.
  #
  # @return [Blacklight::Lens]
  #
  def lens_for(obj = nil)
    fallback = current_lens_key
    obj ||= fallback
    lens = Blacklight::Lens[obj]
    unless lens # NOTE: 0% coverage for this case
      unless Blacklight::Lens.empty?
        logger.error("Blacklight::Lens#table has no entry for #{obj}")
      end
      obj = Blacklight::Lens.key_for(obj)
      "config/#{obj}".camelize.constantize.new
      lens = Blacklight::Lens[obj]
    end
    unless lens # NOTE: 0% coverage for this case
      obj = fallback
      logger.error("Blacklight::Lens fallback to #{obj}")
      lens = Blacklight::Lens[obj]
    end
    lens || raise("Blacklight::Lens#table has no entry for #{obj}")
  end

  # The current lens.
  #
  # If no lens can be determined for the current context, the result will be
  # Blacklight::Lens#default_lens.
  #
  # @return [Blacklight::Lens]
  #
  def current_lens
    lens_for(nil)
  end

  # The default lens.
  #
  # Returns *nil* if there is no default lens controller identifiable in the
  # current context.
  #
  # @return [Blacklight::Lens, nil]
  #
  # NOTE: 0% coverage for this method
  #
  def default_lens
    current_lens if default_lens_controller
  end

  # lens_key_for
  #
  # If no lens can be determined for the current context, the result will be
  # Blacklight::Lens#default_key.
  #
  # @param [Object, nil] obj
  #
  # @return [Symbol]
  #
  def lens_key_for(obj = nil)
    Blacklight::Lens.key_for(obj)
  end

  # current_lens_key
  #
  # @return [Symbol]
  #
  def current_lens_key
    default_lens_controller&.lens_key || default_lens_key
  end

  # default_lens_key
  #
  # @return [Symbol]
  #
  def default_lens_key
    Blacklight::Lens.default_key
  end

  # blacklight_config
  #
  # @param [Object, nil] obj
  #
  # @return [Blacklight::Configuration]
  #
  def blacklight_config_for(obj = nil)
    lens_for(obj).blacklight_config
  end

  # current_blacklight_config
  #
  # @return [Blacklight::Configuration]
  #
  def current_blacklight_config
    blacklight_config_for(nil)
  end

  # default_blacklight_config
  #
  # @return [Blacklight::Configuration]
  #
  # NOTE: 0% coverage for this method
  #
  def default_blacklight_config
    blacklight_config_for(default_lens_key)
  end

  # blacklight_config
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Blacklight::Configuration]
  #
  def blacklight_config(lens = nil)
    blacklight_config_for(lens)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The list of view subdirectories.
  #
  # @return [Array<String, nil>]
  #
  def view_subdirs
    [default_lens_controller&.controller_name, nil, default_lens_key.to_s].uniq
  end

  # render_template
  #
  # @param [String]    partial        Base partial name.
  # @param [Hash, nil] locals
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def render_template(partial, locals = nil) # TODO: this can probably be eliminated now...
    locals ||= {}
    render(partial, locals)
  end

end

__loading_end(__FILE__)
