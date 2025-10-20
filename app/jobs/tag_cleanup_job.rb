class TagCleanupJob < ApplicationJob
  queue_as :low

  def perform
    Rails.logger.info "Starting tag cleanup job..."
    
    # Clean up unused tags older than 30 days
    cleanup_unused_tags
    
    # Clean up old rejected tag suggestions (older than 90 days)
    cleanup_old_suggestions
    
    # Sync approved tags with actual tag usage
    sync_approved_tag_usage
    
    Rails.logger.info "Tag cleanup job completed"
  end
  
  private
  
  def cleanup_unused_tags
    # Find tags that have no posts and are older than 30 days
    unused_tags = Tag.left_outer_joins(:post_tags)
                     .where(post_tags: { id: nil })
                     .where('tags.created_at < ?', 30.days.ago)
    
    count = unused_tags.count
    
    if count > 0
      Rails.logger.info "Removing #{count} unused tags"
      unused_tags.destroy_all
    else
      Rails.logger.info "No unused tags to clean up"
    end
  end
  
  def cleanup_old_suggestions
    # Remove old approved suggestions (keep for audit trail)
    old_approved = TagSuggestion.approved_suggestions
                                .where('approved_at < ?', 90.days.ago)
    
    approved_count = old_approved.count
    
    # Remove old rejected suggestions (no need to keep these)
    old_rejected = TagSuggestion.where('created_at < ? AND approved = false', 30.days.ago)
    rejected_count = old_rejected.count
    
    if approved_count > 0
      Rails.logger.info "Removing #{approved_count} old approved tag suggestions"
      old_approved.destroy_all
    end
    
    if rejected_count > 0
      Rails.logger.info "Removing #{rejected_count} old rejected tag suggestions"
      old_rejected.destroy_all
    end
    
    if approved_count == 0 && rejected_count == 0
      Rails.logger.info "No old tag suggestions to clean up"
    end
  end
  
  def sync_approved_tag_usage
    # Deactivate approved tags that haven't been used in 90 days
    unused_approved = ApprovedTag.joins(:tags)
                                 .joins('LEFT JOIN post_tags ON post_tags.tag_id = tags.id')
                                 .joins('LEFT JOIN posts ON posts.id = post_tags.post_id')
                                 .where('posts.created_at < ? OR posts.id IS NULL', 90.days.ago)
                                 .where(is_active: true)
                                 .distinct
    
    deactivated_count = unused_approved.count
    
    if deactivated_count > 0
      Rails.logger.info "Deactivating #{deactivated_count} unused approved tags"
      unused_approved.update_all(is_active: false)
    else
      Rails.logger.info "No approved tags to deactivate"
    end
    
    # Reactivate approved tags that have been used recently
    recently_used = ApprovedTag.joins(:tags)
                               .joins('INNER JOIN post_tags ON post_tags.tag_id = tags.id')
                               .joins('INNER JOIN posts ON posts.id = post_tags.post_id')
                               .where('posts.created_at > ?', 30.days.ago)
                               .where(is_active: false)
                               .distinct
    
    reactivated_count = recently_used.count
    
    if reactivated_count > 0
      Rails.logger.info "Reactivating #{reactivated_count} recently used approved tags"
      recently_used.update_all(is_active: true)
    else
      Rails.logger.info "No approved tags to reactivate"
    end
  end
end
