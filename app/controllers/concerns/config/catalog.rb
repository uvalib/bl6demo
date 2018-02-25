# app/controllers/concerns/config/catalog.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_base'
require_relative '_solr'

module Config

  CATALOG_CONFIG = Config::Solr.instance

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
    # @see Config::Solr#instance
    # @see Config::SolrFake#instance
    #
    def initialize
      if Blacklight.connection_config[:url].include?('lib.virginia.edu')
        super(CATALOG_CONFIG)
      else
        require_relative('_solr_fake')
        super(Config::SolrFake.instance)
      end
    end

  end

  # Assign class lens key.
  Catalog.key = CATALOG_CONFIG.lens_key

  # Sanity check.
  abort unless Blacklight::Lens::LENS_KEYS.include?(Catalog.key)

end

__loading_end(__FILE__)
