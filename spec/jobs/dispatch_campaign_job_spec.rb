require 'rails_helper'

RSpec.describe DispatchCampaignJob, type: :job do
  let(:campaign) do
    Campaign.create!(
      title: "Test Campaign",
      recipients_attributes: {
        "0" => { name: "John", email: "john@example.com", status: "queued" },
        "1" => { name: "Jane", phone: "+1234567890", status: "queued" },
        "2" => { name: "Bob", email: "bob@example.com", status: "sent" }
      }
    )
  end
  let!(:recipient1) { campaign.recipients.find_by(name: "John") }
  let!(:recipient2) { campaign.recipients.find_by(name: "Jane") }
  let!(:recipient3) { campaign.recipients.find_by(name: "Bob") }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe "#perform" do
    it "updates campaign status to processing" do
      DispatchCampaignJob.perform_now(campaign.id)
      expect(campaign.reload.status).to eq("completed")
    end

    it "updates queued recipients to sent" do
      DispatchCampaignJob.perform_now(campaign.id)
      
      expect(recipient1.reload.status).to eq("sent")
      expect(recipient2.reload.status).to eq("sent")
      expect(recipient3.reload.status).to eq("sent")
    end

    it "does not update already sent recipients" do
      initial_sent_count = campaign.recipients.where(status: "sent").count
      DispatchCampaignJob.perform_now(campaign.id)
      
      expect(campaign.recipients.where(status: "sent").count).to be >= initial_sent_count
    end

    it "updates campaign status to completed after processing all recipients" do
      DispatchCampaignJob.perform_now(campaign.id)
      expect(campaign.reload.status).to eq("completed")
    end

    it "handles errors gracefully and marks recipient as failed" do
      allow_any_instance_of(DispatchCampaignJob).to receive(:sleep).and_raise(StandardError.new("Test error"))
      
      expect {
        DispatchCampaignJob.perform_now(campaign.id)
      }.not_to raise_error
      
      campaign.reload
      expect(campaign.status).to eq("completed")
      failed_recipients = campaign.recipients.where(status: "failed")
      expect(failed_recipients.count).to be > 0
    end
  end
end

