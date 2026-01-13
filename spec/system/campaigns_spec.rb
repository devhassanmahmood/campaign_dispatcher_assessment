require 'rails_helper'

RSpec.describe "Campaign dispatch flow", type: :system do
  include ActiveJob::TestHelper

  before do
    driven_by(:selenium_chrome_headless)
    ActiveJob::Base.queue_adapter = :test
  end

  describe "creating and dispatching a campaign" do
    it "allows user to create a campaign with nested recipient forms" do
      visit root_path

      click_link "New Campaign"

      fill_in "Title", with: "Test Campaign"

      within first("[data-nested-form-target='recipient']") do
        fill_in "Name", with: "John Doe"
        fill_in "Email", with: "john@example.com"
      end

      click_button "+ Add Recipient"
      sleep 0.5

      recipients = all("[data-nested-form-target='recipient']")
      within recipients[1] do
        fill_in "Name", with: "Jane Smith"
        fill_in "Phone", with: "+1234567890"
      end

      click_button "+ Add Recipient"
      sleep 0.5

      recipients = all("[data-nested-form-target='recipient']")
      within recipients[2] do
        fill_in "Name", with: "Bob Johnson"
        fill_in "Email", with: "bob@example.com"
      end

      click_button "Create Campaign"

      expect(page).to have_content("Test Campaign")
      expect(page).to have_content("Status")
      expect(page).to have_content("Pending")
      expect(page).to have_content("John Doe")
      expect(page).to have_content("Jane Smith")
      expect(page).to have_content("Bob Johnson")

      expect(page).to have_button("Start Dispatch")
      
      campaign = Campaign.last
      expect(campaign.recipients.count).to eq(3)
      expect(campaign.recipients.pluck(:status).uniq).to eq(["queued"])
    end

    it "allows user to remove recipients from the form" do
      visit root_path

      click_link "New Campaign"

      fill_in "Title", with: "Test Campaign"

      within first("[data-nested-form-target='recipient']") do
        fill_in "Name", with: "John Doe"
        fill_in "Email", with: "john@example.com"
      end

      click_button "+ Add Recipient"
      sleep 0.5

      recipients = all("[data-nested-form-target='recipient']")
      within recipients[1] do
        fill_in "Name", with: "Jane Smith"
        fill_in "Email", with: "jane@example.com"
      end

      recipients = all("[data-nested-form-target='recipient']")
      expect(recipients.count).to eq(2)
      
      within recipients[1] do
        find("button[data-action*='remove']").click
      end
      sleep 1

      visible_recipients = all("[data-nested-form-target='recipient']", visible: true)
      expect(visible_recipients.count).to eq(1)

      click_button "Create Campaign"
      sleep 1

      campaign = Campaign.last
      expect(campaign).to be_present
      expect(campaign.recipients.count).to eq(1)
      expect(campaign.recipients.first.name).to eq("John Doe")
    end

    it "updates recipient status in real-time during dispatch" do
      campaign = Campaign.create!(
        title: "Test Campaign",
        recipients_attributes: {
          "0" => { name: "John", email: "john@example.com", status: "queued" },
          "1" => { name: "Jane", email: "jane@example.com", status: "queued" }
        }
      )
      recipient1 = campaign.recipients.find_by(name: "John")
      recipient2 = campaign.recipients.find_by(name: "Jane")

      visit campaign_path(campaign)

      expect(page).to have_content("Queued", count: 2)

      click_button "Start Dispatch"
      sleep 2

      expect(page).to have_content("Test Campaign")

      perform_enqueued_jobs

      sleep 2

      campaign.reload
      expect(campaign.status).to eq("completed")
      expect(campaign.recipients.pluck(:status).uniq).to include("sent")
    end

    it "shows progress updates during dispatch" do
      recipients_attrs = {}
      5.times do |i|
        recipients_attrs[i.to_s] = {
          name: "Recipient #{i + 1}",
          email: "recipient#{i + 1}@example.com",
          status: "queued"
        }
      end
      campaign = Campaign.create!(
        title: "Test Campaign",
        recipients_attributes: recipients_attrs
      )

      visit campaign_path(campaign)

      expect(page).to have_content("0 / 5")

      DispatchCampaignJob.perform_now(campaign.id)

      sleep 2

      campaign.reload
      expect(campaign.status).to eq("completed")
      expect(page).to have_content("5 / 5")
    end
  end
end

