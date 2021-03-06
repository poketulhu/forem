require "rails_helper"

RSpec.describe "DisplayAdEvents", type: :request do
  let(:user) { create(:user, :trusted) }
  let(:organization) { create(:organization) }
  let(:display_ad) { create(:display_ad, organization_id: organization.id) }

  describe "POST /display_ad_events" do
    context "when user signed in" do
      before do
        sign_in user
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(DisplayAdEventsController).to receive(:skip_ad_update?).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it "creates a display ad click event" do
        post "/display_ad_events", params: {
          display_ad_event: {
            display_ad_id: display_ad.id,
            context_type: "home",
            category: "click"
          }
        }
        expect(display_ad.reload.clicks_count).to eq(1)
      end

      it "creates a display ad impression event" do
        post "/display_ad_events", params: {
          display_ad_event: {
            display_ad_id: display_ad.id,
            context_type: "home",
            category: "impression"
          }
        }
        expect(display_ad.reload.impressions_count).to eq(1)
      end

      it "creates a display ad success rate" do
        ad_event_params = { display_ad_id: display_ad.id, context_type: "home" }

        4.times do
          post "/display_ad_events", params: { display_ad_event: ad_event_params.merge(category: "impression") }
        end

        post "/display_ad_events", params: { display_ad_event: ad_event_params.merge(category: "click") }

        expect(display_ad.reload.success_rate).to eq(0.25)
      end

      it "assigns event to current user" do
        post "/display_ad_events", params: {
          display_ad_event: {
            display_ad_id: display_ad.id,
            context_type: "home",
            category: "impression"
          }
        }
        expect(DisplayAdEvent.last.user_id).to eq(user.id)
      end
    end
  end
end
