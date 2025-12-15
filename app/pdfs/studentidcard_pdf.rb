# To change this template, choose Tools | Templates
# and open the template in the editor.
require 'net/http'
require "open-uri"
class StudentidcardPdf < Prawn::Document
  def initialize(reportdata, compdetail, uRl)
    super(:left_margin=>5,:right_margin=>5,:top_margin=>5,:bottom_margin=>2,:page_size =>[243, 153])
    @reportdata = reportdata
    @compDetail = compdetail
    @uRl2        = uRl
    @uRl         = Rails.root.join "public"
    @logoSize    = 0.2   
   
    line_items
    
 end

 
  def count_mcell
  @count_cell ||= 0
  @count_cell = @count_cell+1
end


def line_items
  newcompdteail =  @compDetail.cmp_addressline1.to_s+((@compDetail.cmp_addressline1.to_s.length.to_i >1) ? ', ': '' )+@compDetail.cmp_addressline2.to_s+(@compDetail.cmp_addressline3.to_s.strip.length > 1 ? " -#{@compDetail.cmp_addressline3.strip}" : '').to_s
  if @compDetail.cmp_logos.to_s.length >1
    @filesExt = Rails.root.join "public", "images", "logo",@compDetail.cmp_logos.to_s
    if File.exist?(@filesExt)
      image_path = {:image=>open(@uRl.to_s+"/images/logo/"+@compDetail.cmp_logos.to_s) ,:position =>:center,:fit => [40,35],:rowspan=>2}           
    else
      image_path =''
    end
 
 end

 if @compDetail.cmp_signs.to_s.length >1
  @signfilesExt = Rails.root.join "public", "images", "signs",@compDetail.cmp_signs.to_s
  if File.exist?(@signfilesExt)
    principal_image_path = {:image=>open(@uRl.to_s+"/images/signs/"+@compDetail.cmp_signs.to_s) ,:position =>:center,:fit => [35,20],:rowspan=>2}           
  else
    principal_image_path = {:image=>open(@uRl.to_s+"/assets/img/invoice_logo.png") ,:position =>:center,:fit => [35,20],:rowspan=>2} 
  end

end

  # student_image_path = {:image=>open(@uRl.to_s+"/assets/img/user/user10.jpg") ,:position =>:left,:fit => [48,80],:rowspan=>5,:padding_top=>4}           
 

data2 = []
record_count = 0
  @reportdata.each.map do |stid|
    data1 = ([ 
  [image_path,{:content => "<b>#{@compDetail.cmp_companyname.upcase}", :inline_format => true, :size => 9,:padding_bottom=>1}],
  [{:content => "<b>(Under Ministry of Tourism, Govt. of India)</b>", :inline_format => true, :size => 6,:padding_top=>0}]
    
   ])

# Use the repeat method to add the header on every page
 
    table(data1, :width => 240) do
      style row(0..1).column(0..1), :border_width => 0
      style column(0), :width => 40, :align => :left, :inline_format => :true
      style column(1), :width => 200, :align => :center,:text_color => 'DC143C'
      cells.padding = 0
     end
     if stid.stdnt_img.present?
      student_image_path = "https://ihm-inqerp.b-cdn.net/#{stid.stdnt_compcode}/student/#{stid.stdnt_img}"
      
      # Function to check if the URL for the image file is valid
      def url_exists?(url)
        uri = URI.parse(url)
        response = Net::HTTP.get_response(uri)
        response.code == "200" # Returns true if status is 200 (OK)
      end
    
      # Verify if the image URL exists
      unless url_exists?(student_image_path)
        student_image_path = "#{@uRl}/images/no-image.jpg" # Use default if the image is not found on the server
      end
    else
      student_image_path = "#{@uRl}/images/no-image.jpg" # Fallback if no image in the database
    end
    
    # file_extension = File.extname(stid.stdnt_signature).downcase if stid.stdnt_signature.present?

    # if stid.stdnt_signature.present? 
    #   student_signature_path = "https://ihm-inqerp.b-cdn.net/#{stid.stdnt_compcode}/studentsign/#{stid.stdnt_signature}"
    # else
    #   student_signature_path = "#{@uRl}/images/no-image.jpg"
    # end
    
    file_extension = File.extname(stid.stdnt_signature).downcase if stid.stdnt_signature.present?

    # Function to check if the URL for the image file is valid
    def sign_url_exists?(url)
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)
      response.code == "200" # Returns true if status is 200 (OK)
    end
    
    if stid.stdnt_signature.present? && !['.pdf', '.heic'].include?(file_extension)
      student_signature_path = "https://ihm-inqerp.b-cdn.net/#{stid.stdnt_compcode}/studentsign/#{stid.stdnt_signature}"
    
      # Verify if the image URL exists
      unless sign_url_exists?(student_signature_path)
        student_signature_path = "#{@uRl}/images/no-image.jpg" # Use default if the image is not found on the server
      end
    else
      student_signature_path = "#{@uRl}/images/no-image.jpg"
    end
    


   move_up 2    
  data2 = ([
       [{:image =>  URI.open(student_image_path.to_s),:position =>:left,:fit => [48,80],:rowspan=>5,:padding_top=>4},{:content=>"Roll No."},{:content=>":"},{:content=>"<b>"+stid.stdnt_reg_no.to_s+"</b>"},{:content=>""},{:content=>"Prog.Name"},{:content=>":"},{:content=>"<b>"+stid.coursecode.to_s+"</b>"}],
       [{:content=>"Batch"},{:content=>":"},{:content=>"<b>"+stid.registyear.to_s+"-"+stid.courseduration.to_s+"</b>"},{:content=>""},{:content=>"Valid Upto"},{:content=>":"},{:content=>"<b>JUNE-"+stid.courseduration.to_s+"</b>"}],
     
      ])
            

    table([] + data2,:width =>235)  do
    
    style column(0..7),:inline_format=>:true ,  :border_width => 0,:size=>7,:font_style=>:bold
    # style row(0),  :size => 9, :align=>:center
    style row(0..1).column(0), width: 52  # Image column
    style row(0..1).column(1), width: 28  # "Roll No." column
    style row(0..1).column(2), width: 10  # ":" column
    style row(0..1).column(3), width: 40  # Roll number value
    style row(0..1).column(4), width: 10  # Empty cell
    style row(0..1).column(5), width: 40  # "Prog. Name" column
    style row(0..1).column(6), width: 10  # ":" column
    style row(0..1).column(7), width: 45  # Empty cell for program name
    style row(1),:border_bottom_width =>1, :padding => [1, 1, 2, 1]
    style row(0), :padding => [0, 1, 1, 1]
    # style row(0).column(0),:border_width => 1 
    # cells.padding = 2
    end
    
        
  data3 = ([
    ['',{:content=>"<b>Name</b>"},{:content=>":"},{:content=>"<b>"+stid.stdnt_fname.to_s+"</b>",:colspan=>2}],
    ['',{:content=>"<b>Father's Name</b>"},{:content=>":"},{:content=>stid.fathername.to_s,:colspan=>2}],
    ['',{:content=>"<b>Address</b>"},{:content=>":"},{:content=>stid.stdnt_dtl_add1.to_s,:colspan=>2,:height=>25}],
    ['',{:content=>"<b>D.O.B</b>"},{:content=>":"},{:content=>format_oblig_date(stid.stdnt_dob).to_s,:colspan=>2}],
    [{:image =>  URI.open(student_signature_path.to_s),:position =>:center,:fit => [35,20],:rowspan=>2},{:content=>"<b>Blood Group</b>"},{:content=>":"},{:content=>stid.stdnt_bloodgroup.to_s},principal_image_path],
    [{:content=>"<b>Mob.No.</b>"},{:content=>":"},{:content=>stid.stdnt_dtl_cont.to_s}],
  
   ])
         

 table([] + data3,:width =>235)  do
 
 style column(0..4),:inline_format=>:true ,  :border_width => 0,:size=>7.2,:font_style=>:bold
 # style row(0),  :size => 9, :align=>:center
 style column(0), width: 52  # Image column
 style column(1), width: 49  
 style column(2), width: 10  # ":" column
 style column(3), width: 84 
 style column(4), width: 40 

 cells.padding = 0
 end

  
        
 data4 = ([
  [{:content=>"STUDENT'S SIGNATURE"},{:content=>"PRINCIPAL"}],
 ])
       

table([] + data4,:width =>235)  do

style column(0..4),:inline_format=>:true ,  :border_width => 0,:size=>7,:font_style=>:bold
style column(0), width: 120  
style column(1), width: 115,:align => :right  

cells.padding = 0
end
    # IC CARD BACK SIDE START  
data5 = ([
  [{:content=>"1. No tempering/change should be done to the information mentioned in I-Card."}],
  [{:content=>"2. Loss of I-Card must be reported immediately to the issuing Authority and duplicate card should be procured on payment of Rs. 200/-"}],
 ])
       

table([] + data5,:width =>235)  do

style column(0),:inline_format=>:true ,  :border_width => 0,:size=>7,:font_style=>:bold
style column(0), width: 235  

cells.padding = 1
end
move_down 20

text "<b>*IHM*</b>",:align=> :center,:size=>9,:font_style=>:bold,:inline_format=>:true
text "<b>#{@compDetail.cmp_companyname.upcase}</b>",:align=> :center,:size=>9,:inline_format=>:true
move_down 5
text "<b>An Autonomous body (Under Ministry of Tourism, Govt. of India)</b>",:align=> :center,:size=>7,:font_style=>:bold,:inline_format=>:true
move_down 5
text "<b>#{newcompdteail}</b>",:align=> :center,:size=>7.3,:inline_format=>:true
text "<b>Ph : #{@compDetail.cmp_telephonenumber}</b>",:align=> :center,:size=>7.3,:inline_format=>:true
text "<b>Website : www.ihmpusa.net</b>",:align=> :center,:size=>7.3,:inline_format=>:true

# IC CARD BACK SIDE END  
    record_count += 1

    # Start a new page if it's not the last record
    if record_count != @reportdata.size
      start_new_page
    end
    
 end
    Time.zone = "Kolkata"
    billtimes = Time.zone.now.strftime('%I:%M%p')

  
   
  end
  
  
  
  private
  def format_oblig_date(dates)
       newdate = ''
       if dates!=nil && dates!=''
            dts    = Date.parse(dates.to_s)
            newdate = dts.strftime("%d/%m/%Y")
       end
       return newdate
  end
  
private
def number_currency_in_words
   to_words(@tnetamt.to_f)  
 end

private
   def currency_formatted(amt)
        amts = ''
        if amt!=nil && amt!=''
          amts = "%.2f" % amt.to_f
        end
        return amts
   end

private
 def formatted_date(dates)
      newdate = ''
      if dates!=nil && dates!=''
           dts    = Date.parse(dates.to_s)
           newdate = dts.strftime("%d-%b-%Y")
      end
      return newdate
 end

def count
  @count ||= 0
  @count = @count+1
end


def to_words(num)
  numbers_to_name = {
      10000000 => "Crore",
      100000 => "Lakh",
      1000 => "Thousand",
      100 => "Hundred",
      90 => "Ninety",
      80 => "Eighty",
      70 => "Seventy",
      60 => "Sixty",
      50 => "Fifty",
      40 => "Forty",
      30 => "Thirty",
      20 => "Twenty",
      19=>"Nineteen",
      18=>"Eighteen",
      17=>"Seventeen",
      16=>"Sixteen",
      15=>"Fifteen",
      14=>"Fourteen",
      13=>"Thirteen",
      12=>"Twelve",
      11 => "Eleven",
      10 => "Ten",
      9 => "Nine",
      8 => "Eight",
      7 => "Seven",
      6 => "Six",
      5 => "Five",
      4 => "Four",
      3 => "Three",
      2 => "Two",
      1 => "One"
    }

  log_floors_to_ten_powers = {
    0 => 1,
    1 => 10,
    2 => 100,
    3 => 1000,
    4 => 1000,
    5 => 100000,
    6 => 100000,
    7 => 10000000
  }

  num = num.to_i
  return '' if num <= 0 or num >= 100000000

  log_floor = Math.log(num, 10).floor
  ten_power = log_floors_to_ten_powers[log_floor]

  if num <= 20
    numbers_to_name[num]
  elsif log_floor == 1
    rem = num % 10
    [ numbers_to_name[num - rem], to_words(rem) ].join(' ')
  else
    [ to_words(num / ten_power), numbers_to_name[ten_power], to_words(num % ten_power) ].join(' ')
  end
end
end