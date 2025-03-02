// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import CommentsController from "./comments_controller"

// Register CommentsController manually
application.register("comments", CommentsController)

eagerLoadControllersFrom("controllers", application)
