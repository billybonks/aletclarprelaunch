require 'users_helper'
require 'mailchimp_helper'

class User < ActiveRecord::Base
  belongs_to :referrer, class_name: 'User', foreign_key: 'referrer_id'
  has_many :referrals, class_name: 'User', foreign_key: 'referrer_id'

  validates :email, presence: true, uniqueness: true, format: {
    with: /\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*/i,
    message: 'Invalid email format.'
  }
  validates :referral_code, uniqueness: true

  before_create :create_referral_code
  after_create :send_welcome_email

  REFERRAL_STEPS = [

    {
      'count' => 2,
      'html' => 'Sneak peek at the launch collection',
      'class' => 'two'
    },
    {
      'count' => 5,
      'html' => 'Exclusive Access: <br>Shop a day before everyone else',
      'class' => 'three'
    },
    {
      'count' => 15,
      'html' => 'S$20 shopping voucher',
      'class' => 'four'
    },
    {
      'count' => 30,
      'html' => 'Free Quintessential Top worth S$39',
      'class' => 'five'
    },
    {
      'count' => 60,
      'html' => 'Free local shipping for life',
      'class' => 'six'
    }

  ]

  def verified_referrals
    referrals.select{ |ref| ref.verified == true}
  end

  private

  def create_referral_code
    self.referral_code = UsersHelper.unused_referral_code
  end

  def send_welcome_email
    MailchimpHelper.add_to_list self
    #UserMailer.delay.signup_email(self)
  end
end
