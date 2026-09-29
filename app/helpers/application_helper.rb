module ApplicationHelper
  def clerk_display_name
    user = clerk&.user
    return unless user

    [ user.first_name, user.last_name ].compact_blank.join(" ").presence ||
      user.username.presence ||
      clerk_primary_email(user)
  end

  def clerk_js_src
    host = clerk_frontend_api_host
    return if host.blank?

    "https://#{host}/npm/@clerk/clerk-js@5/dist/clerk.browser.js"
  end

  private

  def clerk_primary_email(user)
    emails = Array(user.email_addresses)
    primary = emails.find { |email| email.id == user.primary_email_address_id }
    (primary || emails.first)&.email_address
  end

  # Clerk publishable keys encode the Frontend API host as base64 after the environment prefix.
  def clerk_frontend_api_host
    encoded = ENV["CLERK_PUBLISHABLE_KEY"].to_s.split("_", 3).last
    return if encoded.blank?

    Base64.decode64(encoded).delete_suffix("$").presence
  end
end
