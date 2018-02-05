# app/controllers/concerns/mail_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# The "non-routable" methods from Blacklight::Catalog which are also needed by
# non-catalog controllers like BookmarksController.
#
module MailConcern

  extend ActiveSupport::Concern

  include Blacklight::Catalog unless ONLY_FOR_DOCUMENTATION

  # Code to be added to the controller class including this module.
  included do |base|
    __included(base, 'MailConcern')
    include RescueConcern
    include LensConcern
  end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides
  # ===========================================================================

  protected

=begin # NOTE: using base version
  # Email Action (this will render the appropriate view on GET requests and
  # process the form and send the email on POST requests)
  #
  # @param [Array<Blacklight::Document>] documents
  #
  # Compare with:
  # @see Blacklight::Catalog#email_action
  #
  def email_action(documents)
    details = params.slice(:to, :message)
    mail = RecordMailer.email_record(documents, details, url_options)
    mail.respond_to?(:deliver_now) ? mail.deliver_now : mail.deliver
  end
=end

  # SMS action (this will render the appropriate view on GET requests and
  # process the form and send the email on POST requests)
  #
  # @param [Array<Blacklight::Document>] documents
  #
  # Compare with:
  # @see Blacklight::Catalog#sms_action
  #
  def sms_action(documents)
    ph_number = params[:to].to_s.gsub(/[^\d]/, '')
    carrier   = params[:carrier]
    details   = { to: "#{ph_number}@#{carrier}" }
    mail = RecordMailer.sms_record(documents, details, url_options)
    mail.respond_to?(:deliver_now) ? mail.deliver_now : mail.deliver
  end

  # validate_sms_params
  #
  # @return [Boolean]
  #
  # This method overrides:
  # @see Blacklight::Catalog#validate_sms_params
  #
  def validate_sms_params
    error = []
    ph_number = params[:to]
    if ph_number.blank?
      error << I18n.t('blacklight.sms.errors.to.blank')
    elsif ph_number.gsub(/[^\d]/, '').length != 10 # NOTE: 0% coverage for this case
      error << I18n.t('blacklight.sms.errors.to.invalid', to: ph_number)
    end
    carrier = params[:carrier]
    if carrier.blank?
      error << I18n.t('blacklight.sms.errors.carrier.blank')
    elsif !sms_mappings.values.include?(carrier) # NOTE: 0% coverage for this case
      error << I18n.t('blacklight.sms.errors.carrier.invalid')
    end
    flash[:error] = error.join("<br/>\n".html_safe) if error.present?
    flash[:error].blank?
  end

=begin # NOTE: using base version
  # sms_mappings
  #
  # @return [Hash{String=>String}]
  #
  # @see Blacklight::Engine (lib/blacklight/engine.rb)
  #
  # Compare with:
  # @see Blacklight::Catalog#sms_mappings
  #
  def sms_mappings
    Blacklight::Engine.config.sms_mappings
  end
=end

  # validate_email_params
  #
  # @return [Boolean]
  #
  # This method overrides:
  # @see Blacklight::Catalog#validate_email_params
  #
  def validate_email_params
    error = []
    addr = params[:to]
    if addr.blank?
      error << I18n.t('blacklight.email.errors.to.blank')
    elsif !addr.match(Blacklight::Engine.config.email_regexp) # NOTE: 0% coverage for this case
      error << I18n.t('blacklight.email.errors.to.invalid', to: addr)
    end
    flash[:error] = error.join("<br/>\n".html_safe) if error.present?
    flash[:error].blank?
  end

end

__loading_end(__FILE__)
