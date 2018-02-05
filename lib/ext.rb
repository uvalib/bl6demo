# lib/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# This file is loaded from config/initializers/_extensions.rb.

# =============================================================================
# Constants
# =============================================================================

# Control tracking of file load order.
#
# During normal operation this should be set to *false*.
#
TRACE_LOADING =
  #true                               # Un-comment to turn on...
  false                               # ... otherwise this setting is used.

# Control tracking of invocation of Concern "included" blocks.
#
# During normal operation this should be set to *false*.
#
TRACE_CONCERNS =
  true                               # Un-comment to turn on...
  #false                               # ... otherwise this setting is used.

# Control tracking of Rails notifications.
#
# During normal operation this should be set to *false*.
#
TRACE_NOTIFICATIONS =
  #true                               # Un-comment to turn on...
  false                               # ... otherwise this setting is used.

# This constant is defined to mark sections of code that are present only to
# give context information to RubyMine -- for example, "include" statements
# which allow RubyMine to indicate which methods are overrides.
#
# (This constant is required to be a non-false value.)
#
ONLY_FOR_DOCUMENTATION = true

# =============================================================================
# Debugging - file load/require
# =============================================================================

if TRACE_LOADING

  # Indentation for #__loading_level.
  # ()This file's invocation will increment the value to zero.)
  @load_level = -1

  # Loading level and indentation.
  #
  # @param [Integer, nil] level       Default: `@load_level`.
  #
  # @return [String]
  #
  def __loading_level(level = @load_level)
    result = +''
    result << ' ' if level < 10
    result << level.to_s
    result << (' ' * ((2 * level) + 1))
  end

  # Display console output to indicate that a file is being loaded.
  #
  # @param [String] file              Actual parameter should be __FILE__.
  #
  # @return [void]
  #
  # == Usage Notes
  # Place as the first non-comment line of a Ruby source file.
  #
  def __loading(file)
    $stderr.puts("====== #{__loading_level}#{file}")
  end

  # Display console output to indicate that a file is being loaded.
  #
  # @param [String] file              Actual parameter should be __FILE__.
  #
  # @return [void]
  #
  # == Usage Notes
  # Place as the first non-comment line of a Ruby source file.
  #
  def __loading_begin(file)
    @load_level += 1
    $stderr.puts("====-> #{__loading_level}#{file}")
  end

  # Display console output to indicate the end of a file that is being loaded.
  #
  # @param [String] file              Actual parameter should be __FILE__.
  #
  # @return [void]
  #
  # == Usage Notes
  # Place as the last non-comment line of a Ruby source file.
  #
  def __loading_end(file)
    $stderr.puts("<-==== #{__loading_level}#{file}")
    @load_level -= 1
  end

else

  def __loading(*)
  end
  def __loading_begin(*)
  end
  def __loading_end(*)
  end

end

# =============================================================================
# Debugging - Concerns
# =============================================================================

if TRACE_CONCERNS

  # Indicate invocation of a Concern's "included" block.
  #
  # @param [Module] base
  # @param [String] concern
  #
  # @return [void]
  #
  def __included(base, concern)
    $stderr.puts "... including #{concern} in #{base}"
  end

else

  def __included(*)
  end

end

# =============================================================================
# Debugging - Rails notifications
# =============================================================================

if TRACE_NOTIFICATIONS

  # Notification specifications can be a single String, Regexp, or Array of
  # either.
  #
  # @example /.*/
  #   All notifications.
  #
  # @example /^cache_.*/
  #   Only caching notifications.
  #
  # @example [/\.action_dispatch/, /^.*process.*\.action_controller$/]
  #   Notifications related to route processing.
  #
  # @example Others
  #
  # 'load_config_initializer.railties'
  #
  # 'request.action_dispatch'
  #
  # '!connection.active_record'
  # 'sql.active_record'
  # 'instantiation.active_record'
  #
  # 'start_processing.action_controller'
  # 'process_action.action_controller'
  # 'redirect_to.action_controller'
  # 'halted_callback.action_controller'
  #
  # '!compile_template.action_view'
  # '!render_template.action_view'
  # 'render_template.action_view'
  # 'render_partial.action_view'
  #
  # 'cache_read.active_support'
  # 'cache_write.active_support'
  #
  # @see http://guides.rubyonrails.org/active_support_instrumentation.html
  #
  NOTIFICATIONS = /.*/

  # Limit each notification display to this number of characters.
  MAX_NOTIFICATION_SIZE = 1024

  # Table for mapping notifier instance identifiers down to simple numbers.
  @notifiers = {}

  ActiveSupport::Notifications.subscribe(*NOTIFICATIONS) do |*args|
    evt = ActiveSupport::Notifications::Event.new(*args)
    tid = @notifiers[evt.transaction_id] ||= @notifiers.size + 1
    args.shift(4)
    $stderr.puts(
      ("@@@ NOTIFIER [#{tid}] %-35s (%.2f ms) " % [evt.name, evt.duration]) <<
      args.map { |arg| arg.inspect.truncate(MAX_NOTIFICATION_SIZE) }.join(', ')
    )
  end

end

# =============================================================================
# Overrides
# =============================================================================

public

# This method can be used as a simple mechanism to override member(s) of a
# class or module by supplying new methods or redefinitions of existing methods
# within a block that is prepended as an anonymous module.
#
# @param [Class] mod                  The class or module to override
#
# @yield
#
# @return [void]
#
# == Usage Notes
# Within the block given, define new methods that *mod* will respond to and/or
# redefine existing methods.  Within redefined methods, "super" refers to the
# original method.
#
def override(mod, &block)
  unless block
    message = "Override of #{mod} failed - no definition block supplied"
    if Rails.env.production?
      Rails.logger.error(message)
    else
      raise message
    end
  end
  mod.send(:prepend, Module.new(&block))
end

# =============================================================================
# Require all modules from the "lib/ext" directory
# =============================================================================

__loading_begin(__FILE__)

_LIB_EXT_LOADS ||=
  begin
    dir = File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb'))
    Dir["#{dir}/*.rb"].each { |path| require(path) }
    Dir["#{dir}/*/ext.rb"].each { |path| require(path) }
  end

# =============================================================================
# Virgo deployments
# =============================================================================

module Virgo

  # We use Rails environments prefixed with "search_" to specify behaviors and
  # setting for the deployed application versus the behaviors and settings of
  # the usual "production", "development", and "test" environments, which are
  # implicitly reserved for non-deployed settings like desktop development.
  #
  # Unfortunately, this scheme could be problematic with any part of the Rails
  # toolchain that is sensitive to Rails environment since "search_production"
  # will not be treated the same as "production" for purposes of optimization,
  # etc.
  #
  # As a transition, these methods are defined to be used in place of tests for
  # `Rails.env` so that both the deployment setting and execution environment
  # can be specified by one term.
  #
  # Ultimately this should be replaced with a different way of handling
  # "config/environments" so that it contains only "production.rb",
  # "development.rb" and "test.rb" with internal adjustments for any cases
  # where values for the deployed setting is different than for the desktop
  # setting.
  #
  class << self

    # Indicates that this Virgo instance is being run in a deployed setting,
    # regardless of the execution environment.
    #
    def deployed?
      Rails.env.to_s.start_with?('search_') # TODO: criterion should change
    end

    # Indicates that this Virgo instance is the deployed production
    # application.  (Currently equivalent to `Rails.env.search_production?`.)
    #
    def deployed_production?
      deployed? && production?
    end

    # Indicates that this Virgo instance is the deployed development
    # application.  (Currently equivalent to `Rails.env.search_development?`.)
    #
    def deployed_development?
      deployed? && development?
    end

    # Indicates that this Virgo instance is for automated testing in the
    # deployed setting.  (Currently  equivalent to`Rails.env.search_test?`.)
    #
    def deployed_test?
      deployed? && test?
    end

    # Indicates that this Virgo instance is being run on the desktop (or other
    # non-deployed setting), regardless of the execution environment.
    #
    def desktop?
      !deployed?
    end

    # Indicates that this Virgo instance is running in a non-deployed setting
    # in the "production" Rails environment.
    #
    def desktop_production?
      desktop? && production?
    end

    # Indicates that this Virgo instance is running in a non-deployed setting
    # in the "development" Rails environment.
    #
    def desktop_development?
      desktop? && development?
    end

    # Indicates that this Virgo instance is running in a non-deployed setting
    # in the "test" Rails environment.
    #
    def desktop_test?
      desktop? && test?
    end

    # Indicates whether this Virgo instance should exhibit behaviors of a
    # "production" system.
    #
    def production?
      deployment?(%w(production prod))
    end

    # Indicates whether this Virgo instance should exhibit behaviors of a
    # "development" system.
    #
    def development?
      deployment?(%w(development dev))
    end

    # Indicates whether this Virgo instance should exhibit behaviors of a
    # "test" system.
    #
    def test?
      deployment?('test')
    end

    # Indicates whether this Virgo instance has any of the given name suffixes.
    #
    # @param [Array<String>, String] suffix
    #
    def deployment?(*suffix)
      env = Rails.env.to_s
      suffix.flatten.any? { |s| env.end_with?(s) }
    end

  end

end

__loading_end(__FILE__)
