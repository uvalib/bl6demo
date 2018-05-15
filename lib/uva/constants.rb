# lib/uva/constants.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'uva'

module UVA

  # Various useful constants.
  #
  module Constants

    # String to cause text to continue on the next line within an HTML element.
    HTML_NEW_LINE = '<br/>'.html_safe.freeze

  end

end

__loading_end(__FILE__)
