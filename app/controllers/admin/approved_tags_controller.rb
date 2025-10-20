class Admin::ApprovedTagsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_approved_tag, only: [:show, :edit, :update, :destroy, :toggle_active, :toggle_featured]
  
  def index
    @approved_tags = ApprovedTag.includes(:tags).order(:name)
    
    # Filter by category if specified
    if params[:category].present? && ApprovedTag::CATEGORIES.key?(params[:category])
      @approved_tags = @approved_tags.by_category(params[:category])
    end
    
    # Filter by status
    case params[:status]
    when 'active'
      @approved_tags = @approved_tags.active
    when 'inactive'
      @approved_tags = @approved_tags.inactive
    when 'featured'
      @approved_tags = @approved_tags.featured
    end
    
    @approved_tags = @approved_tags.page(params[:page]).per(50)
  end

  def show
    @related_tags = Tag.where(name: @approved_tag.name)
    @usage_count = @related_tags.joins(:posts).count
  end

  def new
    @approved_tag = ApprovedTag.new
  end

  def create
    @approved_tag = ApprovedTag.new(approved_tag_params)
    
    if @approved_tag.save
      redirect_to admin_approved_tag_path(@approved_tag), notice: 'Approved tag was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @approved_tag.update(approved_tag_params)
      redirect_to admin_approved_tag_path(@approved_tag), notice: 'Approved tag was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @approved_tag.destroy!
    redirect_to admin_approved_tags_path, notice: 'Approved tag was successfully deleted.'
  end
  
  def toggle_active
    @approved_tag.toggle_active!
    redirect_back(fallback_location: admin_approved_tags_path, 
                  notice: "Tag #{@approved_tag.is_active? ? 'activated' : 'deactivated'} successfully.")
  end
  
  def toggle_featured
    @approved_tag.toggle_featured!
    redirect_back(fallback_location: admin_approved_tags_path, 
                  notice: "Tag #{@approved_tag.is_featured? ? 'featured' : 'unfeatured'} successfully.")
  end
  
  private
  
  def set_approved_tag
    @approved_tag = ApprovedTag.find(params[:id])
  end
  
  def approved_tag_params
    params.require(:approved_tag).permit(:name, :category, :description, :is_active, :is_featured)
  end
  
  def ensure_admin!
    redirect_to root_path, alert: 'Access denied.' unless current_user&.admin?
  end
end
