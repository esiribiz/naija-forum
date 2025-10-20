class TagsController < ApplicationController
before_action :set_tag, only: [:show, :edit, :update, :destroy, :toggle_featured, :toggle_official]
after_action :verify_authorized, except: [:index, :suggestions]
after_action :verify_policy_scoped, only: :index

def index
    @tags = policy_scope(Tag).includes(:posts)
    
    # Handle search
    if params[:search].present?
      search_term = params[:search].strip.downcase
      @tags = @tags.where('LOWER(name) LIKE ? OR LOWER(description) LIKE ?', 
                         "%#{search_term}%", "%#{search_term}%")
    end
    
    # Allow filtering by category
    if params[:category].present? && Tag::CATEGORIES.key?(params[:category])
      @tags = @tags.by_category(params[:category])
    end
    
    # Allow sorting
    case params[:sort]
    when 'trending'
      @tags = @tags.trending.limit(50)
    when 'featured'
      @tags = @tags.featured
    when 'official'
      @tags = @tags.official
    else
      @tags = @tags.order(:name)
    end
    
    @tags = @tags.page(params[:page]).per(50)
end

def show
    authorize @tag
    @posts = @tag.posts.includes(:user, :category).order(created_at: :desc).page(params[:page]).per(10)
end

def new
    @tag = Tag.new
    authorize @tag
end

def edit
    authorize @tag
end

def create
    @tag = Tag.new(tag_params)
    authorize @tag

    if @tag.save
    redirect_to @tag, notice: 'Tag was successfully created.'
    else
    render :new
    end
end

def update
    authorize @tag
    if @tag.update(tag_params)
    redirect_to @tag, notice: 'Tag was successfully updated.'
    else
    render :edit
    end
end

def destroy
    authorize @tag
    @tag.destroy
    redirect_to tags_url, notice: 'Tag was successfully destroyed.'
end

private

def set_tag
    @tag = Tag.find(params[:id])
end

def toggle_featured
    authorize @tag, :update?
    @tag.update!(is_featured: !@tag.is_featured)
    redirect_back(fallback_location: @tag, notice: "Tag #{@tag.is_featured? ? 'featured' : 'unfeatured'} successfully.")
end

def toggle_official
    authorize @tag, :update?
    @tag.update!(is_official: !@tag.is_official)
    redirect_back(fallback_location: @tag, notice: "Tag marked as #{@tag.is_official? ? 'official' : 'unofficial'}.")
end

def suggestions
    # Return tag suggestions for autocomplete
    query = params[:q]&.downcase&.strip
    category_filter = params[:category]
    
    if query.present? && query.length >= 2
      @tags = policy_scope(Tag).where('LOWER(name) LIKE ? OR LOWER(description) LIKE ?', 
                                     "%#{query}%", "%#{query}%")
      
      # Apply category filter if provided
      if category_filter.present? && Tag::CATEGORIES.key?(category_filter)
        @tags = @tags.by_category(category_filter)
      end
      
      @tags = @tags.includes(:posts)
                   .order(:name)
                   .limit(20)
                   .group_by(&:category)
    else
      @tags = policy_scope(Tag).featured.order(:name).limit(20).group_by(&:category)
    end
    
    # Return more detailed tag information
    result = @tags.transform_values do |tags|
      tags.map do |tag|
        {
          id: tag.id,
          name: tag.name,
          description: tag.description,
          category: tag.category,
          posts_count: tag.posts.count,
          is_featured: tag.respond_to?(:is_featured) ? tag.is_featured : false,
          is_official: tag.respond_to?(:is_official) ? tag.is_official : false
        }
      end
    end
    
    render json: result
end

private

def tag_params
    params.require(:tag).permit(:name, :description, :category, :is_official, :is_featured)
end
end
