class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_admin, :toggle_suspend, :promote_to_moderator, :demote_user, :ban, :unban]
  before_action :ensure_can_manage_user_roles, only: [:edit, :update, :destroy, :toggle_admin, :promote_to_moderator, :demote_user, :ban, :unban]
  before_action :ensure_can_create_users, only: [:new, :create]

  def index
    @users = User.includes(:posts, :comments)

    # Apply role filter
    @users = @users.where(role: params[:role]) if params[:role].present?

    # Apply search filter
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where("username ILIKE ? OR email ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?",
                           search_term, search_term, search_term, search_term)
    end

    # Apply activity filter
    case params[:activity]
    when "online"
      @users = @users.online
    when "recent"
      @users = @users.recently_active
    when "inactive"
      @users = @users.inactive
    when "never"
      @users = @users.never_logged_in
    end

    # Apply joined period filter
    case params[:joined]
    when "today"
      @users = @users.joined_today
    when "week"
      @users = @users.joined_this_week
    when "month"
      @users = @users.joined_this_month
    when "3months"
      @users = @users.joined_last_3_months
    when "year"
      @users = @users.joined_this_year
    end

    # Apply minimum posts filter
    if params[:min_posts].present? && params[:min_posts].to_i > 0
      @users = @users.left_joins(:posts).group("users.id").having("COUNT(posts.id) >= ?", params[:min_posts].to_i)
    end

    # Apply minimum comments filter
    if params[:min_comments].present? && params[:min_comments].to_i > 0
      @users = @users.left_joins(:comments).group("users.id").having("COUNT(comments.id) >= ?", params[:min_comments].to_i)
    end

    # Handle export before pagination
    if params[:format] == "csv"
      return export_users_csv
    end

    # Apply sorting
    case params[:sort]
    when "oldest"
      @users = @users.order(created_at: :asc)
    when "most_active"
      @users = @users.most_active
    when "most_posts"
      @users = @users.by_posts_count
    when "most_comments"
      @users = @users.by_comments_count
    when "alpha_asc"
      @users = @users.order(:username)
    when "alpha_desc"
      @users = @users.order(username: :desc)
    else # 'newest' or default
      @users = @users.order(created_at: :desc)
    end

    # Store filtered users for stats (before pagination)
    @filtered_users_count = @users.count

    # Apply pagination
    per_page = params[:per_page].present? ? params[:per_page].to_i : 25
    per_page = [per_page, 100].min # Max 100 per page
    @users = @users.page(params[:page]).per(per_page) if @users.respond_to?(:page)

    # Stats for the dashboard
    @total_users = User.count
    @admin_users = User.where(role: "admin").count
    @users_today = User.joined_today.count
    @moderator_users = User.where(role: "moderator").count
    @new_users_this_week = User.joined_this_week.count
    @online_users = User.online.count
    @recent_users = User.recently_active.count
    @inactive_users = User.inactive.count
    @never_logged_in_users = User.never_logged_in.count
  end

  def export
    # Export users as CSV
    redirect_to admin_users_path(format: "csv", **request.query_parameters.except("action", "controller", "format"))
  end

  def show
    # Admin access is already validated by Admin::BaseController
    @user_posts = @user.posts.includes(:category).order(created_at: :desc).limit(10)
    @user_comments = @user.comments.includes(:post).order(created_at: :desc).limit(10)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    # If password not provided, generate a secure one
    if @user.password.blank?
      generated_password = SecureRandom.hex(8)
      @user.password = generated_password
      @user.password_confirmation = generated_password
    end

    # Auto-confirm admin-created users if email_confirmed field exists
    @user.email_confirmed = true if @user.respond_to?(:email_confirmed=)

    if @user.save
      # Log the user creation
      Rails.logger.info "Admin #{current_user.username} created user #{@user.username} with role #{@user.role}"

      # Send welcome email if mailer exists
      begin
        if defined?(UserMailer) && UserMailer.respond_to?(:account_created)
          UserMailer.account_created(@user, @user.password, current_user).deliver_now
        end
      rescue => e
        Rails.logger.warn "Failed to send welcome email to #{@user.email}: #{e.message}"
      end

      # Create notification for the new user if Notification model exists
      begin
        if defined?(Notification)
          Notification.create!(
            user: @user,
            actor: current_user,
            action: "account_created",
            message: "Your account has been created by administrator #{current_user.display_name}"
          )
        end
      rescue => e
        Rails.logger.warn "Failed to create notification for new user: #{e.message}"
      end

      redirect_to admin_users_path, notice: "User #{@user.username} created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Admin access is already validated by Admin::BaseController
  end

  def update
    # Admin access is already validated by Admin::BaseController
    # Set the current admin user for the email notification
    Thread.current[:current_admin_user] = current_user

    if @user.update(user_params)
      redirect_to admin_users_path, notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Admin access is already validated by Admin::BaseController
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot delete yourself."
      return
    end

    username = @user.username
    email = @user.email
    posts_count = @user.posts.count
    comments_count = @user.comments.count

    begin
      # Log the deletion for audit purposes
      Rails.logger.warn "ADMIN USER DELETION: Admin #{current_user.username} (ID: #{current_user.id}) is deleting user #{username} (ID: #{@user.id}, Email: #{email}). Posts: #{posts_count}, Comments: #{comments_count}"

      # Perform the deletion (this will cascade delete associated records due to dependent: :destroy)
      @user.destroy!

      # Success message with details
      redirect_to admin_users_path,
                  notice: "User account deleted: #{username} (#{email}). Removed #{posts_count} posts and #{comments_count} comments."
    rescue => e
      # Log the error
      Rails.logger.error "Failed to delete user #{username} (ID: #{@user.id}): #{e.message}"

      # Redirect with error message
      redirect_to admin_users_path,
                  alert: "Failed to delete user #{username}: #{e.message}"
    end
  end

    # toggle_suspend
  def toggle_suspend
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot suspend yourself."
      return
    end

    @user.update!(suspended: !@user.suspended)
    action = @user.suspended? ? "suspended" : "unsuspended"
    redirect_to admin_user_path(@user), notice: "User has been #{action}."
  end


  def toggle_admin
    # Admin access is already validated by Admin::BaseController
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot change your own admin status."
      return
    end

    new_role = @user.admin? ? "user" : "admin"

    # Set the current admin user for the email notification
    Thread.current[:current_admin_user] = current_user

    @user.update!(role: new_role)

    action = @user.admin? ? "granted" : "removed"
    redirect_to admin_users_path, notice: "Admin privileges #{action} for #{@user.username}."
  end

  # Promote user to moderator
  def promote_to_moderator
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot change your own role."
      return
    end

    # Set the current admin user for the email notification
    Thread.current[:current_admin_user] = current_user

    @user.update!(role: "moderator")
    redirect_to admin_users_path, notice: "#{@user.username} has been promoted to moderator."
  end

  # Demote user (admin to user, moderator to user)
  def demote_user
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot change your own role."
      return
    end

    old_role = @user.role

    # Set the current admin user for the email notification
    Thread.current[:current_admin_user] = current_user

    @user.update!(role: "user")
    redirect_to admin_users_path, notice: "#{@user.username} has been demoted from #{old_role} to regular user."
  end

  # Ban/Unban user
  def ban
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot ban yourself."
      return
    end

    Rails.logger.info "ADMIN BAN: Admin #{current_user.username} (ID: #{current_user.id}) is banning user #{@user.username} (ID: #{@user.id})"

    @user.update!(suspended: true)
    Rails.logger.info "ADMIN BAN SUCCESS: User #{@user.username} (ID: #{@user.id}) suspended status is now: #{@user.suspended?}"

    redirect_to admin_users_path(page: params[:page], search: params[:search]), alert: "#{@user.username} has been banned."
  end

  def unban
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot unban yourself."
      return
    end

    Rails.logger.info "ADMIN UNBAN: Admin #{current_user.username} (ID: #{current_user.id}) is unbanning user #{@user.username} (ID: #{@user.id}). Current suspended status: #{@user.suspended?}"

    @user.update!(suspended: false)
    Rails.logger.info "ADMIN UNBAN SUCCESS: User #{@user.username} (ID: #{@user.id}) suspended status is now: #{@user.suspended?}"

    redirect_to admin_users_path(page: params[:page], search: params[:search]), notice: "#{@user.username} has been unbanned."
  end

  private

  def export_users_csv
    require "csv"

    # Get filtered users (without pagination)
    users = @users.includes(:posts, :comments)

    csv_data = CSV.generate(headers: true) do |csv|
      # CSV Headers
      csv << [
        "ID", "Username", "Email", "First Name", "Last Name", "Role",
        "Created At", "Last Sign In", "Posts Count", "Comments Count",
        "Status", "Suspended"
      ]

      # CSV Data
      users.find_each do |user|
        csv << [
          user.id,
          user.username,
          user.email,
          user.first_name,
          user.last_name,
          user.role.capitalize,
          user.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
          user.last_sign_in_at&.strftime("%Y-%m-%d %H:%M:%S"),
          user.posts.count,
          user.comments.count,
          user.activity_status,
          user.suspended? ? "Yes" : "No"
        ]
      end
    end

    # Send CSV file
    send_data csv_data,
              filename: "users_export_#{Date.current.strftime('%Y%m%d')}.csv",
              type: "text/csv",
              disposition: "attachment"
  end

  def set_user
    @user = User.find(params[:id])
  end

  def ensure_can_manage_user_roles
    unless current_user&.admin?
      redirect_to admin_users_path, alert: "Only administrators can manage user roles."
    end
  end

  def ensure_can_create_users
    unless current_user&.admin?
      redirect_to admin_users_path, alert: "Only administrators can create new users."
    end
  end

  def user_params
    # Base permitted parameters (everyone can edit these)
    base_params = [:username, :email, :first_name, :last_name, :bio]

    # For new user creation, allow password
    if action_name == "create"
      base_params += [:password, :password_confirmation]
    end

    # Only admins can modify roles and suspension status - SECURITY: Separate role and suspension permissions
    if current_user&.admin?
      # SECURITY FIX: Use explicit parameter lists instead of splat operator to prevent mass assignment
      admin_params = [:username, :email, :first_name, :last_name, :bio]
      admin_params += [:password, :password_confirmation] if action_name == "create"
      admin_params += [:role, :suspended]
      permitted_params = params.require(:user).permit(admin_params)
    else
      # Non-admins can only edit basic profile information
      permitted_params = params.require(:user).permit(base_params)

      # SECURITY: Log any attempts to modify privileged fields
      if params[:user][:role].present? || params[:user][:suspended].present?
        Rails.logger.warn "SECURITY: Non-admin user #{current_user&.id} attempted to change privileged user attributes (role/suspended)"
      end
    end

    # SECURITY: Additional validation for role changes
    if permitted_params[:role].present?
      unless User::VALID_ROLES.include?(permitted_params[:role])
        Rails.logger.error "SECURITY: Invalid role specified: #{permitted_params[:role]} by user #{current_user&.id}"
        raise ActionController::ParameterMissing.new("Invalid role specified")
      end

      # Prevent privilege escalation - only super admins can create other admins
      if permitted_params[:role] == "admin" && !current_user&.admin?
        Rails.logger.error "SECURITY: Non-admin user #{current_user&.id} attempted to create admin user"
        raise SecurityError, "Insufficient privileges to create admin users"
      end
    end

    # SECURITY: Validate suspension changes
    if permitted_params[:suspended].present? && !current_user&.admin?
      Rails.logger.error "SECURITY: Non-admin user #{current_user&.id} attempted to modify user suspension status"
      raise SecurityError, "Insufficient privileges to modify user suspension"
    end

    permitted_params
  end

end
