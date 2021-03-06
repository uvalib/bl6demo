# lib/_trace.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Loader debugging.

# =============================================================================
# Debugging - environment variables
# =============================================================================

public

# Access environment variable and return the expected type.
#
# @param [String]       var       Name of environment variable.
# @param [Object, nil]  default   Default value if `ENV[*var*]` is not present.
#                                 or if it's value is blank. (This is not
#                                 interpreted so it should be a value of the
#                                 appropriate type.)
#
# @return [Boolean]               For boolean-like strings.
# @return [Regexp]                For Regexp-like strings.
# @return [String]                For everything else except:
# @return [Object]                Non-string environment variable value.
# @return [nil]                   If missing and *default* is *nil*.
#
def env(var, default = nil)
  case (value = ENV[var].presence)
    when nil                       then default
    when 'true', 'True', 'TRUE'    then true
    when 'false', 'False', 'FALSE' then false
    when %r{^/(.*)/(i?)$}          then Regexp.new($1, $2.presence)
    when /^%r(.)(.*)\1(i?)$/       then Regexp.new($2, $3.presence)
    else                                value
  end
end

# =============================================================================
# Constants
# =============================================================================

public

# Control tracking of file load order.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
TRACE_LOADING = env('TRACE_LOADING', false)

# Control tracking of invocation of Concern "included" blocks.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
TRACE_CONCERNS = env('TRACE_CONCERNS', false)

# Control tracking of Rails notifications.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# Notification subscriptions are controlled by ENV['TRACE_NOTIFICATIONS']:
# * If *false* then none (the default behavior).
# * If *true*  then all.
# * If the value can be interpreted as a regular expression then.
#
# If ENV['TRACE_NOTIFICATIONS'] is set to *true* then all notifications
#
TRACE_NOTIFICATIONS = env('TRACE_NOTIFICATIONS', false)

# =============================================================================
# Debugging - file load/require
# =============================================================================

if TRACE_LOADING

  $stderr.puts("TRACE_LOADING = #{TRACE_LOADING.inspect}")

  # Indentation for #__loading_level.
  # (This file's invocation will increment the value to zero.)
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

  $stderr.puts("TRACE_CONCERNS = #{TRACE_CONCERNS.inspect}")

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
  NOTIFICATIONS =
    case TRACE_NOTIFICATIONS
      when String then Regexp.new(TRACE_NOTIFICATIONS)
      when Regexp then TRACE_NOTIFICATIONS
      else             /.*/
    end

  $stderr.puts("TRACE_NOTIFICATIONS = #{NOTIFICATIONS.inspect}")

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
