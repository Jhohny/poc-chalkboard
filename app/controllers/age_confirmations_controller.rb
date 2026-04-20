# frozen_string_literal: true

# Accepts a visitor's one-click "I'm 18+" self-confirmation.
class AgeConfirmationsController < ApplicationController
  def create
    confirm_age!
    redirect_to root_path
  end

  def destroy
    revoke_age_confirmation!
    redirect_to root_path
  end
end
