class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: [:show, :edit, :update, :destroy]
  before_action :ensure_can_manage_categories, only: [:new, :create, :destroy]

  def index
    @categories = Category.includes(:posts)
                         .order(:name)
                         .page(params[:page])
                         .per(25)

    if params[:search].present?
      @categories = @categories.where("name ILIKE ? OR description ILIKE ?",
                                     "%#{params[:search]}%", "%#{params[:search]}%")
    end

    @stats = {
      total: Category.count,
      with_posts: Category.joins(:posts).distinct.count,
      empty: Category.left_joins(:posts).where(posts: { id: nil }).count
    }
  end

  def show
    @posts = @category.posts.includes(:user, :comments).order(created_at: :desc).limit(10)
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to admin_categories_path, notice: "Category created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path, notice: "Category updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    posts_count = @category.posts.count

    if posts_count > 0 && params[:force] != "true"
      redirect_to admin_categories_path,
                  alert: "Cannot delete category with #{posts_count} posts. Use force delete if you want to remove it anyway."
    else
      # If force delete, we'll need to handle the posts (either reassign or delete)
      if params[:force] == "true" && posts_count > 0
        @category.posts.update_all(category_id: nil) # Unassign posts from category
      end

      @category.destroy
      redirect_to admin_categories_path, notice: "Category deleted successfully."
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def ensure_can_manage_categories
    unless current_user&.admin?
      redirect_to admin_categories_path, alert: "Only administrators can create or delete categories. Moderators can edit existing categories."
    end
  end

  def category_params
    params.require(:category).permit(:name, :description, :color, :image)
  end
end
