require "rails_helper"

RSpec.describe EventsController, type: :controller do
  let!(:event1) { FactoryBot.create(:event, starts_at: Time.current) }
  let!(:event2) { FactoryBot.create(:event, starts_at: Time.current) }
  describe "GET index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it 'should render index template' do
      get :index
      expect(response).to render_template('index')
    end

    it "assigns events" do
      get :index
      expect(assigns(:events).pluck(:id)).to eq([ event1.id, event2.id ])
    end
  end
end
