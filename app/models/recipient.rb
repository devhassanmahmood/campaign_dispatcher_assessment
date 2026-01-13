class Recipient < ApplicationRecord
  belongs_to :campaign

  validates :name, presence: true
  validates :status, inclusion: { in: %w[queued sent failed] }
  validate :email_or_phone_present

  private

  def email_or_phone_present
    if email.blank? && phone.blank?
      errors.add(:base, "Either email or phone must be present")
    end
  end
end
