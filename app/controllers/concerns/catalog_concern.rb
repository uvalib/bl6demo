# app/controllers/concerns/catalog_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'config/catalog'

# CatalogConcern
#
module CatalogConcern

  extend ActiveSupport::Concern

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'CatalogConcern')

    include SolrConcern
    include LensConcern

    if base == CatalogController
      self.blacklight_config = Config::Catalog.new.blacklight_config
    else
      copy_blacklight_config_from(CatalogController)
    end

  end

end

__loading_end(__FILE__)
