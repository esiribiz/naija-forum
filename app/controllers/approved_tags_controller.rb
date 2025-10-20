class ApprovedTagsController < ApplicationController
  # Public endpoint for autocomplete functionality
  def index
    @approved_tags = ApprovedTag.active.order(:name)

    # Filter by category if specified
    if params[:category].present? && ApprovedTag::CATEGORIES.key?(params[:category])
      @approved_tags = @approved_tags.by_category(params[:category])
    end

    # Search by name if query provided
    if params[:q].present?
      @approved_tags = @approved_tags.search_by_name(params[:q]).limit(20)
    else
      @approved_tags = @approved_tags.featured.limit(20)
    end

    respond_to do |format|
      format.json do
        render json: @approved_tags.group_by(&:category).transform_values do |tags|
          tags.map { |tag| { name: tag.name, category: tag.category, description: tag.description } }
        end
      end
      format.html do
        @approved_tags = @approved_tags.page(params[:page]).per(50)
      end
    end
  end

  def suggestions
    # Endpoint specifically for tag input suggestions
    query = params[:q]&.downcase&.strip

    if query.present? && query.length >= 2
      @tags = ApprovedTag.active.search_by_name(query).order(:name).limit(20)
    else
      @tags = ApprovedTag.active.featured.order(:name).limit(20)
    end

    render json: @tags.group_by(&:category).transform_values do |tags|
      tags.map do |tag|
        {
          name: tag.name,
          category: tag.category,
          description: tag.description,
          badge_color: tag.badge_color
        }
      end
    end
  end
end
