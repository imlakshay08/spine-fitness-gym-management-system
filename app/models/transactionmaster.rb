class Transactionmaster < ApplicationRecord
 
    def self.stock_receipt_list_excel
        attributes = ['SNo.', 'TYPE', 'RECEIPT NO.', 'AGENCY', 'MARKET NAME', 'BRANCH', 'WD NAME', 'WD ADDRESS', 'ACTIVITY NAME', 'ACTIVITY BRIEF NUMBER', 'SEGMENT TYPE',  'BRAND', 'VARIANT', 'DATE OF PICK UP', 'PACK SIZE', 'STOCK PICKED UP', 'VALUE OF STOCK PICKED UP', 'RATE PER STICK', 'NAME OF STOCK RECEIVER', 'DESIGNATION OF STOCK RECIEVER', 'MOBILE NO OF STOCK RECIEVER', 'REMARKS']
        attributes1 = %w{transactionid activitytype Id agency cityname branchname wdname wdaddress activityname Activity_Brief_Number segmentname brandname variantname Date_of_pickup packsize StockQty_pickup Value_for_stock Rate_per_Stick receivername receiverdesignation receivermobileno Remarks}
        i = 1
        CSV.generate(:headers=> true) do |csv|
          csv << attributes
            if all.length >0
                  if $excelitems.length >0
                      $excelitems.each do |user|
                          user.transactionid = i
                         csv << attributes1.map{ |attr| user.send(attr) }
                         i +=1
                      end
    
                  end
            end
        end
    end

end