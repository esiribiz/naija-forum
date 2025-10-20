// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"

// Import all controllers explicitly
import AlertsController from "controllers/alerts"
import CharacterCountController from "controllers/character_count_controller"
import CollapsibleRepliesController from "controllers/collapsible_replies_controller"
import CommentsController from "controllers/comments_controller"
import FlashController from "controllers/flash_controller"
import NavbarController from "controllers/navbar_controller"
import NotificationBadgeController from "controllers/notification_badge_controller"
import NotificationsController from "controllers/notifications_controller"
import ProfileDashboardController from "controllers/profile_dashboard_controller"
import ReplyController from "controllers/reply_controller"
import ResetFormController from "controllers/reset_form_controller"
import TagsController from "controllers/tags_controller"

// Register all controllers
application.register("alerts", AlertsController)
application.register("character-count", CharacterCountController)
application.register("collapsible-replies", CollapsibleRepliesController)
application.register("comments", CommentsController)
application.register("flash", FlashController)
application.register("navbar", NavbarController)
application.register("notification-badge", NotificationBadgeController)
application.register("notifications", NotificationsController)
application.register("profile-dashboard", ProfileDashboardController)
application.register("reply", ReplyController)
application.register("reset-form", ResetFormController)
application.register("tags", TagsController)
