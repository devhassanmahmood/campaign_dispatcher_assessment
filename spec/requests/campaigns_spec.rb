require 'rails_helper'

RSpec.describe "Campaigns", type: :request do
  describe "POST /campaigns" do
    context "with valid parameters" do
      it "creates a new campaign with recipients using nested attributes" do
        expect {
          post campaigns_path, params: {
            campaign: {
              title: "Test Campaign",
              recipients_attributes: {
                "0" => { name: "John Doe", email: "john@example.com" },
                "1" => { name: "Jane Smith", phone: "+1234567890" },
                "2" => { name: "Bob Johnson", email: "bob@example.com" }
              }
            }
          }
        }.to change(Campaign, :count).by(1)
          .and change(Recipient, :count).by(3)

        campaign = Campaign.last
        expect(campaign.title).to eq("Test Campaign")
        expect(campaign.status).to eq("pending")
        expect(campaign.recipients.count).to eq(3)
        expect(campaign.recipients.find_by(name: "John Doe").email).to eq("john@example.com")
        expect(campaign.recipients.find_by(name: "Jane Smith").phone).to eq("+1234567890")
      end

      it "redirects to the created campaign" do
        post campaigns_path, params: {
          campaign: {
            title: "Test Campaign",
            recipients_attributes: {
              "0" => { name: "John Doe", email: "john@example.com" }
            }
          }
        }

        expect(response).to redirect_to(campaign_path(Campaign.last))
      end

      it "rejects blank recipients" do
        expect {
          post campaigns_path, params: {
            campaign: {
              title: "Test Campaign",
              recipients_attributes: {
                "0" => { name: "", email: "", phone: "" },
                "1" => { name: "John Doe", email: "john@example.com" }
              }
            }
          }
        }.to change(Campaign, :count).by(1)
          .and change(Recipient, :count).by(1)

        campaign = Campaign.last
        expect(campaign.recipients.count).to eq(1)
        expect(campaign.recipients.first.name).to eq("John Doe")
      end
    end

    context "with invalid parameters" do
      it "does not create a new campaign without a title" do
        expect {
          post campaigns_path, params: {
            campaign: {
              title: "",
              recipients_attributes: {
                "0" => { name: "John Doe", email: "john@example.com" }
              }
            }
          }
        }.not_to change(Campaign, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a campaign without recipients" do
        expect {
          post campaigns_path, params: {
            campaign: {
              title: "Test Campaign",
              recipients_attributes: {
                "0" => { name: "", email: "", phone: "" }
              }
            }
          }
        }.not_to change(Campaign, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "validates recipient has either email or phone" do
        expect {
          post campaigns_path, params: {
            campaign: {
              title: "Test Campaign",
              recipients_attributes: {
                "0" => { name: "John Doe", email: "", phone: "" }
              }
            }
          }
        }.not_to change(Campaign, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "POST /campaigns/:id/start_dispatch" do
    let(:campaign) do
      Campaign.create!(
        title: "Test Campaign",
        recipients_attributes: {
          "0" => { name: "John", email: "john@example.com", status: "queued" },
          "1" => { name: "Jane", email: "jane@example.com", status: "queued" }
        }
      )
    end
    let!(:recipient1) { campaign.recipients.find_by(name: "John") }
    let!(:recipient2) { campaign.recipients.find_by(name: "Jane") }

    it "enqueues a DispatchCampaignJob" do
      expect {
        post start_dispatch_campaign_path(campaign)
      }.to have_enqueued_job(DispatchCampaignJob).with(campaign.id)
    end

    it "redirects to the campaign show page" do
      post start_dispatch_campaign_path(campaign)
      expect(response).to redirect_to(campaign_path(campaign))
    end
  end
end

