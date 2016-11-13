class UsersController < ApplicationController
  before_filter :user_exists, only: :create
  before_filter :skip_first_page, only: :new
  before_filter :handle_ip, only: :create

  def new
    @bodyId = 'home'
    @is_mobile = mobile_device?

    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    ref_code = cookies[:h_ref]
    email = params[:user][:email]
    @user = User.new(email: email.downcase)
    @user.referrer = User.find_by_referral_code(ref_code) if ref_code
    if @user.save
      cookies[:h_email] = { value: @user.email }
      redirect_to '/refer-a-friend'
    else
      logger.info("Error saving user with email, #{email}")
      redirect_to root_path, alert: 'Something went wrong!'
    end
  end

  def refer
    @bodyId = 'refer'
    @is_mobile = mobile_device?

    @user = User.find_by_email(cookies[:h_email].downcase)

    respond_to do |format|
      if @user.nil?
        format.html { redirect_to root_path, alert: 'Something went wrong!' }
      else
        format.html # refer.html.erb
      end
    end
  end

  def policy
  end

  def redirect
    redirect_to root_path, status: 404
  end

  def verified_referrals
    csv_string = CSV.generate do |csv|
      csv << ['email', 'verified', 'referrals','verified_referrals', 'created_at', 'updated_at']
      User.all.each do |user|
        csv << [user.email, user.verified, user.referrals.count, user.verified_referrals.count,  user.created_at, user.updated_at ]
      end
    end
    puts csv_string
    render :csv  => csv_string
  end

  private

  def user_exists
    email = params[:user][:email].downcase
    if User.where(email: email).count == 1
      cookies[:h_email] = { value: email }
      return redirect_to '/refer-a-friend'
    end
  end

  def skip_first_page
    return if Rails.application.config.ended

    email = cookies[:h_email]
    if email && User.find_by_email(email.downcase)
      redirect_to '/refer-a-friend'
    else
      cookies.delete :h_email
    end
  end

  def handle_ip
    # Prevent someone from gaming the site by referring themselves.
    # Presumably, users are doing this from the same device so block
    # their ip after their ip appears three times in the database.

    address = request.env['HTTP_X_FORWARDED_FOR']
    return if address.nil?

    current_ip = IpAddress.find_by_address(address)
    if current_ip.nil?
      current_ip = IpAddress.create(address: address, count: 1)
    elsif current_ip.count > 2
      logger.info('IP address has already appeared three times in our records.
                 Redirecting user back to landing page.')
      return redirect_to root_path
    else
      current_ip.count += 1
      current_ip.save
    end
  end
end
