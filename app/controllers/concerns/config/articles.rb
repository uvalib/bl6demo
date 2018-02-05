# app/controllers/concerns/config/articles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_base'
require_relative '_eds'

module Config

  ARTICLES_CONFIG ||= Config::Eds.instance

  # Config::Articles
  #
  class Articles

    include Config::Base

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a self instance.
    #
    # @param [Blacklight::Configuration, nil] config
    #
    # @see Config::Eds#instance
    #
    def initialize(config = nil)
      config ||= ARTICLES_CONFIG
      super(:articles, config)
    end

  end

end

__loading_end(__FILE__)
