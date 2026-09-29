module ClerkHelpers
  DEFAULT_USER_ID = "user_test_123"

  class << self
    attr_accessor :current, :signed_out
  end

  def self.reset!
    self.current = nil
    self.signed_out = nil
  end

  def self.sign_in_as(user_id)
    self.current = build(
      user_id: user_id,
      organization_id: nil,
      role: nil,
      permissions: [],
      authenticated: true
    )
  end

  def self.restore_signed_out!
    self.current = signed_out || build(authenticated: false)
  end

  def self.build(user_id: DEFAULT_USER_ID, organization_id: nil, role: nil, permissions: [], sign_in_url: nil, sign_up_url: nil, authenticated: false)
    Session.new(
      user_id: user_id,
      organization_id: organization_id,
      role: role,
      permissions: permissions,
      sign_in_url: sign_in_url,
      sign_up_url: sign_up_url,
      authenticated: authenticated
    )
  end

  def stub_clerk_auth(user_id: DEFAULT_USER_ID, organization_id: nil, role: nil, permissions: [])
    clerk = ClerkHelpers.build(
      user_id: user_id,
      organization_id: organization_id,
      role: role,
      permissions: permissions,
      authenticated: true
    )
    use_clerk(clerk)
    clerk
  end

  def stub_unauthenticated_clerk(sign_in_url: "https://example.test/sign-in", sign_up_url: "https://example.test/sign-up")
    clerk = ClerkHelpers.build(
      authenticated: false,
      sign_in_url: sign_in_url,
      sign_up_url: sign_up_url
    )
    ClerkHelpers.signed_out = clerk
    use_clerk(clerk)
    clerk
  end

  def click_sign_out
    page.execute_script(<<~JS)
      window.Clerk = {
        load() { return Promise.resolve() },
        signOut() { window.location.assign("/events?sign_out=1") }
      }
    JS
    click_button "Sign out"
  end

  class Session
    attr_reader :user_id, :session, :organization_id, :organization_role, :organization_permissions, :sign_in_url, :sign_up_url, :user

    def initialize(user_id:, organization_id:, role:, permissions:, sign_in_url:, sign_up_url:, authenticated:)
      @organization_id = organization_id
      @organization_role = role
      @organization_permissions = permissions
      @sign_in_url = sign_in_url
      @sign_up_url = sign_up_url
      @user_id = authenticated ? user_id : nil
      @session = authenticated ? {
        "sub" => user_id,
        "org_id" => organization_id,
        "org_role" => role,
        "org_permissions" => permissions
      } : nil
      @user = authenticated ? User.new : nil
    end

    def user?
      @user_id.present?
    end
  end

  User = Struct.new(:first_name, :last_name, :username, :email_addresses, :primary_email_address_id) do
    def initialize
      super("Test", "Voter", nil, [], nil)
    end
  end

  # Browser requests run on the server thread, so the stand-in is installed on
  # the controller and on the Rack env. Sign-in and sign-out links swap it.
  module Middleware
    def call(env)
      return super unless ClerkHelpers.current

      request = Rack::Request.new(env)

      if request.params["sign_out"].present?
        ClerkHelpers.restore_signed_out!
        return redirect_to_events
      end

      if (user_id = request.params["test_user"].presence)
        ClerkHelpers.sign_in_as(user_id)
        return redirect_to_events
      end

      env["clerk"] = ClerkHelpers.current
      @app.call(env)
    end

    private

    def redirect_to_events
      response = Rack::Response.new
      response.redirect("/events")
      response.finish
    end
  end

  private

  def use_clerk(clerk)
    ClerkHelpers.current = clerk
    unless Clerk::Rack::Middleware.ancestors.include?(Middleware)
      Clerk::Rack::Middleware.prepend(Middleware)
    end
    allow_any_instance_of(ApplicationController).to receive(:clerk) { ClerkHelpers.current }
  end
end

RSpec.configure do |config|
  config.include ClerkHelpers
  config.after { ClerkHelpers.reset! }
end
