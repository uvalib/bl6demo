# app/controllers/account_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# User account controller.
#
# TODO: Need to determine how this plays with Devise
#
class AccountController < ApplicationController

  include LensConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /account/signed_out
  #
  def signed_out
  end

end

__loading_end(__FILE__)
