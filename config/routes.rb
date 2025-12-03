
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
  get   'course_list/referesh_course_list'
  get   'course_list/index'=>'course_list#index'
  post  'course_list/index'=>'course_list#index'
  post  'course_list/search' =>'course_list#index'
  get   'course_list/search' =>'course_list#index'
  get   'course_list/add_course'=>'course_list#add_course'
  post  'course_list/add_course'=>'course_list#add_course'
  get   "course_list/:id"=>'course_list#index'
  get   "course_list/add_course/:id"=>'course_list#add_course'
  get   "course_list/:id/deletes"=>'course_list#destroy'
  resources :course_list
end

Rails.application.routes.draw do
  get   'subject_list/referesh_subject_list'
  post  "subject_list/ajax_process"=>"subject_list#ajax_process"
  get   'subject_list/index'=>'subject_list#index'
  post  'subject_list/index'=>'subject_list#index'
  post  'subject_list/search' =>'subject_list#index'
  get   'subject_list/search' =>'subject_list#index'
  get   'subject_list/add_subject'=>'subject_list#add_subject'
  post  'subject_list/add_subject'=>'subject_list#add_subject'
  get   "subject_list/:id"=>'subject_list#index'
  get   "subject_list/add_subject/:id"=>'subject_list#add_subject'
  get   "subject_list/:id/deletes"=>'subject_list#destroy'
  resources :subject_list
end

Rails.application.routes.draw do
  get   'fee_list/referesh_fee_list'
  get   'fee_list/index'=>'fee_list#index'
  post  'fee_list/index'=>'fee_list#index'
  post  'fee_list/search' =>'fee_list#index'
  get   'fee_list/search' =>'fee_list#index'
  get   'fee_list/add_fee_structure'=>'fee_list#add_fee_structure'
  post  'fee_list/add_fee_structure'=>'fee_list#add_fee_structure'
  get   "fee_list/:id"=>'fee_list#index'
  get   "fee_list/add_fee_structure/:id"=>'fee_list#add_fee_structure'
  get   "fee_list/:id/deletes"=>'fee_list#destroy'
  post  "fee_list/ajax_process"=>"fee_list#ajax_process"
  get   "fee_list/add_fee_structure/:id/deletefee"=>'fee_list#deletefee'

  resources :fee_list
end

Rails.application.routes.draw do
  get   'student_list/referesh_student_list'
  get   'student_list/index'=>'student_list#index'
  post  'student_list/index'=>'student_list#index'
  post  'student_list/search' =>'student_list#index'
  get   'student_list/search' =>'student_list#index'
  get   'student_list/student_admission'=>'student_list#student_admission'
  post  'student_list/student_admission'=>'student_list#student_admission'
  get   "student_list/:id"=>'student_list#index'
  get   "student_list/student_admission/:id"=>'student_list#student_admission'
  post   "student_list/student_admission/:id"=>'student_list#student_admission'
  get   "student_list/:id/deletes"=>'student_list#destroy'
  get   "student_list/student_admission/:id/deleteparent"=>'student_list#deleteparent'
  post  'student_list/ajax_process'=>'student_list#ajax_process'
  resources :student_list
end

Rails.application.routes.draw do
  get   'component_list/referesh_component_list'
  get   'component_list/index'=>'component_list#index'
  post  'component_list/index'=>'component_list#index'
  post  'component_list/search' =>'component_list#index'
  get   'component_list/search' =>'component_list#index'
  get   'component_list/add_component'=>'component_list#add_component'
  post  'component_list/add_component'=>'component_list#add_component'
  get   "component_list/:id"=>'component_list#index'
  get   "component_list/add_component/:id"=>'component_list#add_component'
  get   "component_list/:id/deletes"=>'component_list#destroy'
  resources :component_list
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
  get   'faculty_list/referesh_faculty_list'
  get   'faculty_list/index'=>'faculty_list#index'
  post  'faculty_list/index'=>'faculty_list#index'
  post  'faculty_list/search' =>'faculty_list#index'
  get   'faculty_list/search' =>'faculty_list#index'
  get   'faculty_list/add_faculty'=>'faculty_list#add_faculty'
  post  'faculty_list/add_faculty'=>'faculty_list#add_faculty'
  get   "faculty_list/:id"=>'faculty_list#index'
  get   "faculty_list/add_faculty/:id"=>'faculty_list#add_faculty'
  get   "faculty_list/:id/deletes"=>'faculty_list#destroy'
  post  "faculty_list/faculty_ajax_img"=>"faculty_list#save_faculty_img"
  post  "faculty_list/ajax_process"=>"faculty_list#ajax_process" 
  resources :faculty_list
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
  get   "change_password/change_password_refresh" 
  get   "change_password/:id"=>"change_password#index"
  post  "change_password/:id"=>"change_password#index"  
  get   "change_password/search"=>"change_password#index"
  post  "change_password/search"=>"change_password#index"
 
  resources :change_password
end

Rails.application.routes.draw do
  get   "student_profile/search"=>"student_profile#index"
  post  "student_profile/search"=>"student_profile#index"
  post  "student_profile/ajax"=>"student_profile#index" 
  resources :student_profile

end


Rails.application.routes.draw do
  get   "time_table/search"=>"time_table#index"
  post  "time_table/search"=>"time_table#index"
  get   "time_table/faculty_view"=>"time_table#faculty_view"
  post  "time_table/ajax_process"=>"time_table#ajax_process" 
  resources :time_table
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
  get   "mark_attendance/search"=>"mark_attendance#index"
  post  "mark_attendance/search"=>"mark_attendance#index"
  post  "mark_attendance/ajax_process"=>"mark_attendance#ajax_process" 
  post "mark_attendance/get_students_lists" => "mark_attendance#get_students_lists"
  resources :mark_attendance
end

Rails.application.routes.draw do
  get   "special_attendance/referesh_special_attendance"
  get   'special_attendance/index'=>'special_attendance#index'
  post  'special_attendance/index'=>'special_attendance#index'
  post  "special_attendance/search"=>"special_attendance#index"
  get   "special_attendance/search"=>"special_attendance#index"
  post  "special_attendance/ajax_process"=>"special_attendance#ajax_process" 
  get   'special_attendance/:id'=>'special_attendance#index'
  resources :special_attendance
end

Rails.application.routes.draw do 
  get   "print_student_id_card/referesh_print_student_id_card"
  post  "print_student_id_card/ajax_process"=>"print_student_id_card#ajax_process"
  get   "print_student_id_card/search"=>"print_student_id_card#index"
  post  "print_student_id_card/search"=>"print_student_id_card#index"
  get   "print_student_id_card/:id"=>"print_student_id_card#show"
  post  "print_student_id_card/:id"=>"print_student_id_card#show"
  resources :print_student_id_card
 end

 Rails.application.routes.draw do
  get   'student_transaction_list/referesh_student_transaction_list'
  get   'student_transaction_list/index'=>'student_transaction_list#index'
  post  'student_transaction_list/index'=>'student_transaction_list#index'
  post  'student_transaction_list/search' =>'student_transaction_list#index'
  get   'student_transaction_list/search' =>'student_transaction_list#index'
  get   'student_transaction_list/add_student_transaction'=>'student_transaction_list#add_student_transaction'
  post  'student_transaction_list/add_student_transaction'=>'student_transaction_list#add_student_transaction'
  post  'student_transaction_list/ajax_process'=>'student_transaction_list#ajax_process'
  get   "student_transaction_list/:id"=>'student_transaction_list#index'
  get   "student_transaction_list/add_student_transaction/:id"=>'student_transaction_list#add_student_transaction'
  get   "student_transaction_list/add_student_transaction/:id/deletes"=>'student_transaction_list#destroy'
  resources :student_transaction_list
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
  get   "faculty_dashboard/:id"=>'faculty_dashboard#index'
  post  "faculty_dashboard/search"=>"faculty_dashboard#index"
  post  "faculty_dashboard/ajax_process"=>"faculty_dashboard#index" 
  resources :faculty_dashboard
end

Rails.application.routes.draw do
  get   "student_info/:id"=>'student_info#index'
  post  "student_info/search"=>"student_info#index"
  post  "student_info/ajax_process"=>"student_info#ajax_process" 
  resources :student_info
end

Rails.application.routes.draw do
  post  'student_data_import/ajax_process'=>'student_data_import#ajax_process' 
  get   '/404.shtml'=>"invoice#show"
  get   "/404" ,:to =>"erros#not_found"
  get   "/422" ,:to =>"erros#not_found"
  get   "/500" ,:to =>"erros#unacceptable"
  resources :student_data_import
end

Rails.application.routes.draw do
  get   "time_table_date_parameter/search"=>"time_table_date_parameter#index"
  post  "time_table_date_parameter/search"=>"time_table_date_parameter#index"
  post  "time_table_date_parameter/ajax_process"=>"time_table_date_parameter#ajax_process" 
  resources :time_table_date_parameter
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
  get   "special_attendance_params/search"=>"special_attendance_params#index"
  post  "special_attendance_params/search"=>"special_attendance_params#index"
  post  "special_attendance_params/ajax_process"=>"special_attendance_params#ajax_process" 
  get   'special_attendance_params/special_attendance_params_list'=>'special_attendance_params#special_attendance_params_list'
  post  'special_attendance_params/special_attendance_params_list'=>'special_attendance_params#special_attendance_params_list'
  get   'special_attendance_params/special_attendance_params_list/search'=>"special_attendance_params#special_attendance_params_list"
  post  'special_attendance_params/special_attendance_params_list/search'=>"special_attendance_params#special_attendance_params_list"
  get   "special_attendance_params/:id"=>'special_attendance_params#index'  
  get   "special_attendance_params/:id/deletes"=>"special_attendance_params#destroy"

  resources :special_attendance_params
end

Rails.application.routes.draw do
  get   "attendance_reports/referesh_attendance_reports"
  get   'attendance_reports/index'=>'attendance_reports#index'
  post  'attendance_reports/index'=>'attendance_reports#index'
  post  "attendance_reports/search"=>"attendance_reports#index"
  get   "attendance_reports/search"=>"attendance_reports#index"
  post  "attendance_reports/ajax_process"=>"attendance_reports#ajax_process" 
  get   'attendance_reports/:id'=>'attendance_reports#index'
  resources :attendance_reports
end

Rails.application.routes.draw do
  post  'fee_import/ajax_process'=>'fee_import#ajax_process' 
  get   '/404.shtml'=>"invoice#show"
  get   "/404" ,:to =>"erros#not_found"
  get   "/422" ,:to =>"erros#not_found"
  get   "/500" ,:to =>"erros#unacceptable"
  resources :fee_import
end

Rails.application.routes.draw do
  get   "fee_process/referesh_fee_process"
  get   'fee_process/index'=>'fee_process#index'
  post  'fee_process/index'=>'fee_process#index'
  post  "fee_process/ajax_process"=>"fee_process#ajax_process" 
  post  "fee_process/search"=>"fee_process#index"
  get   "fee_process/search"=>"fee_process#index"
  get   'fee_process/:id'=>'fee_process#index'
  resources :fee_process
end

Rails.application.routes.draw do
  get   "fee_dashboard/fee_dashboard_refresh" 
  post  "fee_dashboard/ajax_process"=>"fee_dashboard#ajax_process" 
  get   "fee_dashboard/search"=>"fee_dashboard#index"
  post  "fee_dashboard/search"=>"fee_dashboard#index"

  resources :fee_dashboard
end

Rails.application.routes.draw do 
  post  "common_process/:ajax_process"=>"common_process#ajax_process"
  resources :common_process
end

Rails.application.routes.draw do 
  get   "faculty_id_card/referesh_faculty_id_card"
  post  "faculty_id_card/ajax_process"=>"faculty_id_card#ajax_process"
  get   "faculty_id_card/search"=>"faculty_id_card#index"
  post  "faculty_id_card/search"=>"faculty_id_card#index"
  get   "faculty_id_card/:id"=>"faculty_id_card#show"
  post  "faculty_id_card/:id"=>"faculty_id_card#show"
  resources :faculty_id_card
 end

Rails.application.routes.draw do
  get   "year_end_process/referesh_year_end_process"
  get   'year_end_process/index'=>'year_end_process#index'
  post  'year_end_process/index'=>'year_end_process#index'
  post  "year_end_process/ajax_process"=>"year_end_process#ajax_process" 
  post  "year_end_process/search"=>"year_end_process#index"
  get   "year_end_process/search"=>"year_end_process#index"
  get   'year_end_process/:id'=>'year_end_process#index'
  resources :year_end_process
end

Rails.application.routes.draw do
  get   "process_special_attendance/referesh_process_special_attendance"
  get   'process_special_attendance/index'=>'process_special_attendance#index'
  post  'process_special_attendance/index'=>'process_special_attendance#index'
  post  "process_special_attendance/ajax_process"=>"process_special_attendance#ajax_process" 
  post  "process_special_attendance/search"=>"process_special_attendance#index"
  get   "process_special_attendance/search"=>"process_special_attendance#index"
  get   'process_special_attendance/:id'=>'process_special_attendance#index'
  resources :process_special_attendance
end

Rails.application.routes.draw do
  get   "faculty_attendance_report/referesh_faculty_attendance_report"
  get   'faculty_attendance_report/index'=>'faculty_attendance_report#index'
  post  'faculty_attendance_report/index'=>'faculty_attendance_report#index'
  post  "faculty_attendance_report/search"=>"faculty_attendance_report#index"
  get   "faculty_attendance_report/search"=>"faculty_attendance_report#index"
  post  "faculty_attendance_report/ajax_process"=>"faculty_attendance_report#ajax_process" 
  get   'faculty_attendance_report/:id'=>'faculty_attendance_report#index'
  resources :faculty_attendance_report
end