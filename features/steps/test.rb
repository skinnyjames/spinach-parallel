class Spinach::Features::Test < Spinach::FeatureSteps
  step 'I tested' do
    resp = RestClient.get "https://www.google.com"
    expect(resp.code).to be(200)
  end
end
