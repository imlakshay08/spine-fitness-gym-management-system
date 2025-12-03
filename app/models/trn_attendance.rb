class TrnAttendance < ApplicationRecord
def self.faculty_attendance_report
    require 'csv'
    datas = $excelitems
    return if !datas || datas.length <= 0

    subname    = datas[0]        
    month_year = datas[1]        
    dateslist  = datas[2]        
    finaldata  = datas[3]        

    CSV.generate do |csv|
        csv << [subname]
        csv << [month_year]
        csv << []  # empty row

        header = ["NCHM RI No", "Student Name"]
        dateslist.each do |dt|
            header.push(dt.strftime("%d-%m"))
        end
        header.push("Days(P)")
        header.push("Periods(P)")
        header.push("Total Periods")   # ?? New column
        csv << header

        finaldata.each do |row|
            csv << row
        end
    end
end
end
