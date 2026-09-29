module ApplicationHelper
  def clerk_js_src
    host = clerk_frontend_api_host
    return if host.blank?

    "https://#{host}/npm/@clerk/clerk-js@5/dist/clerk.browser.js"
  end

  private

  # Clerk publishable keys encode the Frontend API host as base64 after the environment prefix.
  def clerk_frontend_api_host
    encoded = ENV["CLERK_PUBLISHABLE_KEY"].to_s.split("_", 3).last
    return if encoded.blank?

    Base64.decode64(encoded).delete_suffix("$").presence
  end
end
