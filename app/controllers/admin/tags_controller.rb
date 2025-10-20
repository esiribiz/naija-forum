class Admin::TagsController < Admin::BaseController
  before_action :set_tag, only: [:show, :edit, :update, :destroy]
  before_action :ensure_can_manage_tags, only: [:new, :create, :destroy]

  def index
    @tags = Tag.includes(:posts)
               .order(:name)
               .page(params[:page])
               .per(25)

    if params[:search].present?
      @tags = @tags.where("name ILIKE ?", "%#{params[:search]}%")
    end

    @stats = {
      total: Tag.count,
      with_posts: Tag.joins(:posts).distinct.count,
      unused: Tag.left_joins(:posts).where(posts: { id: nil }).count
    }
  end

  def show
    @posts = @tag.posts.includes(:user, :category, :comments).order(created_at: :desc).limit(10)
  end

  def new
    @tag = Tag.new
  end

  def create
    @tag = Tag.new(tag_params)

    if @tag.save
      redirect_to admin_tags_path, notice: "Tag created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @tag.update(tag_params)
      redirect_to admin_tags_path, notice: "Tag updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @tag.posts.exists?
      redirect_to admin_tags_path, alert: "Cannot delete tag with posts."
    else
      @tag.destroy
      redirect_to admin_tags_path, notice: "Tag deleted successfully."
    end
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def ensure_can_manage_tags
    unless current_user&.admin?
      redirect_to admin_tags_path, alert: "Only administrators can create or delete tags. Moderators can edit existing tags."
    end
  end

  def tag_params
    params.require(:tag).permit(:name, :description)
  end
end
