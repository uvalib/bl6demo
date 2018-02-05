# app/controllers/concerns/config/_constants.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Config

  module Constants

    HTML_NEW_LINE = '<br/>'.html_safe

    # Options for displaying separator between metadata items with multiple
    # values.
    HTML_LINES = %i(
      words_connector
      two_words_connector
      last_word_connector
    ).map { |k| [k, HTML_NEW_LINE] }.to_h.deep_freeze

  end

end

__loading_end(__FILE__)
