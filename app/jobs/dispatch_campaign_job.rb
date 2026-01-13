class DispatchCampaignJob < ApplicationJob
  def perform(campaign_id)
    campaign = Campaign.find(campaign_id)
    campaign.update(status: "processing")
    broadcast_status_update(campaign)

    campaign.recipients.where(status: "queued").find_each do |recipient|
      begin
        sleep(rand(1..5))
        recipient.update(status: "sent")
        broadcast_recipient_update(recipient)
        broadcast_campaign_update(campaign)
      rescue => e
        recipient.update(status: "failed")
        broadcast_recipient_update(recipient)
        broadcast_campaign_update(campaign)
        Rails.logger.error("Failed to send to recipient #{recipient.id}: #{e.message}")
      end
    end

    campaign.update(status: "completed")
    broadcast_campaign_update(campaign)
    broadcast_status_update(campaign)
  end

  private

  def broadcast_recipient_update(recipient)
    Turbo::StreamsChannel.broadcast_update_to(
      "campaign_#{recipient.campaign_id}",
      target: "recipient_#{recipient.id}",
      partial: "recipients/recipient",
      locals: { recipient: recipient }
    )
  rescue => e
    Rails.logger.error("Failed to broadcast recipient update: #{e.message}")
  end

  def broadcast_campaign_update(campaign)
    campaign.reload
    Turbo::StreamsChannel.broadcast_update_to(
      "campaign_#{campaign.id}",
      target: "campaign_progress",
      partial: "campaigns/progress",
      locals: { campaign: campaign }
    )
  rescue => e
    Rails.logger.error("Failed to broadcast campaign update: #{e.message}")
  end

  def broadcast_status_update(campaign)
    campaign.reload
    Turbo::StreamsChannel.broadcast_update_to(
      "campaign_#{campaign.id}",
      target: "campaign_status",
      partial: "campaigns/status",
      locals: { campaign: campaign }
    )
    Turbo::StreamsChannel.broadcast_update_to(
      "campaign_#{campaign.id}",
      target: "dispatch_button",
      partial: "campaigns/dispatch_button",
      locals: { campaign: campaign }
    )
  rescue => e
    Rails.logger.error("Failed to broadcast status update: #{e.message}")
  end
end
