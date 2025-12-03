class TrnRptoutletMaster < ApplicationRecord

    def self.outlet_list_excel
        attributes = %w{SNo. AreaName OutletType OutletID OutletName OwnerName  MobileNo.  UPIID }
        attributes1 = %w{outletid om_area om_usertype id om_outletname om_ownername om_mobileno om_upi_verify_id }
        i = 1
        CSV.generate(:headers=> true) do |csv|
          csv << attributes
            if all.length >0
                  if $excelitems.length >0
                      $excelitems.each do |user|
                          user.outletid = i
                         csv << attributes1.map{ |attr| user.send(attr) }
                         i +=1
                      end
    
                  end
            end
        end
    end

end
