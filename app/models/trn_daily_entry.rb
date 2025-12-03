class TrnDailyEntry < ApplicationRecord

    def self.game_entry_list_excel
        attributes = ['SNo.', 'Entry Date', 'Time', 'Retailer Code', 'Consumer Name', 'Age', 'Mobile No.', 'No. of sticks purchased', 'Dice Score', 'UPI Id']
        attributes1 = %w{gameentryid de_dated de_time de_retailercode de_name de_age de_mobileno de_stick_purch de_dice_score_percent de_upi_id}
        i = 1
        CSV.generate(:headers=> true) do |csv|
          csv << attributes
            if all.length >0
                  if $excelitems.length >0
                      $excelitems.each do |user|
                          user.gameentryid = i
                         csv << attributes1.map{ |attr| user.send(attr) }
                         i +=1
                      end
    
                  end
            end
        end
    end

      


end
