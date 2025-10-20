# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# Only enable CSP in production to avoid conflicts with development tools
unless Rails.env.development?
  Rails.application.configure do
    config.content_security_policy do |policy|
      policy.default_src :self
      policy.font_src    :self, :https, :data
      policy.img_src     :self, :https, :data, :blob
      policy.object_src  :none
      policy.script_src  :self
      policy.style_src   :self, :unsafe_inline
      policy.connect_src :self, :https, "ws:", "wss:"
      policy.frame_ancestors :none

      # Specify URI for violation reports
      # policy.report_uri "/csp-violation-report-endpoint"
    end

    # Generate session nonces for permitted importmap, inline scripts, and inline styles.
    config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
    config.content_security_policy_nonce_directives = %w(script-src style-src)
  end
end
