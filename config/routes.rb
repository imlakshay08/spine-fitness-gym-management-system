### FOR REST API ######
Rails.application.routes.draw do
  namespace :api do
    resources :biometric_attendances, only: [:create]
  end
  get  '/iclock/cdata',      to: 'api/adms#handshake'
  post '/iclock/cdata',      to: 'api/adms#receive'
  get  '/iclock/getrequest', to: 'api/adms#getrequest'
end

Rails.application.routes.draw do  
  get   '/index.html.var'=>'login#index'
  root  'login#index'  
  get   '/404.shtml'=>"invoice#show" 
  get   "/404" ,:to =>"erros#not_found"
  get   "/422" ,:to =>"erros#not_found"
  get   "/500" ,:to =>"erros#unacceptable"
  #:return_ca_material  
  resources :login,:logout
end
Rails.application.routes.draw do
  get   "dashboard/dashboard_refresh" 
  get   "dashboard/search"=>"dashboard#index"
  post  "dashboard/search"=>"dashboard#index"
  post  "dashboard/ajax"=>"dashboard#index" 
  post "dashboard/ajax_process" => "dashboard#ajax_process"
  resources :dashboard
end

Rails.application.routes.draw do
  get  'create_user/user_list_refresh'
 get   'create_user/index'=>'create_user#index'
 post  'create_user/index'=>'create_user#index'
 get   'create_user/user_list'=>"create_user#user_list"
 get   'create_user/user_list/search'=>"create_user#user_list"
 post  'create_user/user_list/search'=>"create_user#user_list"
 get   'create_user/:id/deletes'=>"create_user#destroy"
 get   'create_user/:id'=>"create_user#index"
 post  'create_user/ajax_process'=>'create_user#ajax_process'
 resources :create_user
end

Rails.application.routes.draw do
  get   'category_list/referesh_category_list'
  get   'category_list/index'=>'category_list#index'
  post  'category_list/index'=>'category_list#index'
  post  'category_list/search' =>'category_list#index'
  get   'category_list/search' =>'category_list#index'
  get   'category_list/add_category'=>'category_list#add_category'
  post  'category_list/add_category'=>'category_list#add_category'
  get   "category_list/:id"=>'category_list#index'
  get   "category_list/add_category/:id"=>'category_list#add_category'
  get   "category_list/:id/deletes"=>'category_list#destroy'
  resources :category_list
end

Rails.application.routes.draw do
  get   'stock_list/referesh_stock_list'
  get   'stock_list/index'=>'stock_list#index'
  post  'stock_list/index'=>'stock_list#index'
  post  'stock_list/search' =>'stock_list#index'
  get   'stock_list/search' =>'stock_list#index'
  get   'stock_list/add_stock'=>'stock_list#add_stock'
  post  'stock_list/add_stock'=>'stock_list#add_stock'
  get   "stock_list/:id"=>'stock_list#index'
  get   "stock_list/add_stock/:id"=>'stock_list#add_stock'
  get   "stock_list/:id/deletes"=>'stock_list#destroy'
  resources :stock_list
end

Rails.application.routes.draw do
  get   'stock_inventory/referesh_stock_inventory'
  get   'stock_inventory/index'=>'stock_inventory#index'
  post  'stock_inventory/index'=>'stock_inventory#index'
  post  'stock_inventory/search' =>'stock_inventory#index'
  get   'stock_inventory/search' =>'stock_inventory#index'
  get   'stock_inventory/add_stock_inventory'=>'stock_inventory#add_stock_inventory'
  post  'stock_inventory/add_stock_inventory'=>'stock_inventory#add_stock_inventory'
  get   "stock_inventory/:id"=>'stock_inventory#index'
  get   "stock_inventory/add_stock_inventory/:id"=>'stock_inventory#add_stock_inventory'
  get   "stock_inventory/:id/deletes"=>'stock_inventory#destroy'
  resources :stock_inventory
end


Rails.application.routes.draw do
  get   'membership_plan/referesh_membership_plan'
  get   'membership_plan/index'=>'membership_plan#index'
  post  'membership_plan/index'=>'membership_plan#index'
  post  'membership_plan/search' =>'membership_plan#index'
  get   'membership_plan/search' =>'membership_plan#index'
  get   'membership_plan/add_membership_plan'=>'membership_plan#add_membership_plan'
  post  'membership_plan/add_membership_plan'=>'membership_plan#add_membership_plan'
  get   "membership_plan/:id"=>'stock_inventory#index'
  get   "membership_plan/add_membership_plan/:id"=>'membership_plan#add_membership_plan'
  get   "membership_plan/:id/deletes"=>'membership_plan#destroy'
  resources :membership_plan
end

Rails.application.routes.draw do
  get   'member_list/referesh_member_list'
  get   'member_list/index'=>'member_list#index'
  post  'member_list/index'=>'member_list#index'
  post  'member_list/search' =>'member_list#index'
  get   'member_list/search' =>'member_list#index'
  get   'member_list/add_member'=>'member_list#add_member'
  post  'member_list/add_member'=>'member_list#add_member'
  get   "member_list/:id"=>'member_list#index'
  get   "member_list/add_member/:id"=>'member_list#add_member'
  get   "member_list/:id/deletes"=>'member_list#destroy'
  post  "member_list/faculty_ajax_img"=>"member_list#save_faculty_img"
  post  "member_list/ajax_process"=>"member_list#ajax_process" 
  resources :member_list
end

Rails.application.routes.draw do
  get   'staff_list/referesh_staff_list'
  get   'staff_list/index'=>'staff_list#index'
  post  'staff_list/index'=>'staff_list#index'
  post  'staff_list/search' =>'staff_list#index'
  get   'staff_list/search' =>'staff_list#index'
  get   'staff_list/add_staff'=>'staff_list#add_staff'
  post  'staff_list/add_staff'=>'staff_list#add_staff'
  get   "staff_list/:id"=>'staff_list#index'
  get   "staff_list/add_staff/:id"=>'staff_list#add_staff'
  get   "staff_list/:id/deletes"=>'staff_list#destroy'
  post  "staff_list/faculty_ajax_img"=>"staff_list#save_faculty_img"
  post  "staff_list/ajax_process"=>"staff_list#ajax_process" 
  resources :staff_list
end

Rails.application.routes.draw do
  get   'trainer_list/referesh_trainer_list'
  get   'trainer_list/index'=>'trainer_list#index'
  post  'trainer_list/index'=>'trainer_list#index'
  post  'trainer_list/search' =>'trainer_list#index'
  get   'trainer_list/search' =>'trainer_list#index'
  get   'trainer_list/add_trainer'=>'trainer_list#add_trainer'
  post  'trainer_list/add_trainer'=>'trainer_list#add_trainer'
  get   "trainer_list/:id"=>'trainer_list#index'
  get   "trainer_list/add_trainer/:id"=>'trainer_list#add_trainer'
  get   "trainer_list/:id/deletes"=>'trainer_list#destroy'
  post  "trainer_list/faculty_ajax_img"=>"trainer_list#save_faculty_img"
  post  "trainer_list/ajax_process"=>"trainer_list#ajax_process" 
  resources :trainer_list
end

Rails.application.routes.draw do
  get   'member_subscriptions/referesh_member_subscriptions'
  get   'member_subscriptions/index'=>'member_subscriptions#index'
  post  'member_subscriptions/index'=>'member_subscriptions#index'
  post  'member_subscriptions/search' =>'member_subscriptions#index'
  get   'member_subscriptions/search' =>'member_subscriptions#index'
  get   'member_subscriptions/add_member_subscriptions'=>'member_subscriptions#add_member_subscriptions'
  post  'member_subscriptions/add_member_subscriptions'=>'member_subscriptions#add_member_subscriptions'
  get   "member_subscriptions/:id"=>'member_subscriptions#index'
  get   "member_subscriptions/add_member_subscriptions/:id"=>'member_subscriptions#add_member_subscriptions'
  get   "member_subscriptions/:id/deletes"=>'member_subscriptions#destroy'
  post  "member_subscriptions/ajax_process"=>"member_subscriptions#ajax_process" 
  resources :member_subscriptions
end

Rails.application.routes.draw do
  get   'cron/send_expiry_whatsapp'=>'cron#send_expiry_whatsapp'
  post "/webhooks/interakt" => "webhooks/interakt#receive"
  get 'cron/sync_subscription_status'  => 'cron#sync_subscription_status' 
  resources :cron
end

Rails.application.routes.draw do
  get   'issue_amount/referesh_issue_amount'
  get   'issue_amount/index'=>'issue_amount#index'
  post  'issue_amount/index'=>'issue_amount#index'
  post  'issue_amount/search' =>'issue_amount#index'
  get   'issue_amount/search' =>'issue_amount#index'
  get   'issue_amount/add_issue_amount'=>'issue_amount#add_issue_amount'
  post  'issue_amount/add_issue_amount'=>'issue_amount#add_issue_amount'
  get   "issue_amount/staff_balance"=>'issue_amount#staff_balance'
  post  "issue_amount/staff_balance"=>'issue_amount#staff_balance'
  get   "issue_amount/:id"=>'issue_amount#index'
  get   "issue_amount/add_issue_amount/:id"=>'issue_amount#add_issue_amount'
  get   "issue_amount/:id/deletes"=>'issue_amount#destroy'
  post  "issue_amount/faculty_ajax_img"=>"issue_amount#save_faculty_img"
  post  "issue_amount/ajax_process"=>"issue_amount#ajax_process" 
  resources :issue_amount
end

Rails.application.routes.draw do
  get   "change_password/change_password_refresh" 
  get   "change_password/:id"=>"change_password#index"
  post  "change_password/:id"=>"change_password#index"  
  get   "change_password/search"=>"change_password#index"
  post  "change_password/search"=>"change_password#index"
 
  resources :change_password
end

Rails.application.routes.draw do
  get   'house_list/referesh_house_list'
  get   'house_list/index'=>'house_list#index'
  post  'house_list/index'=>'house_list#index'
  post  'house_list/search' =>'house_list#index'
  get   'house_list/search' =>'house_list#index'
  get   'house_list/add_house'=>'house_list#add_house'
  post  'house_list/add_house'=>'house_list#add_house'
  get   "house_list/:id"=>'house_list#index'
  get   "house_list/add_house/:id"=>'house_list#add_house'
  get   "house_list/:id/deletes"=>'house_list#destroy'
  resources :house_list
end

Rails.application.routes.draw do
  get   'log_audit/refresh_log_audit'
  get   'log_audit/index'=>'log_audit#index'
  post  'log_audit/index'=>'log_audit#index'
  get   'log_audit/search'=>"log_audit#index"
  post  'log_audit/search'=>"log_audit#index"
  get   'log_audit/:id/deletes'=>"log_audit#destroy"
  get   'log_audit/:id'=>"log_audit#index"
  get   '/404.shtml'=>"invoice#show"
  get   "/404" ,:to =>"erros#not_found"
  get   "/422" ,:to =>"erros#not_found"
  get   "/500" ,:to =>"erros#unacceptable"
  #:return_ca_material
  resources :log_audit
end

Rails.application.routes.draw do
  get   "company/:id"=>'company#index'
  post  "company/search"=>"company#index"
  post  "company/ajax_process"=>"company#index" 
  resources :company
end

Rails.application.routes.draw do
  get   'holiday/referesh_holiday'
  get   'holiday/index'=>'holiday#index'
  post  'holiday/index'=>'holiday#index'
  post  'holiday/search' =>'holiday#index'
  get   'holiday/search' =>'holiday#index'
  get   'holiday/add_holiday'=>'holiday#add_holiday'
  post  'holiday/add_holiday'=>'holiday#add_holiday'
  get   "holiday/:id"=>'holiday#index'
  get   "holiday/add_holiday/:id"=>'holiday#add_holiday'
  get   "holiday/:id/deletes"=>'holiday#destroy'
  resources :holiday
end

Rails.application.routes.draw do 
  post  "common_process/:ajax_process"=>"common_process#ajax_process"
  resources :common_process
end
