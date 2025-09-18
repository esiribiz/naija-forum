class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: [:show, :edit, :update, :destroy]
  
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
      redirect_to admin_categories_path, notice: 'Category created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @category.update(category_params)
      redirect_to admin_categories_path, notice: 'Category updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @category.posts.exists?
      redirect_to admin_categories_path, alert: 'Cannot delete category with posts.'
    else
      @category.destroy
      redirect_to admin_categories_path, notice: 'Category deleted successfully.'
    end
  end
  
  private
  
  def set_category
    @category = Category.find(params[:id])
  end
  
  def category_params
    params.require(:category).permit(:name, :description, :color)
  end
end