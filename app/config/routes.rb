Rails.application.routes.draw do
  devise_for :users
  get "/" => "home#start", :as => "root"
  get "user" => 'user#list'
  post "user/edit" => 'user#edit'
  post "user/update" => 'user#update'
  get "user/edit" => 'user#edit'

#category
  get "category" => 'category#list'
  post "category" => 'category#add'
  get "category/change" => 'category#change_validation'
#document
  resources :documents, only: [:new, :create, :destroy]
  get "documents" => 'documents#new'
  get "documents/list" => 'documents#list'
  get "documents/download" => 'documents#download'
  get "documents/change" => 'documents#change_state'
  get "documents/delete" => 'documents#force_delete'
#db versions
  get "version" => 'version#view'
  get "version/delete" => 'version#delete'
  get "version/fix" => 'version#fix'
  get "version/revert" => 'version#revert'

#  resources :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
