# lib/ext/object.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading(__FILE__)

require 'active_support/core_ext/object'

class Object

  # Recursive freezing support.
  #
  # @see Hash#deep_freeze
  #
  def deep_freeze
    freeze
  end

  # Recursive duplication support.
  #
  # @see Hash#rdup
  #
  def rdup
    duplicable? ? dup : self
  end

end
