# frozen_string_literal: true

FactoryBot.modify do
  factory :host do
    trait :without_validation do
      # Turn off validation so we can create a host with an expiry date in the past
      to_create { |instance| instance.save(validate: false) }
    end

    trait :expires_in_a_year do
      expired_on { Date.today + 365 }
    end

    trait :expires_in_a_week do
      expired_on { Date.today + 7 }
    end

    trait :expires_today do
      without_validation
      expired_on { Date.today }
    end

    trait :expired_grace do
      without_validation
      expired_on { Date.today - 1 }
    end

    trait :expired do
      without_validation
      expired_on { Date.today - 356 }
    end
  end
end
