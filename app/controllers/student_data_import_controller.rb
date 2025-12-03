class StudentDataImportController < ApplicationController
  before_action      :require_login
  skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
  include ErpModule::Common
  helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct  
    def index
    end

    def create
        @compcodes  = session[:loggedUserCompCode]
        session[:request_months_download]   = nil 
        session[:request_years_download]    = nil
        session[:request_process_download]  = nil 
        $compcodes  = @compcodes
        isFlags     = true
        $xcount      = 0
        $updatecount = 0
        data = ""
        begin
         if params[:file]!=nil && params[:file]!=''    
            $isimport = params[:process_file_data].to_s
                    ############### IMPORT CUSTOMER & PRODUCT DATA ITEMS#############
                    if params[:process_file_data].to_s!=nil && params[:process_file_data].to_s!='' && params[:process_file_data].to_s =='employee'
                      $checkscaleupdate = params[:checkscale_updated]
                      if MstStudent.import(params[:file])
                          if params[:checkscale_updated] && params[:checkscale_updated].to_s == 'UPDATE'
                              flash[:error] =  "Groups updated successfully "+(($xcount.to_s.length.to_i >0 ) ? $xcount.to_s : '0' )+" record(s)!"
                          else
                             flash[:error] =  "Data Imported successfully "+(($xcount.to_s.length.to_i >0 ) ? $xcount.to_s : '0' )+" record(s)!"
                          end
                          
                          isFlags       =  true
                          modulename = "Process/Calculations"
                          description = "Dataimports: #{params[:process_file_data]}"
                          process_request_log_data("IMPORT", modulename, description)
                          session[:isErrorhandled] = nil
                        end
                    elsif params[:process_file_data].to_s!=nil && params[:process_file_data].to_s!='' && params[:process_file_data].to_s =='attendance'
                        $monthsyears     = params[:myyears]
                        $months          = params[:mymonths]
                        $myupdateallowed = params[:myupdateallowed]
                        if  TrnPayMonthly.employeeattendance(params[:file])
                          if $miscount.to_i >0
                              flash[:error] =  "Month & Year is not matching to HR parameters."
                              isFlags       = false
                              session[:isErrorhandled] = 1
                          else
                              flash[:error] =  "Data Imported successfully "+(($xcount.to_s.length.to_i >0 ) ? $xcount.to_s : '0' )+" record(s) AND Updated #{$dupcount} record(s)"
                              isFlags       = true
                               modulename = "Process/Calculations"
                               description = "Dataimports: #{params[:process_file_data]}"
                               process_request_log_data("IMPORT", modulename, description)
                              session[:isErrorhandled] = nil
                          end
                        end
                    
                    elsif params[:process_file_data].to_s!=nil && params[:process_file_data].to_s!='' && params[:process_file_data].to_s =='product'
                            if  MstProduct.import(params[:file])
                              flash[:error] =  "Data saved successfully New "+(($xcount.to_s.length.to_i >0 ) ? $xcount.to_s : '0' )+" record(s) AND Duplicate "+(($sduplicate.to_s.length.to_i >0 ) ? $sduplicate.to_s : '0' )+" record(s)!"
                              isFlags       = true
                              modulename = "Process/Calculations"
                              description = "Dataimports: #{params[:process_file_data]}"
                              process_request_log_data("SAVE", modulename, description)
                              session[:isErrorhandled] = nil
                          
                          end
                    elsif params[:process_file_data].to_s!=nil && params[:process_file_data].to_s!='' && params[:process_file_data].to_s =='atdrawfile'
                            $monthsyears     = years = params[:myyears]
                            $months          = months = params[:mymonths]
                            location         = params[:emp_location]
                            $myupdateallowed = params[:myupdateallowed]
                            emp_machine      = params[:emp_machine]
      
                            currfile         = ""
                            processyears       = ""
                            cdirect           = "importfile" 
                            if emp_machine.to_s == 'df'
                              
                            monthsyears       =  get_number_month_data(months).to_s+"-"+years.to_s
                            hrparmonths       = get_number_month_data(months)
                            readfile          = "textfile-"+$compcodes.to_s+"-"+monthsyears.to_s+".dat"
                           if ( datfile_process_files(params[:file],currfile,cdirect,months,years) )
      
                                  filename         = Rails.root.join "public","images", cdirect,readfile
                                  inputfile        = File.open(filename, File::RDONLY){|f| f.read }
                                  inarray          = inputfile.lines.map(&:split)
                                  cmycounts        = 0
                                  gc_local_time    = ""
              
                                  # chekattendobj    = TrnGeoLocation.where("gc_compcode=?",@compcodes).last
                                  # processdates     = Date.today
                                  # if chekattendobj
                                  #   processdates   = chekattendobj.gc_date
                                  # end
                                  if inarray.length >0
                                          process_delete_text_file_attendance_from_raw(years,get_number_month_data(months),location)                  
                                          inarray.each do |newfile|
                                              gc_date          = newfile[1].to_s.strip
                                              if gc_date !=nil && gc_date !=''
                                                  newarrformat     =  year_month_days_formatted(gc_date)
                                                  filemonthsyears  =  newarrformat.to_s.split("-")
                                                  #processyears     = filemonthsyears[0].to_s+"-"+filemonthsyears[1].to_s+"/"+hrparmonths.to_s+"-"+years.to_s
                                                if filemonthsyears[0].to_i == years.to_i && filemonthsyears[1].to_i == hrparmonths.to_i
                                               
                                                  compcode         = @compcodes 
                                                  user_id          = newfile[0].to_s.strip                                        
                                                  user_time        = newfile[2].to_s.strip
                                              
      
                                              # if(  @compcodes  == '10004' )
                                              #     newusercode   = "SITPL"+user_id.to_s
                                              # else
                                              #     newusercode   = user_id
                                              # end
                                                    newusercode   = user_id                                        
                                                    if user_time !=nil && user_time !=''
                                                      newtmarr       = user_time.to_s.split(":")
                                                      gc_local_time  = newtmarr[0].to_s+":"+newtmarr[1].to_s
                                                    end
                                                    if user_id.to_i >0 #&& year_month_days_formatted(gc_date)>=year_month_days_formatted(processdates)
                                                      userobj   = get_employee_listed_details(newusercode)
                                                      if userobj
                                                          gc_user_id = userobj.sw_sewcode
                                                      else
                                                          gc_user_id = user_id
                                                      end
                                                      mycounts =  process_raw_data(compcode,gc_user_id,gc_date,gc_local_time,location)
                                                      cmycounts +=1
                                                    end
      
                                                  end
                                             end
                                          end
                                  end
                                if cmycounts.to_i >0
                                    flash[:error] =  "Data saved successfully New "+(inarray.length).to_s+" record(s) "
                                    isFlags       = true
                                    modulename = "Process/Calculations"
                                    description = "Dataimports: #{params[:process_file_data]}"
                                    process_request_log_data("SAVE", modulename, description)
                                    session[:isErrorhandled] = nil
                                else
                                    flash[:error] =  "Could not be process due to already done." #+processyears.to_s
                                    isFlags       = true
                                    session[:isErrorhandled] = nil
                                end
                           end 
                           
                          else ######FOR CP PLUS
                                                  monthsyears       =  get_number_month_data(months).to_s+"-"+years.to_s
                                                  hrparmonths       =  get_number_month_data(months)
                                                  readfile          =  "gltextfile-"+$compcodes.to_s+"-"+monthsyears.to_s+".txt"
                                                if ( txtfile_process_files(params[:file],currfile,cdirect,months,years) )
      
                                                        filename         = Rails.root.join "public","images", cdirect,readfile
                                                        inputfile        = File.open(filename, File::RDONLY){|f| f.read }
                                                        inarray          = inputfile.lines.map(&:split)
                                                        cmycounts        = 0
                                                        gc_local_time    = ""
                                    
                                                        if inarray.length >0
                                                                process_delete_text_file_attendance_from_raw(years,get_number_month_data(months),location)   
                                                                File.foreach(filename) do |line|               
                                                                #inarray.each do |newfile|
                                                                 data = line.strip.split("\t")
      
                                                                    gdatetime  = data[6].to_s.split("  ")
                                                                    if gdatetime[0].to_s.present? && gdatetime[1].to_s.present?
                                                                        filemonthsyears  =  gdatetime[0].to_s.split("/")
                                                                          if filemonthsyears[0].to_i == years.to_i && filemonthsyears[1].to_i == hrparmonths.to_i
                                                                            
                                                                            compcode         = @compcodes 
                                                                            user_id          = data[2].to_s.strip                                        
                                                                            user_time        = gdatetime[1].to_s.strip
                                                                            gc_date          = filemonthsyears[0].to_s+"-"+filemonthsyears[1].to_s+"-"+filemonthsyears[2].to_s
                                                                        
                                                                            #  svbs =  MstUnit.new(:un_compcode=>user_id,:un_sewacode=>user_id,:un_amount=>0,:um_type=>0,:um_status=>'',:un_credit=>0,:un_ob=>0,:un_cb=>0)
                                                                            #  if svbs.save                                                                    
                                                                            #  end
      
                                                                              newusercode   = user_id                                        
                                                                              if user_time !=nil && user_time !=''
                                                                                newtmarr       = user_time.to_s.split(":")
                                                                                gc_local_time  = newtmarr[0].to_s+":"+newtmarr[1].to_s
                                                                              end
                                                                              if user_id.to_i >0 #&& year_month_days_formatted(gc_date)>=year_month_days_formatted(processdates)
                                                                                userobj   = get_employee_listed_details(newusercode)
                                                                                if userobj                                                                       
                                                                                    gc_user_id = userobj.sw_sewcode
                                                                                else
                                                                                    gc_user_id = user_id
                                                                                end
                                                                                if user_time !=nil && user_time !=''
                                                                                  mycounts =  process_raw_data(compcode,gc_user_id,gc_date,gc_local_time,location)
                                                                                end
                                                                                cmycounts +=1
                                                                              end
      
                                                                            end
                                                                      end
                                                                end
                                                        end
                                                      if cmycounts.to_i >0
                                                          flash[:error] =  "Data saved successfully New "+(inarray.length).to_s+" record(s) "
                                                          isFlags       = true
                                                          modulename = "Process/Calculations"
                                                          description = "Dataimports: #{params[:process_file_data]}"
                                                          process_request_log_data("SAVE", modulename, description)
                                                          session[:isErrorhandled] = nil
                                                      else
                                                          flash[:error] =  "Could not be process due to already done." #+data.to_s
                                                          isFlags       = true
                                                          session[:isErrorhandled] = nil
                                                      end
                                                end 
      
                          end ### END CPPLUS
                       end
          else
              # if params[:process_file_data].to_s!=nil && params[:process_file_data].to_s!='' && params[:process_file_data].to_s =='atdrawfile'
              #       $monthsyears     = years = params[:myyears]
              #       $months          = months = params[:mymonths]
              #       $myupdateallowed = params[:myupdateallowed]
              #       mymonthsyears    = get_directory_monthyear()
              #       cdirect          = "importfile/mytxtimport-"+@compcodes.to_s+"-"+mymonthsyears.to_s
           
              #      if ( process_files(params[:file],currfile,cdirect) )
      
              #             filename         = Rails.root.join('importfile', cdirect)
              #             inputfile        = File.open(filename, File::RDONLY){|f| f.read }
              #             inarray          = inputfile.lines.map(&:split)
              #             cmycounts         = 0
              #             gc_local_time    = ""
      
              #             chekattendobj    = TrnGeoLocation.where("gc_compcode=?",@compcodes).last
              #             processdates     = Date.today
              #             if chekattendobj
              #               processdates   = chekattendobj.gc_date
              #             end
              #             if inarray.length >0
              #                     process_delete_text_file_attendance_from_raw(years,get_number_month_data(months))                  
              #                     inarray.each do |newfile|
              #                         compcode         = @compcodes 
              #                         user_id          = newfile[0].to_s.strip
              #                         gc_date          = newfile[1].to_s.strip
              #                         user_time        = newfile[2].to_s.strip
              #                         # if(  @compcodes  == '10004' )
              #                         #     newusercode   = "SITPL"+user_id.to_s
              #                         # else
              #                         #     newusercode   = user_id
              #                         # end
              #                         newusercode   = user_id
                                      
              #                         if user_time !=nil && user_time !=''
              #                           newtmarr       = user_time.to_s.split(":")
              #                           gc_local_time  = newtmarr[0].to_s+":"+newtmarr[1].to_s
              #                         end
              #                         if user_id.to_i >0 #&& year_month_days_formatted(gc_date)>=year_month_days_formatted(processdates)
              #                             userobj   = get_employee_listed_details(newusercode)
              #                             if userobj
              #                                 gc_user_id = userobj.sw_sewcode
              #                             else
              #                                 gc_user_id = user_id
              #                             end
              #                             mycounts =  process_raw_data(compcode,gc_user_id,gc_date,gc_local_time)
              #                             cmycounts +=1
              #                         end
              #                     end
              #             end
              #           if cmycounts.to_i >0
              #               flash[:error] =  "Data saved successfully New "+(inarray.length).to_s+" record(s) "
              #               isFlags       = true
              #               session[:isErrorhandled] = nil
              #           else
              #               flash[:error] =  "Could not be process due to already done."
              #               isFlags       = true
              #               session[:isErrorhandled] = nil
              #           end
              #      end     
              #  end
           ############### END IMPORT CUSTOMER & PRODUCT DATA ITEMS#############
         end
       
       if !isFlags
        session[:postedpamams] = params
        session[:isErrorhandled] = 1
       else
         session[:postedpamams] = nil
         session[:isErrorhandled] = nil
       end
       rescue Exception => exc
            flash[:error] =   "#{exc.message}"
            session[:isErrorhandled] = 1
        end
       redirect_to "#{root_url}"+"student_data_import"
      end
      
end
