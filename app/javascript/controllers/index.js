// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"

// Import all controllers manually
import AlertsController from "./alerts"
import CommentsController from "./comments_controller"
import FlashController from "./flash_controller"
import NavbarController from "./navbar_controller"
import NotificationsController from "./notifications_controller"
import ProfileDashboardController from "./profile_dashboard_controller"

// Register all controllers
application.register("alerts", AlertsController)
application.register("comments", CommentsController)
application.register("flash", FlashController)
application.register("navbar", NavbarController)
application.register("notifications", NotificationsController)
application.register("profile-dashboard", ProfileDashboardController)
