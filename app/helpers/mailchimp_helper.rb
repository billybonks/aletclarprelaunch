require 'gibbon'

module MailchimpHelper
  def self.add_to_list(user)
    Gibbon::Request.lists(ENV['LIST_ID']).members.create(body: {email_address: user.email, status: "pending", merge_fields: {FNAME: "First Name", LNAME: "Last Name"}})
  end
end
