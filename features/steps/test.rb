class Spinach::Features::Test < Spinach::FeatureSteps
  step 'I tested' do
    expect(true).to be(false)
  end
end
