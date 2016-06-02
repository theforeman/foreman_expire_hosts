FactoryGirl.modify do
  factory :host do
    trait :expires_today do
      expired_on Date.today
    end

    trait :expired_grace do
      expired_on Date.today - 1
    end

    trait :expired do
      expired_on Date.today - 356
    end
  end
end
