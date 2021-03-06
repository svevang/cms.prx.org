# encoding: utf-8

class Api::Auth::AccountsController < Api::AccountsController
  include ApiAuthenticated

  api_versions :v1

  represent_with Api::Auth::AccountRepresenter

  private

  def resources
    self.resources = decorate_query(resources_base)
  end

  def resources_base
    authorization.token_auth_accounts
  end
end
