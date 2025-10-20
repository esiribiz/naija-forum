class Admin::TagSuggestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_tag_suggestion, only: [:show, :approve, :reject]
  
  def index
    @tag_suggestions = TagSuggestion.includes(:user, :approved_by).recent
    
    # Filter by status
    case params[:status]
    when 'pending'
      @tag_suggestions = @tag_suggestions.pending
    when 'approved'
      @tag_suggestions = @tag_suggestions.approved_suggestions
    end
    
    # Filter by category
    if params[:category].present? && ApprovedTag::CATEGORIES.key?(params[:category])
      @tag_suggestions = @tag_suggestions.by_category(params[:category])
    end
    
    @tag_suggestions = @tag_suggestions.page(params[:page]).per(25)
    @pending_count = TagSuggestion.pending.count
  end

  def show
    # Check if a similar approved tag already exists
    @similar_approved_tags = ApprovedTag.search_by_name(@tag_suggestion.name).limit(5)
  end

  def approve
    begin
      @approved_tag = @tag_suggestion.approve!(current_user)
      redirect_to admin_tag_suggestions_path, 
                  notice: "Tag suggestion '#{@tag_suggestion.name}' has been approved and is now available."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_tag_suggestion_path(@tag_suggestion), 
                  alert: "Failed to approve tag: #{e.record.errors.full_messages.join(', ')}"
    end
  end

  def reject
    @tag_suggestion.reject!
    redirect_to admin_tag_suggestions_path, 
                notice: "Tag suggestion '#{@tag_suggestion.name}' has been rejected and removed."
  end
  
  def bulk_approve
    if params[:suggestion_ids].present?
      approved_count = 0
      errors = []
      
      TagSuggestion.where(id: params[:suggestion_ids]).find_each do |suggestion|
        begin
          suggestion.approve!(current_user)
          approved_count += 1
        rescue ActiveRecord::RecordInvalid => e
          errors << "#{suggestion.name}: #{e.record.errors.full_messages.join(', ')}"
        end
      end
      
      if approved_count > 0
        flash[:notice] = "#{approved_count} tag(s) approved successfully."
      end
      
      if errors.any?
        flash[:alert] = "Some tags failed to approve: #{errors.join('; ')}"
      end
    else
      flash[:alert] = "No tags selected for approval."
    end
    
    redirect_to admin_tag_suggestions_path
  end
  
  def bulk_reject
    if params[:suggestion_ids].present?
      rejected_count = TagSuggestion.where(id: params[:suggestion_ids]).count
      TagSuggestion.where(id: params[:suggestion_ids]).destroy_all
      flash[:notice] = "#{rejected_count} tag suggestion(s) rejected successfully."
    else
      flash[:alert] = "No tags selected for rejection."
    end
    
    redirect_to admin_tag_suggestions_path
  end
  
  private
  
  def set_tag_suggestion
    @tag_suggestion = TagSuggestion.find(params[:id])
  end
  
  def ensure_admin!
    redirect_to root_path, alert: 'Access denied.' unless current_user&.admin?
  end
end
