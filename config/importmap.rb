# Pin npm packages by running ./bin/importmap

pin "application"
pin "admin_notifications"
pin "admin"
pin "admin_sidebar"
pin "admin_dashboard"
pin "post_view_toggle"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin_all_from "app/javascript/controllers", under: "controllers"
