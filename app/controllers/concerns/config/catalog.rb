# app/controllers/concerns/config/catalog.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_base'
require_relative '_solr'

module Config

  CATALOG_CONFIG ||= Config::Solr.instance

  # Config::Catalog
  #
  class Catalog

    include Config::Base

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a self instance.
    #
    # If config/blacklight.yml indicates that the Solr server path includes
    # "lib.virginia.edu" then the real configuration will be used.  Otherwise,
    # the "fake" (local Solr) configuration will be used.
    #
    # @param [Blacklight::Configuration, nil] config
    #
    # @see Config::Solr#instance
    # @see Config::SolrFake#instance
    #
    def initialize(config = nil)
      config ||=
        if Blacklight.connection_config[:url].include?('lib.virginia.edu')
          CATALOG_CONFIG
        else
          require_relative('_solr_fake')
          SolrFake.instance
        end
      super(:catalog, config)
    end

  end

end

__loading_end(__FILE__)
