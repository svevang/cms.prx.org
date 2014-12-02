class AccountPolicy < ApplicationPolicy
  attr_reader :user, :account

  def initialize(user, account)
    @user = user
    @account = account
  end

  def create?
    user.present?
  end

  def update?
    user && user.approved_accounts.include?(account)
  end

  def destroy?
    user && user.role_for(account) == 'admin'
  end
end