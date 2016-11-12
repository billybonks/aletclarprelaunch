class MailchimpController < ApplicationController

  def subscribed
    if params["type"] == "subscribe"
      user = User.where(email:params["data"]["email"]).first
      user.verified = true
      user.save
    end
    render :json => user
  end

end
