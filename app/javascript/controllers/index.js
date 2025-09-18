// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"

// Import all controllers explicitly
import AlertsController from "controllers/alerts"
import CommentsController from "controllers/comments_controller"
import FlashController from "controllers/flash_controller"
import NavbarController from "controllers/navbar_controller"
import NotificationsController from "controllers/notifications_controller"
import ProfileDashboardController from "controllers/profile_dashboard_controller"

// Register all controllers
application.register("alerts", AlertsController)
application.register("comments", CommentsController)
application.register("flash", FlashController)
application.register("navbar", NavbarController)
application.register("notifications", NotificationsController)
application.register("profile-dashboard", ProfileDashboardController)
