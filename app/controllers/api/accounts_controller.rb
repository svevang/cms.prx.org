# encoding: utf-8

class Api::AccountsController < Api::BaseController
  api_versions :v1

  represent_with Api::AccountRepresenter

  private

  def resources
    @resources ||= super.member
  end

  def resources_base
    user.try(:accounts) || Account
  end

  def user
    @user ||= User.find(params[:user_id]) if params[:user_id]
  end

  def scoped(relation)
    relation.active
  end

# TODO: refactor existing app to have membership record for user to be admin of individual account
# This would be the right thing to do if there was consistency in how accounts are associated to a user.
# Once that TODO above is done, this can be used instead of the `resources` method
  # filter_resources_by :user_id
end
