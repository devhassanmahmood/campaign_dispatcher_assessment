class Campaign < ApplicationRecord
  has_many :recipients, dependent: :destroy
  accepts_nested_attributes_for :recipients, reject_if: :all_blank, allow_destroy: true

  validates :title, presence: true
  validates :status, inclusion: { in: %w[pending processing completed] }
  validate :at_least_one_recipient

  def progress_percentage
    return 0 if recipients.empty?
    (recipients.where(status: "sent").count.to_f / recipients.count * 100).round
  end

  def sent_count
    recipients.where(status: "sent").count
  end

  def total_count
    recipients.count
  end

  private

  def at_least_one_recipient
    valid_recipients = recipients.reject(&:marked_for_destruction?).reject { |r| r.name.blank? && r.email.blank? && r.phone.blank? }
    if valid_recipients.empty?
      errors.add(:base, "At least one recipient is required")
    end
  end
end
