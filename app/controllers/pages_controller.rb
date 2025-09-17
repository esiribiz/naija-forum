class PagesController < ApplicationController
  def about
  end

  def contact
  end
  
  def submit_contact
    # For now, we'll just redirect with a success message
    # In a real application, you'd want to:
    # - Validate the form data
    # - Send an email notification
    # - Save to database
    # - Use a background job for email sending
    
    contact_params = params.permit(:first_name, :last_name, :email, :subject, :message)
    
    if contact_params[:email].present? && contact_params[:message].present?
      # TODO: Send email notification
      # TODO: Save to database
      
      redirect_to contact_path, notice: "Thank you for your message! We'll get back to you within 24-48 hours."
    else
      redirect_to contact_path, alert: "Please fill in all required fields (email and message)."
    end
  end
end
