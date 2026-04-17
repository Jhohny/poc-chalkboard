Rails.application.routes.draw do
  constraints subdomain: "app" do
    root "dashboard#show", as: :app_root
  end

  constraints subdomain: /^(www)?$/ do
    root "marketing/home#show"
  end
end
