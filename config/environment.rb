# Load the Rails application.
require File.expand_path('../application', __FILE__)

gmail_username = ENV['GMAIL_USERNAME']
gmail_password = ENV['GMAIL_PASSWORD']

ActionMailer::Base.smtp_settings = {
    :enable_starttls_auto => true,
    :address        => 'smtp.gmail.com',
    :port           => 587,
    :domain         => 'gmail.com',
    :authentication => :plain,
    :user_name      => gmail_username,
    :password       => gmail_password
  }

# Initialize the Rails application.
Portal::Application.initialize!


